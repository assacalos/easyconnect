<?php

namespace App\Http\Controllers\API;

use App\Http\Controllers\Controller;
use App\Models\RecruitmentRequest;
use App\Models\RecruitmentApplication;
use App\Models\RecruitmentDocument;
use App\Models\RecruitmentInterview;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class RecruitmentController extends Controller
{
    /**
     * Afficher la liste des demandes de recrutement
     */
    public function index(Request $request)
    {
        try {
            $query = RecruitmentRequest::with(['creator', 'publisher', 'approver', 'applications']);

            // Filtrage par statut
            if ($request->has('status')) {
                $query->where('status', $request->status);
            }

            // Filtrage par département
            if ($request->has('department')) {
                $query->where('department', $request->department);
            }

            // Filtrage par poste
            if ($request->has('position')) {
                $query->where('position', $request->position);
            }

            // Filtrage par type d'emploi
            if ($request->has('employment_type')) {
                $query->where('employment_type', $request->employment_type);
            }

            // Filtrage par niveau d'expérience
            if ($request->has('experience_level')) {
                $query->where('experience_level', $request->experience_level);
            }

            // Filtrage par titre
            if ($request->has('title')) {
                $query->where('title', 'like', '%' . $request->title . '%');
            }

            // Filtrage par localisation
            if ($request->has('location')) {
                $query->where('location', 'like', '%' . $request->location . '%');
            }

            // Filtrage par date limite
            if ($request->has('deadline_from')) {
                $query->where('application_deadline', '>=', $request->deadline_from);
            }

            if ($request->has('deadline_to')) {
                $query->where('application_deadline', '<=', $request->deadline_to);
            }

            // Filtrage par expirant
            if ($request->has('expiring')) {
                if ($request->expiring === 'true') {
                    $query->expiring();
                }
            }

            // Filtrage par expiré
            if ($request->has('expired')) {
                if ($request->expired === 'true') {
                    $query->expired();
                }
            }

            // Pagination
            $perPage = $request->get('per_page', 15);
            $requests = $query->orderBy('created_at', 'desc')->paginate($perPage);

            // Transformer les données
            $requests->getCollection()->transform(function ($request) {
                return [
                    'id' => $request->id,
                    'title' => $request->title,
                    'department' => $request->department,
                    'position' => $request->position,
                    'description' => $request->description,
                    'requirements' => $request->requirements,
                    'responsibilities' => $request->responsibilities,
                    'number_of_positions' => $request->number_of_positions,
                    'employment_type' => $request->employment_type,
                    'employment_type_libelle' => $request->employment_type_libelle,
                    'experience_level' => $request->experience_level,
                    'experience_level_libelle' => $request->experience_level_libelle,
                    'salary_range' => $request->salary_range,
                    'location' => $request->location,
                    'application_deadline' => $request->application_deadline?->format('Y-m-d'),
                    'status' => $request->status,
                    'status_libelle' => $request->status_libelle,
                    'rejection_reason' => $request->rejection_reason,
                    'published_at' => $request->published_at?->format('Y-m-d H:i:s'),
                    'published_by' => $request->published_by,
                    'publisher_name' => $request->publisher_name,
                    'approved_at' => $request->approved_at?->format('Y-m-d H:i:s'),
                    'approved_by' => $request->approved_by,
                    'approver_name' => $request->approver_name,
                    'created_by' => $request->created_by,
                    'creator_name' => $request->creator_name,
                    'updated_by' => $request->updated_by,
                    'updater_name' => $request->updater_name,
                    'is_draft' => $request->is_draft,
                    'is_published' => $request->is_published,
                    'is_closed' => $request->is_closed,
                    'is_cancelled' => $request->is_cancelled,
                    'can_publish' => $request->can_publish,
                    'can_close' => $request->can_close,
                    'can_cancel' => $request->can_cancel,
                    'can_edit' => $request->can_edit,
                    'is_expiring' => $request->is_expiring,
                    'is_expired' => $request->is_expired,
                    'applications_count' => $request->applications_count,
                    'pending_applications_count' => $request->pending_applications_count,
                    'shortlisted_applications_count' => $request->shortlisted_applications_count,
                    'hired_applications_count' => $request->hired_applications_count,
                    'applications' => $request->applications->map(function ($application) {
                        return [
                            'id' => $application->id,
                            'candidate_name' => $application->candidate_name,
                            'candidate_email' => $application->candidate_email,
                            'candidate_phone' => $application->candidate_phone,
                            'status' => $application->status,
                            'status_libelle' => $application->status_libelle,
                            'created_at' => $application->created_at->format('Y-m-d H:i:s')
                        ];
                    }),
                    'created_at' => $request->created_at->format('Y-m-d H:i:s'),
                    'updated_at' => $request->updated_at->format('Y-m-d H:i:s')
                ];
            });

            return response()->json([
                'success' => true,
                'data' => $requests,
                'message' => 'Liste des demandes de recrutement récupérée avec succès'
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de la récupération des demandes: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Afficher une demande de recrutement spécifique
     */
    public function show($id)
    {
        try {
            $request = RecruitmentRequest::with(['creator', 'publisher', 'approver', 'applications.documents', 'applications.interviews'])->find($id);

            if (!$request) {
                return response()->json([
                    'success' => false,
                    'message' => 'Demande de recrutement non trouvée'
                ], 404);
            }

            return response()->json([
                'success' => true,
                'data' => $request,
                'message' => 'Demande de recrutement récupérée avec succès'
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de la récupération de la demande: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Créer une nouvelle demande de recrutement
     */
    public function store(Request $request)
    {
        try {
            $validated = $request->validate([
                'title' => 'required|string|max:255',
                'department' => 'required|string|max:255',
                'position' => 'required|string|max:255',
                'description' => 'required|string',
                'requirements' => 'required|string',
                'responsibilities' => 'required|string',
                'number_of_positions' => 'required|integer|min:1',
                'employment_type' => 'required|in:full_time,part_time,contract,internship',
                'experience_level' => 'required|in:entry,junior,mid,senior,expert',
                'salary_range' => 'required|string|max:255',
                'location' => 'required|string|max:255',
                'application_deadline' => 'required|date|after:today'
            ]);

            DB::beginTransaction();

            $recruitmentRequest = RecruitmentRequest::create([
                'title' => $validated['title'],
                'department' => $validated['department'],
                'position' => $validated['position'],
                'description' => $validated['description'],
                'requirements' => $validated['requirements'],
                'responsibilities' => $validated['responsibilities'],
                'number_of_positions' => $validated['number_of_positions'],
                'employment_type' => $validated['employment_type'],
                'experience_level' => $validated['experience_level'],
                'salary_range' => $validated['salary_range'],
                'location' => $validated['location'],
                'application_deadline' => $validated['application_deadline'],
                'status' => 'draft',
                'created_by' => $request->user()->id
            ]);

            DB::commit();

            return response()->json([
                'success' => true,
                'data' => $recruitmentRequest->load(['creator']),
                'message' => 'Demande de recrutement créée avec succès'
            ], 201);

        } catch (\Exception $e) {
            DB::rollback();
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de la création de la demande: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Mettre à jour une demande de recrutement
     */
    public function update(Request $request, $id)
    {
        try {
            $recruitmentRequest = RecruitmentRequest::find($id);

            if (!$recruitmentRequest) {
                return response()->json([
                    'success' => false,
                    'message' => 'Demande de recrutement non trouvée'
                ], 404);
            }

            if (!$recruitmentRequest->can_edit) {
                return response()->json([
                    'success' => false,
                    'message' => 'Cette demande ne peut pas être modifiée'
                ], 403);
            }

            $validated = $request->validate([
                'title' => 'sometimes|string|max:255',
                'department' => 'sometimes|string|max:255',
                'position' => 'sometimes|string|max:255',
                'description' => 'sometimes|string',
                'requirements' => 'sometimes|string',
                'responsibilities' => 'sometimes|string',
                'number_of_positions' => 'sometimes|integer|min:1',
                'employment_type' => 'sometimes|in:full_time,part_time,contract,internship',
                'experience_level' => 'sometimes|in:entry,junior,mid,senior,expert',
                'salary_range' => 'sometimes|string|max:255',
                'location' => 'sometimes|string|max:255',
                'application_deadline' => 'sometimes|date|after:today'
            ]);

            $recruitmentRequest->update(array_merge($validated, [
                'updated_by' => $request->user()->id
            ]));

            return response()->json([
                'success' => true,
                'data' => $recruitmentRequest->load(['creator', 'updater']),
                'message' => 'Demande de recrutement mise à jour avec succès'
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de la mise à jour de la demande: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Supprimer une demande de recrutement
     */
    public function destroy($id)
    {
        try {
            $recruitmentRequest = RecruitmentRequest::find($id);

            if (!$recruitmentRequest) {
                return response()->json([
                    'success' => false,
                    'message' => 'Demande de recrutement non trouvée'
                ], 404);
            }

            if (!$recruitmentRequest->can_edit) {
                return response()->json([
                    'success' => false,
                    'message' => 'Cette demande ne peut pas être supprimée'
                ], 403);
            }

            $recruitmentRequest->delete();

            return response()->json([
                'success' => true,
                'message' => 'Demande de recrutement supprimée avec succès'
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de la suppression de la demande: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Publier une demande de recrutement
     */
    public function publish($id)
    {
        try {
            $recruitmentRequest = RecruitmentRequest::find($id);

            if (!$recruitmentRequest) {
                return response()->json([
                    'success' => false,
                    'message' => 'Demande de recrutement non trouvée'
                ], 404);
            }

            if (!$recruitmentRequest->can_publish) {
                return response()->json([
                    'success' => false,
                    'message' => 'Cette demande ne peut pas être publiée'
                ], 403);
            }

            $recruitmentRequest->publish(request()->user()->id);

            return response()->json([
                'success' => true,
                'message' => 'Demande de recrutement publiée avec succès'
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de la publication: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Fermer une demande de recrutement
     */
    public function close($id)
    {
        try {
            $recruitmentRequest = RecruitmentRequest::find($id);

            if (!$recruitmentRequest) {
                return response()->json([
                    'success' => false,
                    'message' => 'Demande de recrutement non trouvée'
                ], 404);
            }

            if (!$recruitmentRequest->can_close) {
                return response()->json([
                    'success' => false,
                    'message' => 'Cette demande ne peut pas être fermée'
                ], 403);
            }

            $recruitmentRequest->close();

            return response()->json([
                'success' => true,
                'message' => 'Demande de recrutement fermée avec succès'
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de la fermeture: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Annuler une demande de recrutement
     */
    public function cancel(Request $request, $id)
    {
        try {
            $recruitmentRequest = RecruitmentRequest::find($id);

            if (!$recruitmentRequest) {
                return response()->json([
                    'success' => false,
                    'message' => 'Demande de recrutement non trouvée'
                ], 404);
            }

            if (!$recruitmentRequest->can_cancel) {
                return response()->json([
                    'success' => false,
                    'message' => 'Cette demande ne peut pas être annulée'
                ], 403);
            }

            $validated = $request->validate([
                'reason' => 'nullable|string|max:1000'
            ]);

            $recruitmentRequest->cancel($validated['reason']);

            return response()->json([
                'success' => true,
                'message' => 'Demande de recrutement annulée avec succès'
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de l\'annulation: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Approuver une demande de recrutement
     */
    public function approve($id)
    {
        try {
            $recruitmentRequest = RecruitmentRequest::find($id);

            if (!$recruitmentRequest) {
                return response()->json([
                    'success' => false,
                    'message' => 'Demande de recrutement non trouvée'
                ], 404);
            }

            $recruitmentRequest->approve(request()->user()->id);

            return response()->json([
                'success' => true,
                'message' => 'Demande de recrutement approuvée avec succès'
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de l\'approbation: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Statistiques des recrutements
     */
    public function statistics(Request $request)
    {
        try {
            $stats = RecruitmentRequest::getRecruitmentStats();

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
     * Récupérer les demandes par département
     */
    public function byDepartment($department)
    {
        try {
            $requests = RecruitmentRequest::getRequestsByDepartment($department);

            return response()->json([
                'success' => true,
                'data' => $requests,
                'message' => 'Demandes du département récupérées avec succès'
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de la récupération des demandes du département: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Récupérer les demandes par poste
     */
    public function byPosition($position)
    {
        try {
            $requests = RecruitmentRequest::getRequestsByPosition($position);

            return response()->json([
                'success' => true,
                'data' => $requests,
                'message' => 'Demandes du poste récupérées avec succès'
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de la récupération des demandes du poste: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Récupérer les demandes expirant
     */
    public function expiring()
    {
        try {
            $requests = RecruitmentRequest::getExpiringRequests();

            return response()->json([
                'success' => true,
                'data' => $requests,
                'message' => 'Demandes expirant récupérées avec succès'
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de la récupération des demandes expirant: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Récupérer les demandes expirées
     */
    public function expired()
    {
        try {
            $requests = RecruitmentRequest::getExpiredRequests();

            return response()->json([
                'success' => true,
                'data' => $requests,
                'message' => 'Demandes expirées récupérées avec succès'
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de la récupération des demandes expirées: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Récupérer les demandes publiées
     */
    public function published()
    {
        try {
            $requests = RecruitmentRequest::getPublishedRequests();

            return response()->json([
                'success' => true,
                'data' => $requests,
                'message' => 'Demandes publiées récupérées avec succès'
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de la récupération des demandes publiées: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Récupérer les demandes brouillons
     */
    public function drafts()
    {
        try {
            $requests = RecruitmentRequest::getDraftRequests();

            return response()->json([
                'success' => true,
                'data' => $requests,
                'message' => 'Demandes brouillons récupérées avec succès'
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de la récupération des demandes brouillons: ' . $e->getMessage()
            ], 500);
        }
    }
}

