<?php

namespace App\Http\Controllers\API;

use App\Http\Controllers\API\Controller;
use App\Traits\SendsNotifications;
use App\Models\Attendance;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Str;

class AttendanceController extends Controller
{
    use SendsNotifications;
    /**
     * Enregistrer un pointage (arrivée ou départ)
     */
    public function store(Request $request): JsonResponse
    {
        Log::info('Attendance store called', [
            'request_all' => $request->all(),
            'has_file_photo' => $request->hasFile('photo'),
            'user_id' => $request->user()?->id,
        ]);

        $validator = Validator::make($request->all(), [
            'type' => 'required|in:check_in,check_out',
            'latitude' => 'required|numeric|between:-90,90',
            'longitude' => 'required|numeric|between:-180,180',
            'address' => 'nullable|string|max:255',
            'accuracy' => 'nullable|numeric|min:0',
            'photo' => 'required|image|mimes:jpeg,png,jpg|max:2048',
            'notes' => 'nullable|string|max:1000',
        ]);

        if ($validator->fails()) {
            Log::warning('Attendance validation failed', ['errors' => $validator->errors()->toArray()]);
            return response()->json([
                'success' => false,
                'message' => 'Données invalides',
                'errors' => $validator->errors()
            ], 422);
        }

        $user = $request->user();

        if (!$user) {
            Log::error('No authenticated user');
            return response()->json([
                'success' => false,
                'message' => 'Utilisateur non authentifié'
            ], 401);
        }

        // Vérifier si l'utilisateur peut pointer
        Log::info('Attendance store - Before canUserPunch check', [
            'user_id' => $user->id,
            'type' => $request->type,
            'timestamp' => now()->toDateTimeString()
        ]);
        
        $canPunch = $this->canUserPunch($user, $request->type);
        
        Log::info('Attendance store - After canUserPunch check', [
            'user_id' => $user->id,
            'type' => $request->type,
            'can_punch' => $canPunch,
            'timestamp' => now()->toDateTimeString()
        ]);
        
        if (!$canPunch) {
            // Vérifier à nouveau pour diagnostiquer
            $today = now()->startOfDay();
            $tomorrow = now()->copy()->addDay()->startOfDay();
            $debugAttendance = Attendance::where('user_id', $user->id)
                ->where('check_in_time', '>=', $today)
                ->where('check_in_time', '<', $tomorrow)
                ->whereNull('check_out_time')
                ->get();
            
            Log::warning('User cannot punch - Debug info', [
                'user_id' => $user->id,
                'type' => $request->type,
                'today' => $today->toDateTimeString(),
                'tomorrow' => $tomorrow->toDateTimeString(),
                'found_attendances' => $debugAttendance->map(function($a) {
                    return [
                        'id' => $a->id,
                        'check_in_time' => $a->check_in_time,
                        'check_out_time' => $a->check_out_time,
                    ];
                })->toArray()
            ]);
            
            return response()->json([
                'success' => false,
                'message' => 'Vous ne pouvez pas pointer maintenant'
            ], 400);
        }

        try {
            // Vérifier les permissions d'écriture
            $storagePath = storage_path('app/public');
            if (!is_writable($storagePath)) {
                Log::error('Storage not writable', ['path' => $storagePath]);
                return response()->json([
                    'success' => false,
                    'message' => 'Erreur de permissions sur le dossier de stockage',
                    'error' => 'Le dossier storage/app/public n\'est pas accessible en écriture'
                ], 500);
            }

            // Créer le dossier attendances/{user_id} s'il n'existe pas
            $userAttendancesPath = "{$storagePath}/attendances/{$user->id}";
            if (!file_exists($userAttendancesPath)) {
                if (!mkdir($userAttendancesPath, 0755, true)) {
                    Log::error('Cannot create directory', ['path' => $userAttendancesPath]);
                    return response()->json([
                        'success' => false,
                        'message' => 'Impossible de créer le dossier de stockage',
                        'error' => "Erreur lors de la création du dossier: {$userAttendancesPath}"
                    ], 500);
                }
                Log::info('Created directory', ['path' => $userAttendancesPath]);
            }

            // Upload de la photo
            $photoPath = $this->uploadPhoto($request->file('photo'), $user->id);
            Log::info('Photo uploaded', ['path' => $photoPath]);

            // Préparer les données de localisation en JSON
            $locationData = [
                'latitude' => $request->latitude,
                'longitude' => $request->longitude,
                'address' => $request->address,
                'accuracy' => $request->accuracy,
            ];

            // Si c'est un check-in, créer ou mettre à jour le pointage
            if ($request->type === 'check_in') {
                // Vérifier s'il existe déjà un pointage du jour sans check_out
                $today = now()->startOfDay();
                $tomorrow = now()->copy()->addDay()->startOfDay();
                
                $todayAttendance = Attendance::where('user_id', $user->id)
                    ->where('check_in_time', '>=', $today)
                    ->where('check_in_time', '<', $tomorrow)
                    ->whereNull('check_out_time')
                    ->first();

                if ($todayAttendance) {
                    // Mettre à jour le pointage existant
                    $todayAttendance->update([
                        'check_in_time' => now(),
                        'location' => $locationData,
                        'photo_path' => $photoPath,
                        'notes' => $request->notes,
                        'status' => 'en_attente',
                    ]);
                    $attendance = $todayAttendance;
                } else {
                    // Créer un nouveau pointage
                    $attendance = Attendance::create([
                        'user_id' => $user->id,
                        'check_in_time' => now(),
                        'check_out_time' => null,
                        'location' => $locationData,
                        'photo_path' => $photoPath,
                        'notes' => $request->notes,
                        'status' => 'en_attente',
                    ]);
                }
            } else {
                // C'est un check-out, trouver le pointage du jour
                $today = now()->startOfDay();
                $tomorrow = now()->copy()->addDay()->startOfDay();
                
                $todayAttendance = Attendance::where('user_id', $user->id)
                    ->where('check_in_time', '>=', $today)
                    ->where('check_in_time', '<', $tomorrow)
                    ->whereNull('check_out_time')
                    ->first();

                if ($todayAttendance) {
                    // Mettre à jour avec le check-out
                    $locationData['check_out_location'] = [
                        'latitude' => $request->latitude,
                        'longitude' => $request->longitude,
                        'address' => $request->address,
                        'accuracy' => $request->accuracy,
                    ];
                    $todayAttendance->update([
                        'check_out_time' => now(),
                        'location' => array_merge($todayAttendance->location ?? [], $locationData),
                        'notes' => $request->notes ?? $todayAttendance->notes,
                    ]);
                    $attendance = $todayAttendance;
                } else {
                    return response()->json([
                        'success' => false,
                        'message' => 'Aucun pointage d\'arrivée trouvé pour aujourd\'hui'
                    ], 400);
                }
            }

            Log::info('Attendance created', ['attendance_id' => $attendance->id]);

            return response()->json([
                'success' => true,
                'message' => 'Pointage enregistré avec succès',
                'data' => $attendance->load('user')
            ], 201);

        } catch (\Exception $e) {
            Log::error('Attendance store error', [
                'message' => $e->getMessage(),
                'trace' => $e->getTraceAsString(),
                'file' => $e->getFile(),
                'line' => $e->getLine()
            ]);
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de l\'enregistrement du pointage',
                'error' => config('app.debug') ? $e->getMessage() : 'Une erreur est survenue'
            ], 500);
        }
    }

    /**
     * Lister tous les pointages (pour le patron)
     */
    public function index(Request $request): JsonResponse
    {
        $query = Attendance::with(['user', 'validator']);

        // Filtres
        if ($request->has('status')) {
            $backendStatus = $this->mapStatusFromFrontend($request->status);
            $query->where('status', $backendStatus);
        }

        if ($request->has('user_id')) {
            $query->where('user_id', $request->user_id);
        }

        if ($request->has('date_from')) {
            $query->whereDate('check_in_time', '>=', $request->date_from);
        }

        if ($request->has('date_to')) {
            $query->whereDate('check_in_time', '<=', $request->date_to);
        }

        $attendances = $query->orderBy('check_in_time', 'desc')->paginate(20);

        return response()->json([
            'success' => true,
            'data' => $attendances
        ]);
    }

    /**
     * Afficher un pointage spécifique
     */
    public function show(Attendance $attendance): JsonResponse
    {
        return response()->json([
            'success' => true,
            'data' => $attendance->load(['user', 'approver'])
        ]);
    }

    /**
     * Approuver un pointage
     */
    public function approve(Request $request, Attendance $attendance): JsonResponse
    {
        $user = $request->user();

        // Vérifier que l'utilisateur peut approuver
        if (!$this->canApprove($user)) {
            return response()->json([
                'success' => false,
                'message' => 'Vous n\'avez pas l\'autorisation d\'approuver'
            ], 403);
        }

        // Recharger le pointage pour s'assurer d'avoir les dernières données
        $attendance->refresh();
        
        // Si le statut est null, le définir à 'en_attente' pour compatibilité avec les anciens pointages
        if ($attendance->status === null) {
            $attendance->status = 'en_attente';
            $attendance->save();
        }
        
        // Vérifier que le pointage peut être approuvé
        if (!$attendance->canBeApproved()) {
            Log::warning('Cannot approve attendance', [
                'attendance_id' => $attendance->id,
                'status' => $attendance->status,
                'user_id' => $attendance->user_id,
            ]);
            
            return response()->json([
                'success' => false,
                'message' => 'Ce pointage ne peut pas être approuvé. Statut actuel: ' . ($attendance->status ?? 'null'),
                'current_status' => $attendance->status,
                'attendance_id' => $attendance->id
            ], 400);
        }

        Log::info('Attempting to approve attendance', [
            'attendance_id' => $attendance->id,
            'current_status' => $attendance->status,
            'can_be_approved' => $attendance->canBeApproved(),
            'approver_id' => $user->id,
        ]);

        $result = $attendance->approve($user, $request->input('comment'));
        
        Log::info('Approve result', [
            'attendance_id' => $attendance->id,
            'result' => $result,
            'status_after_approve' => $attendance->status,
        ]);

        if ($result) {
            // Utiliser fresh() pour forcer le rechargement depuis la base de données
            // fresh() retourne une nouvelle instance depuis la DB, ce qui est plus fiable que refresh()
            $attendance = $attendance->fresh(['user', 'validator']);
            
            if (!$attendance) {
                Log::error('Cannot reload attendance after approval', [
                    'attendance_id' => $attendance->id ?? 'unknown',
                ]);
                return response()->json([
                    'success' => false,
                    'message' => 'Erreur lors du rechargement du pointage'
                ], 500);
            }
            
            Log::info('Attendance approved successfully', [
                'attendance_id' => $attendance->id,
                'final_status' => $attendance->status,
                'validated_by' => $attendance->validated_by,
                'validated_at' => $attendance->validated_at,
            ]);
            
            // Notifier l'utilisateur concerné
            if ($attendance->user_id) {
                $dateFormatted = $attendance->check_in_time ? $attendance->check_in_time->format('d/m/Y') : 'date inconnue';
                $this->createNotification([
                    'user_id' => $attendance->user_id,
                    'title' => 'Approbation Pointage',
                    'message' => "Votre pointage du {$dateFormatted} a été approuvé",
                    'type' => 'success',
                    'entity_type' => 'attendance',
                    'entity_id' => $attendance->id,
                    'action_route' => "/attendances/{$attendance->id}",
                ]);
            }

            return response()->json([
                'success' => true,
                'message' => 'Pointage approuvé avec succès',
                'data' => [
                    'id' => $attendance->id,
                    'status' => $attendance->status,
                    'validated_by' => $attendance->validated_by,
                    'validated_at' => $attendance->validated_at,
                    'validation_comment' => $attendance->validation_comment,
                    'user' => $attendance->user,
                    'validator' => $attendance->validator,
                ]
            ]);
        }

        Log::error('Failed to approve attendance', [
            'attendance_id' => $attendance->id,
            'current_status' => $attendance->status,
            'can_be_approved' => $attendance->canBeApproved(),
        ]);

        return response()->json([
            'success' => false,
            'message' => 'Impossible d\'approuver ce pointage. Vérifiez que le statut est "en_attente"',
            'current_status' => $attendance->status,
            'can_be_approved' => $attendance->canBeApproved()
        ], 400);
    }

    /**
     * Rejeter un pointage
     */
    public function reject(Request $request, Attendance $attendance): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'reason' => 'required|string|max:500'
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Raison de rejet requise',
                'errors' => $validator->errors()
            ], 422);
        }

        $user = $request->user();

        // Vérifier que l'utilisateur peut rejeter
        if (!$this->canApprove($user)) {
            return response()->json([
                'success' => false,
                'message' => 'Vous n\'avez pas l\'autorisation de rejeter'
            ], 403);
        }

        // Recharger le pointage pour s'assurer d'avoir les dernières données
        $attendance->refresh();
        
        // Si le statut est null, le définir à 'en_attente' pour compatibilité avec les anciens pointages
        if ($attendance->status === null) {
            $attendance->status = 'en_attente';
            $attendance->save();
        }
        
        // Vérifier que le pointage peut être rejeté
        if (!$attendance->canBeRejected()) {
            Log::warning('Cannot reject attendance', [
                'attendance_id' => $attendance->id,
                'status' => $attendance->status,
                'user_id' => $attendance->user_id,
            ]);
            
            return response()->json([
                'success' => false,
                'message' => 'Ce pointage ne peut pas être rejeté. Statut actuel: ' . ($attendance->status ?? 'null'),
                'current_status' => $attendance->status,
                'attendance_id' => $attendance->id
            ], 400);
        }

        if ($attendance->reject($user, $request->reason, $request->input('comment'))) {
            // Recharger le pointage avec les relations
            $attendance->refresh();
            $attendance->load(['user', 'rejector']);
            
            // Notifier l'utilisateur concerné
            if ($attendance->user_id) {
                $dateFormatted = $attendance->check_in_time ? $attendance->check_in_time->format('d/m/Y') : 'date inconnue';
                $this->createNotification([
                    'user_id' => $attendance->user_id,
                    'title' => 'Rejet Pointage',
                    'message' => "Votre pointage du {$dateFormatted} a été rejeté. Raison: {$request->reason}",
                    'type' => 'error',
                    'entity_type' => 'attendance',
                    'entity_id' => $attendance->id,
                    'action_route' => "/attendances/{$attendance->id}",
                    'metadata' => ['reason' => $request->reason],
                ]);
            }

            return response()->json([
                'success' => true,
                'message' => 'Pointage rejeté avec succès',
                'data' => $attendance
            ]);
        }

        return response()->json([
            'success' => false,
            'message' => 'Impossible de rejeter ce pointage'
        ], 400);
    }

    /**
     * Pointages en attente de validation
     */
    public function pending(): JsonResponse
    {
        $attendances = Attendance::with(['user'])
            ->pending()
            ->orderBy('timestamp', 'desc')
            ->get();

        return response()->json([
            'success' => true,
            'data' => $attendances
        ]);
    }

    /**
     * Vérifier si l'utilisateur peut pointer
     * Utilise canUserPunchWithDetails() pour garantir la cohérence avec store()
     */
    public function canPunch(Request $request): JsonResponse
    {
        $user = $request->user();
        $type = $request->query('type', 'check_in');

        // Utiliser canUserPunchWithDetails() pour obtenir toutes les infos en une seule fois
        $details = $this->canUserPunchWithDetails($user, $type);
        
        if ($type === 'check_in') {
            if ($details['today_completed']) {
                return response()->json([
                    'success' => true,
                    'can_punch' => false,
                    'message' => 'Vous avez déjà pointé aujourd\'hui',
                    'current_status' => 'checked_out'
                ]);
            }
            
            if ($details['today_attendance']) {
                return response()->json([
                    'success' => true,
                    'can_punch' => false,
                    'message' => 'Vous avez déjà pointé votre arrivée. Vous pouvez pointer votre départ.',
                    'current_status' => 'checked_in'
                ]);
            }
            
            return response()->json([
                'success' => true,
                'can_punch' => $details['can_punch'],
                'message' => 'Vous pouvez pointer votre arrivée',
                'current_status' => 'no_attendance'
            ]);
        } else {
            // check_out
            if ($details['today_attendance']) {
                return response()->json([
                    'success' => true,
                    'can_punch' => $details['can_punch'],
                    'message' => 'Vous pouvez pointer votre départ',
                    'current_status' => 'checked_in'
                ]);
            }
            
            if ($details['today_completed']) {
                return response()->json([
                    'success' => true,
                    'can_punch' => false,
                    'message' => 'Vous avez déjà pointé votre départ aujourd\'hui',
                    'current_status' => 'checked_out'
                ]);
            }
            
            return response()->json([
                'success' => true,
                'can_punch' => false,
                'message' => 'Vous devez d\'abord pointer votre arrivée',
                'current_status' => 'no_attendance'
            ]);
        }
    }

    /**
     * Upload de photo
     */
    private function uploadPhoto($photo, int $userId): string
    {
        try {
            $filename = Str::uuid() . '.' . $photo->getClientOriginalExtension();
            $path = "attendances/{$userId}/{$filename}";
            
            Log::info('Uploading photo', ['path' => $path, 'user_id' => $userId]);
            
            // Vérifier que le fichier existe et est valide
            if (!$photo || !$photo->isValid()) {
                throw new \Exception('Fichier photo invalide');
            }

            // Utiliser Storage pour l'upload
            $stored = Storage::disk('public')->put($path, file_get_contents($photo->getRealPath()));
            
            if (!$stored) {
                throw new \Exception('Échec de l\'upload du fichier');
            }

            Log::info('Photo uploaded successfully', ['path' => $path]);
            
            return $path;
        } catch (\Exception $e) {
            Log::error('Photo upload error', [
                'message' => $e->getMessage(),
                'user_id' => $userId,
                'trace' => $e->getTraceAsString()
            ]);
            throw $e;
        }
    }

    /**
     * Vérifier si l'utilisateur peut pointer avec tous les détails
     * Cette méthode fait toutes les requêtes en une seule fois pour éviter les incohérences
     */
    private function canUserPunchWithDetails(User $user, string $type): array
    {
        // Utiliser withoutGlobalScopes() pour éviter tout problème de scope
        $today = now()->startOfDay();
        $tomorrow = now()->copy()->addDay()->startOfDay();
        
        // Vérifier les pointages sans check-out (en cours)
        $todayAttendance = Attendance::withoutGlobalScopes()
            ->where('user_id', $user->id)
            ->where('check_in_time', '>=', $today)
            ->where('check_in_time', '<', $tomorrow)
            ->whereNull('check_out_time')
            ->orderBy('check_in_time', 'desc')
            ->first();
        
        // Vérifier les pointages avec check-out (complétés)
        $todayCompleted = Attendance::withoutGlobalScopes()
            ->where('user_id', $user->id)
            ->where('check_in_time', '>=', $today)
            ->where('check_in_time', '<', $tomorrow)
            ->whereNotNull('check_out_time')
            ->exists();
        
        if ($type === 'check_in') {
            // Pour check-in : ne peut pas pointer si :
            // 1. Il y a déjà un pointage complété aujourd'hui
            // 2. Il y a déjà un pointage en cours (sans check-out)
            $canPunch = !$todayCompleted && !$todayAttendance;
        } else {
            // Pour check-out : peut pointer seulement s'il y a un pointage en cours (sans check-out)
            $canPunch = (bool)$todayAttendance;
        }
        
        Log::info('canUserPunchWithDetails', [
            'user_id' => $user->id,
            'type' => $type,
            'today' => $today->toDateTimeString(),
            'tomorrow' => $tomorrow->toDateTimeString(),
            'has_attendance_in_progress' => (bool)$todayAttendance,
            'has_attendance_completed' => $todayCompleted,
            'can_punch' => $canPunch,
            'attendance_id' => $todayAttendance?->id,
            'attendance_check_in' => $todayAttendance?->check_in_time?->toDateTimeString(),
            'attendance_check_out' => $todayAttendance?->check_out_time?->toDateTimeString(),
            'attendance_status' => $todayAttendance?->status,
        ]);
        
        return [
            'can_punch' => $canPunch,
            'today_attendance' => $todayAttendance,
            'today_completed' => $todayCompleted,
        ];
    }

    /**
     * Vérifier si l'utilisateur peut pointer (méthode simplifiée pour store())
     * Utilise canUserPunchWithDetails() en interne
     */
    private function canUserPunch(User $user, string $type): bool
    {
        $details = $this->canUserPunchWithDetails($user, $type);
        return $details['can_punch'];
    }

    /**
     * Vérifier si l'utilisateur peut approuver
     * Les rôles autorisés sont : Admin (1), Patron (6), RH (4)
     */
    private function canApprove(User $user): bool
    {
        return in_array($user->role, [1, 4, 6]) || $user->isAdmin() || $user->isPatron();
    }

    /**
     * Mapper les statuts du frontend vers le backend
     */
    private function mapStatusFromFrontend(string $frontendStatus): string
    {
        $statusMapping = [
            'pending' => 'en_attente',
            'approved' => 'valide',
            'rejected' => 'rejete',
            'en_attente' => 'en_attente',
            'valide' => 'valide',
            'rejete' => 'rejete',
        ];
        
        return $statusMapping[$frontendStatus] ?? $frontendStatus;
    }

    /**
     * Pointage d'arrivée (check-in)
     */
    public function checkIn(Request $request): JsonResponse
    {
        // Ajouter le type check_in à la requête
        $request->merge(['type' => 'check_in']);
        return $this->store($request);
    }

    /**
     * Pointage de départ (check-out)
     */
    public function checkOut(Request $request): JsonResponse
    {
        // Ajouter le type check_out à la requête
        $request->merge(['type' => 'check_out']);
        return $this->store($request);
    }

    /**
     * Obtenir le statut actuel du pointage
     */
    public function currentStatus(Request $request): JsonResponse
    {
        $user = $request->user();
        
        $today = now()->startOfDay();
        $tomorrow = now()->copy()->addDay()->startOfDay();
        
        // Vérifier s'il y a un pointage aujourd'hui sans check-out
        $todayAttendance = Attendance::where('user_id', $user->id)
            ->where('check_in_time', '>=', $today)
            ->where('check_in_time', '<', $tomorrow)
            ->whereNull('check_out_time')
            ->first();

        if ($todayAttendance) {
            return response()->json([
                'can_punch' => true,
                'message' => 'Vous pouvez pointer votre départ',
                'status' => 'checked_in'
            ]);
        }

        // Vérifier s'il y a un pointage aujourd'hui avec check-out
        $todayCompleted = Attendance::where('user_id', $user->id)
            ->where('check_in_time', '>=', $today)
            ->where('check_in_time', '<', $tomorrow)
            ->whereNotNull('check_out_time')
            ->exists();

        if ($todayCompleted) {
            return response()->json([
                'can_punch' => false,
                'message' => 'Vous avez déjà pointé aujourd\'hui',
                'status' => 'checked_out'
            ]);
        }

        // Pas de pointage aujourd'hui
        return response()->json([
            'can_punch' => true,
            'message' => 'Vous pouvez pointer votre arrivée',
            'status' => 'no_attendance'
        ]);
    }

    /**
     * Mettre à jour un pointage
     */
    public function update(Request $request, Attendance $attendance): JsonResponse
    {
        // Seul l'utilisateur propriétaire ou un admin peut modifier
        $user = $request->user();
        
        if ($attendance->user_id !== $user->id && !$this->canApprove($user)) {
            return response()->json([
                'success' => false,
                'message' => 'Vous n\'avez pas l\'autorisation de modifier ce pointage'
            ], 403);
        }

        // Si le pointage est déjà approuvé, seul un admin peut le modifier
        if ($attendance->status === 'valide' && !$this->canApprove($user)) {
            return response()->json([
                'success' => false,
                'message' => 'Impossible de modifier un pointage approuvé'
            ], 400);
        }

        $validator = Validator::make($request->all(), [
            'latitude' => 'nullable|numeric|between:-90,90',
            'longitude' => 'nullable|numeric|between:-180,180',
            'address' => 'nullable|string|max:255',
            'accuracy' => 'nullable|numeric|min:0',
            'notes' => 'nullable|string|max:1000',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Données invalides',
                'errors' => $validator->errors()
            ], 422);
        }

        // Mettre à jour la localisation en JSON si fournie
        $updateData = ['notes' => $request->notes];
        if ($request->has('latitude') || $request->has('longitude')) {
            $location = $attendance->location ?? [];
            if ($request->has('latitude')) $location['latitude'] = $request->latitude;
            if ($request->has('longitude')) $location['longitude'] = $request->longitude;
            if ($request->has('address')) $location['address'] = $request->address;
            if ($request->has('accuracy')) $location['accuracy'] = $request->accuracy;
            $updateData['location'] = $location;
        }

        $attendance->update($updateData);

        return response()->json([
            'success' => true,
            'message' => 'Pointage mis à jour avec succès',
            'data' => $attendance->fresh(['user'])
        ]);
    }

    /**
     * Supprimer un pointage
     */
    public function destroy(Attendance $attendance): JsonResponse
    {
        $user = request()->user();
        
        // Seul l'utilisateur propriétaire ou un admin peut supprimer
        if ($attendance->user_id !== $user->id && !$this->canApprove($user)) {
            return response()->json([
                'success' => false,
                'message' => 'Vous n\'avez pas l\'autorisation de supprimer ce pointage'
            ], 403);
        }

        // Supprimer la photo si elle existe
        if ($attendance->photo_path) {
            Storage::disk('public')->delete($attendance->photo_path);
        }

        $attendance->delete();

        return response()->json([
            'success' => true,
            'message' => 'Pointage supprimé avec succès'
        ]);
    }

    /**
     * Statistiques de pointage
     */
    public function statistics(Request $request): JsonResponse
    {
        $user = $request->user();
        $query = Attendance::where('user_id', $user->id);

        // Filtres par date
        if ($request->has('date_from')) {
            $query->whereDate('check_in_time', '>=', $request->date_from);
        }

        if ($request->has('date_to')) {
            $query->whereDate('check_in_time', '<=', $request->date_to);
        }

        $total = $query->count();
        $approved = (clone $query)->where('status', 'valide')->count();
        $pending = (clone $query)->where('status', 'en_attente')->count();
        $rejected = (clone $query)->where('status', 'rejete')->count();
        $checkIns = (clone $query)->whereNotNull('check_in_time')->count();
        $checkOuts = (clone $query)->whereNotNull('check_out_time')->count();

        return response()->json([
            'success' => true,
            'data' => [
                'total' => $total,
                'approved' => $approved,
                'pending' => $pending,
                'rejected' => $rejected,
                'check_ins' => $checkIns,
                'check_outs' => $checkOuts,
            ]
        ]);
    }

    /**
     * Paramètres de pointage
     */
    public function settings(): JsonResponse
    {
        // Cette méthode peut retourner les paramètres de pointage depuis la table attendance_settings
        // Pour l'instant, retourner des valeurs par défaut
        return response()->json([
            'success' => true,
            'data' => [
                'require_photo' => true,
                'require_location' => true,
                'max_distance_meters' => 100,
                'work_hours_start' => '08:00',
                'work_hours_end' => '17:00',
            ]
        ]);
    }
}
