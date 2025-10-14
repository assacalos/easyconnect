<?php

namespace App\Http\Controllers\API;

use App\Http\Controllers\Controller;
use App\Models\Attendance;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;
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
            return response()->json([
                'success' => false,
                'message' => 'Données invalides',
                'errors' => $validator->errors()
            ], 422);
        }

        $user = $request->user();

        // Vérifier si l'utilisateur peut pointer
        if (!$this->canUserPunch($user, $request->type)) {
            return response()->json([
                'success' => false,
                'message' => 'Vous ne pouvez pas pointer maintenant'
            ], 400);
        }

        try {
            // Upload de la photo
            $photoPath = $this->uploadPhoto($request->file('photo'), $user->id);

            // Créer le pointage
            $attendance = Attendance::create([
                'user_id' => $user->id,
                'type' => $request->type,
                'timestamp' => now(),
                'latitude' => $request->latitude,
                'longitude' => $request->longitude,
                'address' => $request->address,
                'accuracy' => $request->accuracy,
                'photo_path' => $photoPath,
                'notes' => $request->notes,
                'status' => 'pending',
            ]);

            return response()->json([
                'success' => true,
                'message' => 'Pointage enregistré avec succès',
                'data' => $attendance->load('user')
            ], 201);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de l\'enregistrement du pointage',
                'error' => $e->getMessage()
            ], 500);
        }
    }

    /**
     * Lister tous les pointages (pour le patron)
     */
    public function index(Request $request): JsonResponse
    {
        $query = Attendance::with(['user', 'approver']);

        // Filtres
        if ($request->has('status')) {
            $query->where('status', $request->status);
        }

        if ($request->has('type')) {
            $query->where('type', $request->type);
        }

        if ($request->has('user_id')) {
            $query->where('user_id', $request->user_id);
        }

        if ($request->has('date_from')) {
            $query->whereDate('timestamp', '>=', $request->date_from);
        }

        if ($request->has('date_to')) {
            $query->whereDate('timestamp', '<=', $request->date_to);
        }

        $attendances = $query->orderBy('timestamp', 'desc')->paginate(20);

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

        if ($attendance->approve($user)) {
            return response()->json([
                'success' => true,
                'message' => 'Pointage approuvé avec succès',
                'data' => $attendance->fresh(['user', 'approver'])
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

        if ($attendance->reject($user, $request->reason)) {
            return response()->json([
                'success' => true,
                'message' => 'Pointage rejeté avec succès',
                'data' => $attendance->fresh(['user', 'approver'])
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
        $filename = Str::uuid() . '.' . $photo->getClientOriginalExtension();
        $path = "attendances/{$userId}/{$filename}";
        
        Storage::disk('public')->put($path, file_get_contents($photo));
        
        return $path;
    }

    /**
     * Vérifier si l'utilisateur peut pointer
     */
    private function canUserPunch(User $user, string $type): bool
    {
        $lastAttendance = Attendance::where('user_id', $user->id)
            ->orderBy('timestamp', 'desc')
            ->first();

        if (!$lastAttendance) {
            return $type === 'check_in';
        }

        return $lastAttendance->type !== $type;
    }

    /**
     * Vérifier si l'utilisateur peut approuver
     */
    private function canApprove(User $user): bool
    {
        return in_array($user->role, ['admin', 'patron', 'rh']);
    }
}