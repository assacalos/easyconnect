<?php

namespace App\Http\Controllers\API;

use App\Http\Controllers\Controller;
use App\Models\Reporting;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Carbon\Carbon;

class UserReportingController extends Controller
{
    /**
     * Afficher la liste des reportings
     */
    public function index(Request $request)
    {
        try {
            $user = $request->user();
            $query = Reporting::with(['user', 'approver']);

            // Filtrage par statut
            if ($request->has('status')) {
                $query->where('status', $request->status);
            }

            // Filtrage par date
            if ($request->has('date_debut')) {
                $query->where('report_date', '>=', $request->date_debut);
            }

            if ($request->has('date_fin')) {
                $query->where('report_date', '<=', $request->date_fin);
            }

            // Filtrage par utilisateur
            if ($request->has('user_id')) {
                $query->where('user_id', $request->user_id);
            }

            // Si commercial/comptable/technicien → filtre ses propres reportings
            if (in_array($user->role, [2, 3, 5])) {
                $query->where('user_id', $user->id);
            }

            // Pagination
            $perPage = $request->get('per_page', 15);
            $reportings = $query->orderBy('report_date', 'desc')->paginate($perPage);

            // Ajouter les informations utilisateur
            $reportings->getCollection()->transform(function ($reporting) {
                return [
                    'id' => $reporting->id,
                    'user_id' => $reporting->user_id,
                    'user_name' => $reporting->user_name,
                    'user_role' => $reporting->user_role,
                    'report_date' => $reporting->report_date->format('Y-m-d'),
                    'metrics' => $reporting->metrics,
                    'status' => $reporting->status,
                    'submitted_at' => $reporting->submitted_at?->format('Y-m-d H:i:s'),
                    'approved_at' => $reporting->approved_at?->format('Y-m-d H:i:s'),
                    'comments' => $reporting->comments,
                    'created_at' => $reporting->created_at->format('Y-m-d H:i:s'),
                    'updated_at' => $reporting->updated_at->format('Y-m-d H:i:s'),
                ];
            });

            return response()->json([
                'success' => true,
                'data' => $reportings,
                'message' => 'Liste des reportings récupérée avec succès'
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de la récupération des reportings: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Afficher un reporting spécifique
     */
    public function show($id)
    {
        try {
            $reporting = Reporting::with(['user', 'approver'])->find($id);

            if (!$reporting) {
                return response()->json([
                    'success' => false,
                    'message' => 'Reporting non trouvé'
                ], 404);
            }

            $data = [
                'id' => $reporting->id,
                'user_id' => $reporting->user_id,
                'user_name' => $reporting->user_name,
                'user_role' => $reporting->user_role,
                'report_date' => $reporting->report_date->format('Y-m-d'),
                'metrics' => $reporting->metrics,
                'status' => $reporting->status,
                'submitted_at' => $reporting->submitted_at?->format('Y-m-d H:i:s'),
                'approved_at' => $reporting->approved_at?->format('Y-m-d H:i:s'),
                'comments' => $reporting->comments,
                'created_at' => $reporting->created_at->format('Y-m-d H:i:s'),
                'updated_at' => $reporting->updated_at->format('Y-m-d H:i:s'),
            ];

            return response()->json([
                'success' => true,
                'data' => $data,
                'message' => 'Reporting récupéré avec succès'
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de la récupération du reporting: ' . $e->getMessage()
            ], 500);
        }
    }
}
