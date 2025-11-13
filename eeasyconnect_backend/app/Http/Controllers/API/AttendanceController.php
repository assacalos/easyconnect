<?php

namespace App\Http\Controllers\API;

use App\Http\Controllers\Controller;
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
        if (!$this->canUserPunch($user, $request->type)) {
            Log::warning('User cannot punch', ['user_id' => $user->id, 'type' => $request->type]);
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
                $todayAttendance = Attendance::where('user_id', $user->id)
                    ->whereDate('check_in_time', today())
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
                $todayAttendance = Attendance::where('user_id', $user->id)
                    ->whereDate('check_in_time', today())
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
            $query->where('status', $request->status);
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

        if ($attendance->approve($user, $request->input('comment'))) {
            return response()->json([
                'success' => true,
                'message' => 'Pointage approuvé avec succès',
                'data' => $attendance->fresh(['user', 'validator'])
            ]);
        }

        return response()->json([
            'success' => false,
            'message' => 'Impossible d\'approuver ce pointage'
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

        if ($attendance->reject($user, $request->reason, $request->input('comment'))) {
            return response()->json([
                'success' => true,
                'message' => 'Pointage rejeté avec succès',
                'data' => $attendance->fresh(['user', 'rejector'])
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
     */
    public function canPunch(Request $request): JsonResponse
    {
        $user = $request->user();
        $type = $request->query('type', 'check_in');

        $canPunch = $this->canUserPunch($user, $type);

        return response()->json([
            'success' => true,
            'can_punch' => $canPunch,
            'message' => $canPunch ? 'Vous pouvez pointer' : 'Vous ne pouvez pas pointer maintenant'
        ]);
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
     * Vérifier si l'utilisateur peut pointer
     */
    private function canUserPunch(User $user, string $type): bool
    {
        if ($type === 'check_in') {
            // Pour check-in : vérifier s'il n'y a pas déjà un check-in aujourd'hui sans check-out
            $todayAttendance = Attendance::where('user_id', $user->id)
                ->whereDate('check_in_time', today())
                ->whereNull('check_out_time')
                ->first();
            return !$todayAttendance; // Peut pointer si pas de pointage en cours
        } else {
            // Pour check-out : vérifier qu'il y a un check-in aujourd'hui sans check-out
            $todayAttendance = Attendance::where('user_id', $user->id)
                ->whereDate('check_in_time', today())
                ->whereNull('check_out_time')
                ->first();
            return (bool)$todayAttendance; // Peut pointer si pointage en cours
        }
    }

    /**
     * Vérifier si l'utilisateur peut approuver
     */
    private function canApprove(User $user): bool
    {
        return in_array($user->role, ['admin', 'patron', 'rh']);
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
        
        // Vérifier s'il y a un pointage aujourd'hui sans check-out
        $todayAttendance = Attendance::where('user_id', $user->id)
            ->whereDate('check_in_time', today())
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
            ->whereDate('check_in_time', today())
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