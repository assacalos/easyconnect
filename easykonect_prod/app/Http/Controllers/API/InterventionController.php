<?php

namespace App\Http\Controllers\API;

use App\Http\Controllers\Controller;
use App\Models\Intervention;
use App\Models\InterventionType;
use App\Models\Equipment;
use App\Models\InterventionReport;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class InterventionController extends Controller
{
    /**
     * Afficher la liste des interventions
     */
    public function index(Request $request)
    {
        try {
            $user = $request->user();
            $query = Intervention::with(['creator', 'approver', 'reports.technician']);

            // Filtrage par statut
            if ($request->has('status')) {
                $query->where('status', $request->status);
            }

            // Filtrage par type
            if ($request->has('type')) {
                $query->where('type', $request->type);
            }

            // Filtrage par priorité
            if ($request->has('priority')) {
                $query->where('priority', $request->priority);
            }

            // Filtrage par créateur
            if ($request->has('created_by')) {
                $query->where('created_by', $request->created_by);
            }

            // Filtrage par date
            if ($request->has('date_debut')) {
                $query->where('scheduled_date', '>=', $request->date_debut);
            }

            if ($request->has('date_fin')) {
                $query->where('scheduled_date', '<=', $request->date_fin);
            }

            // Filtrage par lieu
            if ($request->has('location')) {
                $query->where('location', 'like', '%' . $request->location . '%');
            }

            // Si technicien → filtre ses interventions
            if ($user->role == 5) { // Technicien
                $query->where('created_by', $user->id);
            }

            // Pagination
            $perPage = $request->get('per_page', 15);
            $interventions = $query->orderBy('scheduled_date', 'desc')->paginate($perPage);

            // Transformer les données
            $interventions->getCollection()->transform(function ($intervention) {
                return [
                    'id' => $intervention->id,
                    'title' => $intervention->title,
                    'description' => $intervention->description,
                    'type' => $intervention->type,
                    'type_libelle' => $intervention->type_libelle,
                    'status' => $intervention->status,
                    'status_libelle' => $intervention->status_libelle,
                    'priority' => $intervention->priority,
                    'priority_libelle' => $intervention->priority_libelle,
                    'scheduled_date' => $intervention->scheduled_date->format('Y-m-d H:i:s'),
                    'start_date' => $intervention->start_date?->format('Y-m-d H:i:s'),
                    'end_date' => $intervention->end_date?->format('Y-m-d H:i:s'),
                    'location' => $intervention->location,
                    'client_name' => $intervention->client_name,
                    'client_phone' => $intervention->client_phone,
                    'client_email' => $intervention->client_email,
                    'equipment' => $intervention->equipment,
                    'problem_description' => $intervention->problem_description,
                    'solution' => $intervention->solution,
                    'notes' => $intervention->notes,
                    'attachments' => $intervention->attachments,
                    'estimated_duration' => $intervention->estimated_duration,
                    'actual_duration' => $intervention->actual_duration,
                    'calculated_duration' => $intervention->calculated_duration,
                    'cost' => $intervention->cost,
                    'formatted_cost' => $intervention->formatted_cost,
                    'formatted_estimated_duration' => $intervention->formatted_estimated_duration,
                    'formatted_actual_duration' => $intervention->formatted_actual_duration,
                    'created_by' => $intervention->created_by,
                    'creator_name' => $intervention->creator_name,
                    'approved_by' => $intervention->approved_by,
                    'approver_name' => $intervention->approver_name,
                    'approved_at' => $intervention->approved_at?->format('Y-m-d H:i:s'),
                    'rejection_reason' => $intervention->rejection_reason,
                    'completion_notes' => $intervention->completion_notes,
                    'is_overdue' => $intervention->is_overdue,
                    'is_due_soon' => $intervention->is_due_soon,
                    'can_be_edited' => $intervention->canBeEdited(),
                    'can_be_approved' => $intervention->canBeApproved(),
                    'can_be_rejected' => $intervention->canBeRejected(),
                    'can_be_started' => $intervention->canBeStarted(),
                    'can_be_completed' => $intervention->canBeCompleted(),
                    'reports' => $intervention->reports->map(function ($report) {
                        return [
                            'id' => $report->id,
                            'report_number' => $report->report_number,
                            'work_performed' => $report->work_performed,
                            'findings' => $report->findings,
                            'recommendations' => $report->recommendations,
                            'parts_used' => $report->parts_used,
                            'labor_hours' => $report->labor_hours,
                            'parts_cost' => $report->parts_cost,
                            'labor_cost' => $report->labor_cost,
                            'total_cost' => $report->total_cost,
                            'formatted_labor_hours' => $report->formatted_labor_hours,
                            'formatted_parts_cost' => $report->formatted_parts_cost,
                            'formatted_labor_cost' => $report->formatted_labor_cost,
                            'formatted_total_cost' => $report->formatted_total_cost,
                            'photos' => $report->photos,
                            'client_signature' => $report->client_signature,
                            'technician_signature' => $report->technician_signature,
                            'technician_name' => $report->technician_name,
                            'report_date' => $report->report_date->format('Y-m-d H:i:s'),
                            'created_at' => $report->created_at->format('Y-m-d H:i:s'),
                            'updated_at' => $report->updated_at->format('Y-m-d H:i:s')
                        ];
                    }),
                    'created_at' => $intervention->created_at->format('Y-m-d H:i:s'),
                    'updated_at' => $intervention->updated_at->format('Y-m-d H:i:s')
                ];
            });

            return response()->json([
                'success' => true,
                'data' => $interventions,
                'message' => 'Liste des interventions récupérée avec succès'
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de la récupération des interventions: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Afficher une intervention spécifique
     */
    public function show($id)
    {
        try {
            $intervention = Intervention::with(['creator', 'approver', 'reports.technician'])->find($id);

            if (!$intervention) {
                return response()->json([
                    'success' => false,
                    'message' => 'Intervention non trouvée'
                ], 404);
            }

            return response()->json([
                'success' => true,
                'data' => $intervention,
                'message' => 'Intervention récupérée avec succès'
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de la récupération de l\'intervention: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Créer une nouvelle intervention
     */
    public function store(Request $request)
    {
        try {
            $validated = $request->validate([
                'title' => 'required|string|max:255',
                'description' => 'required|string',
                'type' => 'required|in:external,on_site',
                'priority' => 'required|in:low,medium,high,urgent',
                'scheduled_date' => 'required|date|after:now',
                'location' => 'nullable|string|max:255',
                'client_name' => 'nullable|string|max:255',
                'client_phone' => 'nullable|string|max:20',
                'client_email' => 'nullable|email|max:255',
                'equipment' => 'nullable|string|max:255',
                'problem_description' => 'nullable|string',
                'estimated_duration' => 'nullable|numeric|min:0',
                'cost' => 'nullable|numeric|min:0',
                'notes' => 'nullable|string',
                'attachments' => 'nullable|array'
            ]);

            DB::beginTransaction();

            $intervention = Intervention::create([
                'title' => $validated['title'],
                'description' => $validated['description'],
                'type' => $validated['type'],
                'priority' => $validated['priority'],
                'scheduled_date' => $validated['scheduled_date'],
                'location' => $validated['location'] ?? null,
                'client_name' => $validated['client_name'] ?? null,
                'client_phone' => $validated['client_phone'] ?? null,
                'client_email' => $validated['client_email'] ?? null,
                'equipment' => $validated['equipment'] ?? null,
                'problem_description' => $validated['problem_description'] ?? null,
                'estimated_duration' => $validated['estimated_duration'] ?? null,
                'cost' => $validated['cost'] ?? null,
                'notes' => $validated['notes'] ?? null,
                'attachments' => $validated['attachments'] ?? null,
                'created_by' => $request->user()->id,
                'status' => 'pending'
            ]);

            DB::commit();

            return response()->json([
                'success' => true,
                'data' => $intervention->load(['creator']),
                'message' => 'Intervention créée avec succès'
            ], 201);

        } catch (\Exception $e) {
            DB::rollback();
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de la création de l\'intervention: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Mettre à jour une intervention
     */
    public function update(Request $request, $id)
    {
        try {
            $intervention = Intervention::find($id);

            if (!$intervention) {
                return response()->json([
                    'success' => false,
                    'message' => 'Intervention non trouvée'
                ], 404);
            }

            if (!$intervention->canBeEdited()) {
                return response()->json([
                    'success' => false,
                    'message' => 'Cette intervention ne peut plus être modifiée'
                ], 400);
            }

            $validated = $request->validate([
                'title' => 'sometimes|string|max:255',
                'description' => 'sometimes|string',
                'type' => 'sometimes|in:external,on_site',
                'priority' => 'sometimes|in:low,medium,high,urgent',
                'scheduled_date' => 'sometimes|date',
                'location' => 'nullable|string|max:255',
                'client_name' => 'nullable|string|max:255',
                'client_phone' => 'nullable|string|max:20',
                'client_email' => 'nullable|email|max:255',
                'equipment' => 'nullable|string|max:255',
                'problem_description' => 'nullable|string',
                'estimated_duration' => 'nullable|numeric|min:0',
                'cost' => 'nullable|numeric|min:0',
                'notes' => 'nullable|string',
                'attachments' => 'nullable|array'
            ]);

            $intervention->update($validated);

            return response()->json([
                'success' => true,
                'data' => $intervention->load(['creator', 'approver']),
                'message' => 'Intervention mise à jour avec succès'
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de la mise à jour de l\'intervention: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Supprimer une intervention
     */
    public function destroy($id)
    {
        try {
            $intervention = Intervention::find($id);

            if (!$intervention) {
                return response()->json([
                    'success' => false,
                    'message' => 'Intervention non trouvée'
                ], 404);
            }

            if (!$intervention->canBeEdited()) {
                return response()->json([
                    'success' => false,
                    'message' => 'Cette intervention ne peut plus être supprimée'
                ], 400);
            }

            $intervention->delete();

            return response()->json([
                'success' => true,
                'message' => 'Intervention supprimée avec succès'
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de la suppression de l\'intervention: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Approuver une intervention
     */
    public function approve(Request $request, $id)
    {
        try {
            $intervention = Intervention::find($id);

            if (!$intervention) {
                return response()->json([
                    'success' => false,
                    'message' => 'Intervention non trouvée'
                ], 404);
            }

            $notes = $request->get('notes');

            if ($intervention->approve($request->user()->id, $notes)) {
                return response()->json([
                    'success' => true,
                    'message' => 'Intervention approuvée avec succès'
                ]);
            } else {
                return response()->json([
                    'success' => false,
                    'message' => 'Cette intervention ne peut pas être approuvée'
                ], 400);
            }

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de l\'approbation: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Rejeter une intervention
     */
    public function reject(Request $request, $id)
    {
        try {
            $intervention = Intervention::find($id);

            if (!$intervention) {
                return response()->json([
                    'success' => false,
                    'message' => 'Intervention non trouvée'
                ], 404);
            }

            $validated = $request->validate([
                'rejection_reason' => 'required|string|max:1000'
            ]);

            if ($intervention->reject($validated['rejection_reason'])) {
                return response()->json([
                    'success' => true,
                    'message' => 'Intervention rejetée avec succès'
                ]);
            } else {
                return response()->json([
                    'success' => false,
                    'message' => 'Cette intervention ne peut pas être rejetée'
                ], 400);
            }

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors du rejet: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Démarrer une intervention
     */
    public function start($id)
    {
        try {
            $intervention = Intervention::find($id);

            if (!$intervention) {
                return response()->json([
                    'success' => false,
                    'message' => 'Intervention non trouvée'
                ], 404);
            }

            if ($intervention->start()) {
                return response()->json([
                    'success' => true,
                    'message' => 'Intervention démarrée avec succès'
                ]);
            } else {
                return response()->json([
                    'success' => false,
                    'message' => 'Cette intervention ne peut pas être démarrée'
                ], 400);
            }

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors du démarrage: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Terminer une intervention
     */
    public function complete(Request $request, $id)
    {
        try {
            $intervention = Intervention::find($id);

            if (!$intervention) {
                return response()->json([
                    'success' => false,
                    'message' => 'Intervention non trouvée'
                ], 404);
            }

            $validated = $request->validate([
                'completion_notes' => 'nullable|string|max:1000',
                'actual_duration' => 'nullable|numeric|min:0',
                'cost' => 'nullable|numeric|min:0'
            ]);

            if ($intervention->complete(
                $validated['completion_notes'] ?? null,
                $validated['actual_duration'] ?? null,
                $validated['cost'] ?? null
            )) {
                return response()->json([
                    'success' => true,
                    'message' => 'Intervention terminée avec succès'
                ]);
            } else {
                return response()->json([
                    'success' => false,
                    'message' => 'Cette intervention ne peut pas être terminée'
                ], 400);
            }

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de la finalisation: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Statistiques des interventions
     */
    public function statistics(Request $request)
    {
        try {
            $startDate = $request->get('date_debut');
            $endDate = $request->get('date_fin');

            $stats = Intervention::getInterventionStats($startDate, $endDate);

            return response()->json([
                'success' => true,
                'data' => $stats,
                'message' => 'Statistiques récupérées avec succès'
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de la récupération des statistiques: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Récupérer les interventions en retard
     */
    public function overdue()
    {
        try {
            $interventions = Intervention::getOverdueInterventions();

            return response()->json([
                'success' => true,
                'data' => $interventions,
                'message' => 'Interventions en retard récupérées avec succès'
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de la récupération des interventions en retard: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Récupérer les interventions dues bientôt
     */
    public function dueSoon()
    {
        try {
            $interventions = Intervention::getDueSoonInterventions();

            return response()->json([
                'success' => true,
                'data' => $interventions,
                'message' => 'Interventions dues bientôt récupérées avec succès'
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de la récupération des interventions dues bientôt: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Récupérer les types d'interventions
     */
    public function types()
    {
        try {
            $types = InterventionType::getActiveTypes();

            return response()->json([
                'success' => true,
                'data' => $types,
                'message' => 'Types d\'interventions récupérés avec succès'
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de la récupération des types: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Récupérer les équipements
     */
    public function equipment()
    {
        try {
            $equipment = Equipment::getActiveEquipment();

            return response()->json([
                'success' => true,
                'data' => $equipment,
                'message' => 'Équipements récupérés avec succès'
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de la récupération des équipements: ' . $e->getMessage()
            ], 500);
        }
    }
}
