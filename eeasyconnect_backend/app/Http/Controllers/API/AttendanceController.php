<?php

namespace App\Http\Controllers\API;

use App\Http\Controllers\Controller;
use App\Models\Attendance;
use App\Models\AttendanceSettings;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Carbon\Carbon;

class AttendanceController extends Controller
{
    /**
     * Afficher la liste des pointages
     */
    public function index(Request $request)
    {
        try {
            $user = $request->user();
            $query = Attendance::with(['user']);

            // Filtrage par utilisateur
            if ($request->has('user_id')) {
                $query->where('user_id', $request->user_id);
            }

            // Filtrage par date
            if ($request->has('date_debut')) {
                $query->where('check_in_time', '>=', $request->date_debut);
            }

            if ($request->has('date_fin')) {
                $query->where('check_in_time', '<=', $request->date_fin);
            }

            // Filtrage par statut
            if ($request->has('status')) {
                $query->where('status', $request->status);
            }

            // Si commercial/comptable/technicien → filtre ses propres pointages
            if (in_array($user->role, [2, 3, 5])) {
                $query->where('user_id', $user->id);
            }

            // Pagination
            $perPage = $request->get('per_page', 15);
            $attendances = $query->orderBy('check_in_time', 'desc')->paginate($perPage);

            // Ajouter les informations utilisateur
            $attendances->getCollection()->transform(function ($attendance) {
                return [
                    'id' => $attendance->id,
                    'user_id' => $attendance->user_id,
                    'user_name' => $attendance->user_name,
                    'user_role' => $attendance->user_role,
                    'check_in_time' => $attendance->check_in_time->format('Y-m-d H:i:s'),
                    'check_out_time' => $attendance->check_out_time?->format('Y-m-d H:i:s'),
                    'status' => $attendance->status,
                    'location' => $attendance->location_info,
                    'photo_path' => $attendance->photo_path,
                    'notes' => $attendance->notes,
                    'work_duration_hours' => $attendance->getWorkDurationInHours(),
                    'is_late' => $attendance->isLate(),
                    'late_minutes' => $attendance->getLateMinutes(),
                    'created_at' => $attendance->created_at->format('Y-m-d H:i:s'),
                    'updated_at' => $attendance->updated_at->format('Y-m-d H:i:s'),
                ];
            });

            return response()->json([
                'success' => true,
                'data' => $attendances,
                'message' => 'Liste des pointages récupérée avec succès'
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de la récupération des pointages: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Pointer l'arrivée
     */
    public function checkIn(Request $request)
    {
        try {
            $user = $request->user();
            
            // Vérifier si l'utilisateur peut pointer
            if (!Attendance::canCheckIn($user->id)) {
                return response()->json([
                    'success' => false,
                    'message' => 'Vous avez déjà pointé aujourd\'hui'
                ], 400);
            }

            $validated = $request->validate([
                'location' => 'required|array',
                'location.latitude' => 'required|numeric',
                'location.longitude' => 'required|numeric',
                'location.address' => 'nullable|string',
                'location.accuracy' => 'nullable|numeric',
                'photo_path' => 'nullable|string',
                'notes' => 'nullable|string'
            ]);

            $checkInTime = now();
            $settings = AttendanceSettings::getActiveSettings();
            
            // Vérifier la géolocalisation
            if ($settings->require_location) {
                if (!$settings->isLocationAllowed(
                    $validated['location']['latitude'],
                    $validated['location']['longitude']
                )) {
                    return response()->json([
                        'success' => false,
                        'message' => 'Vous n\'êtes pas dans une zone autorisée pour pointer'
                    ], 400);
                }
            }

            // Déterminer le statut
            $status = 'present';
            if ($settings->isLate($checkInTime)) {
                $status = 'late';
            }

            $attendance = Attendance::create([
                'user_id' => $user->id,
                'check_in_time' => $checkInTime,
                'status' => $status,
                'location' => $validated['location'],
                'photo_path' => $validated['photo_path'] ?? null,
                'notes' => $validated['notes'] ?? null
            ]);

            return response()->json([
                'success' => true,
                'data' => $attendance->load(['user']),
                'message' => 'Pointage d\'arrivée enregistré avec succès'
            ], 201);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors du pointage d\'arrivée: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Pointer le départ
     */
    public function checkOut(Request $request)
    {
        try {
            $user = $request->user();
            
            // Vérifier si l'utilisateur peut pointer
            if (!Attendance::canCheckOut($user->id)) {
                return response()->json([
                    'success' => false,
                    'message' => 'Vous devez d\'abord pointer votre arrivée'
                ], 400);
            }

            $validated = $request->validate([
                'notes' => 'nullable|string'
            ]);

            $checkOutTime = now();
            $settings = AttendanceSettings::getActiveSettings();
            
            // Récupérer le pointage d'aujourd'hui
            $attendance = Attendance::where('user_id', $user->id)
                ->whereDate('check_in_time', today())
                ->whereNull('check_out_time')
                ->first();

            if (!$attendance) {
                return response()->json([
                    'success' => false,
                    'message' => 'Aucun pointage d\'arrivée trouvé pour aujourd\'hui'
                ], 400);
            }

            // Vérifier si départ anticipé
            if ($settings->isEarlyLeave($checkOutTime)) {
                $attendance->status = 'early_leave';
            }

            $attendance->update([
                'check_out_time' => $checkOutTime,
                'notes' => $validated['notes'] ?? $attendance->notes
            ]);

            return response()->json([
                'success' => true,
                'data' => $attendance->load(['user']),
                'message' => 'Pointage de départ enregistré avec succès'
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors du pointage de départ: ' . $e->getMessage()
            ], 500);
        }
    }
}
