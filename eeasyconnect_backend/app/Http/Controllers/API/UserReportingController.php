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

            // Ajouter les informations utilisateur et les notes
            $reportings->getCollection()->transform(function ($reporting) use ($user) {
                $data = [
                    'id' => $reporting->id,
                    'user_id' => $reporting->user_id,
                    'user_name' => $reporting->user_name,
                    'user_role' => $reporting->user_role,
                    'report_date' => $reporting->report_date?->format('Y-m-d'),
                    'metrics' => $reporting->metrics,
                    'notes' => $reporting->getAllNotes(), // Inclure toutes les notes
                    'status' => $reporting->status,
                    'submitted_at' => $reporting->submitted_at?->format('Y-m-d H:i:s'),
                    'approved_at' => $reporting->approved_at?->format('Y-m-d H:i:s'),
                    'comments' => $reporting->comments,
                    'created_at' => $reporting->created_at->format('Y-m-d H:i:s'),
                    'updated_at' => $reporting->updated_at->format('Y-m-d H:i:s'),
                ];
                
                // Ajouter patron_note uniquement pour Patron et Admin
                if (in_array($user->role, [1, 6])) {
                    $data['patron_note'] = $reporting->patron_note;
                }
                
                return $data;
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

            $user = $request->user();
            
            $data = [
                'id' => $reporting->id,
                'user_id' => $reporting->user_id,
                'user_name' => $reporting->user_name,
                'user_role' => $reporting->user_role,
                'report_date' => $reporting->report_date?->format('Y-m-d'),
                'metrics' => $reporting->metrics,
                'notes' => $reporting->getAllNotes(), // Inclure toutes les notes
                'status' => $reporting->status,
                'submitted_at' => $reporting->submitted_at?->format('Y-m-d H:i:s'),
                'approved_at' => $reporting->approved_at?->format('Y-m-d H:i:s'),
                'comments' => $reporting->comments,
                'created_at' => $reporting->created_at->format('Y-m-d H:i:s'),
                'updated_at' => $reporting->updated_at->format('Y-m-d H:i:s'),
            ];
            
            // Ajouter patron_note uniquement pour Patron et Admin
            if (in_array($user->role, [1, 6])) {
                $data['patron_note'] = $reporting->patron_note;
            }

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

    /**
     * Créer un nouveau reporting
     */
    public function store(Request $request)
    {
        try {
            $user = $request->user();
            
            $request->validate([
                'report_date' => 'required|date',
                'metrics' => 'nullable|array',
                'notes' => 'nullable|array'
            ]);

            $reporting = new Reporting();
            $reporting->user_id = $user->id;
            $reporting->report_date = $request->report_date;
            $reporting->status = 'submitted'; // Soumis directement, plus de draft
            $reporting->submitted_at = now(); // Date de soumission immédiate
            
            // Utiliser les métriques fournies ou générer automatiquement selon le rôle
            if ($request->has('metrics') && is_array($request->metrics)) {
                $reporting->metrics = $request->metrics;
            } else {
                // Générer les métriques selon le rôle
                $startDate = $request->report_date;
                $endDate = $request->report_date;
                
                switch ($user->role) {
                    case 2: // Commercial
                        $metrics = $reporting->generateCommercialMetrics($startDate, $endDate);
                        break;
                    case 3: // Comptable
                        $metrics = $reporting->generateComptableMetrics($startDate, $endDate);
                        break;
                    case 5: // Technicien
                        $metrics = $reporting->generateTechnicienMetrics($startDate, $endDate);
                        break;
                    default:
                        return response()->json([
                            'success' => false,
                            'message' => 'Rôle non autorisé pour créer un reporting'
                        ], 403);
                }
                $reporting->metrics = $metrics;
            }
            
            $reporting->save();
            
            // Ajouter les notes si fournies
            if ($request->has('notes') && is_array($request->notes)) {
                $reporting->updateNotes($request->notes);
                $reporting->save();
            }

            return response()->json([
                'success' => true,
                'data' => $reporting->load(['user', 'approver']),
                'message' => 'Reporting créé et soumis avec succès'
            ], 201);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de la création du reporting: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Mettre à jour un reporting
     */
    public function update(Request $request, $id)
    {
        try {
            $user = $request->user();
            $reporting = Reporting::findOrFail($id);
            
            // Vérifier les permissions
            if ($reporting->user_id !== $user->id && !in_array($user->role, [1, 6])) {
                return response()->json([
                    'success' => false,
                    'message' => 'Accès refusé à ce reporting'
                ], 403);
            }
            
            // Vérifier que le reporting peut être modifié
            if (!$reporting->canBeEdited()) {
                return response()->json([
                    'success' => false,
                    'message' => 'Ce reporting ne peut plus être modifié'
                ], 400);
            }

            $request->validate([
                'metrics' => 'nullable|array',
                'notes' => 'nullable|array'
            ]);

            // Mettre à jour les métriques si fournies
            if ($request->has('metrics')) {
                $reporting->metrics = $request->metrics;
            }
            
            // Mettre à jour les notes si fournies
            if ($request->has('notes')) {
                $reporting->updateNotes($request->notes);
            }
            
            $reporting->save();

            return response()->json([
                'success' => true,
                'data' => $reporting->load(['user', 'approver']),
                'message' => 'Reporting mis à jour avec succès'
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de la mise à jour du reporting: ' . $e->getMessage()
            ], 500);
        }
    }


    /**
     * Soumettre un reporting (obsolète - les reportings sont maintenant soumis automatiquement à la création)
     * Gardée pour compatibilité avec l'API existante
     */
    public function submit($id)
    {
        try {
            $user = request()->user();
            $reporting = Reporting::findOrFail($id);
            
            // Vérifier les permissions
            if ($reporting->user_id !== $user->id) {
                return response()->json([
                    'success' => false,
                    'message' => 'Accès refusé à ce reporting'
                ], 403);
            }
            
            // Si le reporting est déjà soumis, retourner un message informatif
            if ($reporting->status === 'submitted') {
                return response()->json([
                    'success' => true,
                    'data' => $reporting->load(['user', 'approver']),
                    'message' => 'Ce reporting est déjà soumis (les reportings sont soumis automatiquement lors de leur création)'
                ]);
            }
            
            // Si c'est un draft (ancien système), on peut encore le soumettre
            if ($reporting->submit()) {
                return response()->json([
                    'success' => true,
                    'data' => $reporting->load(['user', 'approver']),
                    'message' => 'Reporting soumis avec succès'
                ]);
            } else {
                return response()->json([
                    'success' => false,
                    'message' => 'Impossible de soumettre ce reporting (statut: ' . $reporting->status . ')'
                ], 400);
            }

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de la soumission du reporting: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Approuver un reporting
     */
    public function approve(Request $request, $id)
    {
        try {
            $user = request()->user();
            $reporting = Reporting::findOrFail($id);
            
            // Vérifier les permissions (seuls les admins et patrons peuvent approuver)
            if (!in_array($user->role, [1, 6])) {
                return response()->json([
                    'success' => false,
                    'message' => 'Accès refusé pour approuver ce reporting'
                ], 403);
            }
            
            $request->validate([
                'comments' => 'nullable|string'
            ]);
            
            if ($reporting->approve($user->id, $request->comments)) {
                return response()->json([
                    'success' => true,
                    'data' => $reporting->load(['user', 'approver']),
                    'message' => 'Reporting approuvé avec succès'
                ]);
            } else {
                return response()->json([
                    'success' => false,
                    'message' => 'Impossible d\'approuver ce reporting'
                ], 400);
            }

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de l\'approbation du reporting: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Ajouter ou modifier la note du patron sur un rapport
     */
    public function addPatronNote(Request $request, $id)
    {
        try {
            $user = $request->user();
            
            // Vérifier les permissions (Patron ou Admin uniquement)
            if (!in_array($user->role, [1, 6])) {
                return response()->json([
                    'success' => false,
                    'message' => 'Accès non autorisé'
                ], 403);
            }

            // Valider les données
            $request->validate([
                'patron_note' => 'nullable|string|max:1000'
            ]);

            // Récupérer le rapport
            $reporting = Reporting::findOrFail($id);

            // Vérifier que le rapport est en attente de validation
            if ($reporting->status !== 'submitted') {
                return response()->json([
                    'success' => false,
                    'message' => 'La note ne peut être ajoutée que sur les rapports en attente de validation'
                ], 422);
            }

            // Mettre à jour la note (null ou chaîne vide supprime la note)
            $patronNote = $request->input('patron_note');
            if ($patronNote === '' || $patronNote === null) {
                $reporting->patron_note = null;
            } else {
                $reporting->patron_note = $patronNote;
            }
            $reporting->save();

            // Recharger avec les relations
            $reporting->refresh();
            $reporting->load(['user', 'approver']);

            return response()->json([
                'success' => true,
                'message' => 'Note enregistrée avec succès',
                'data' => [
                    'id' => $reporting->id,
                    'user_id' => $reporting->user_id,
                    'user_name' => $reporting->user_name,
                    'user_role' => $reporting->user_role,
                    'report_date' => $reporting->report_date?->format('Y-m-d\TH:i:s\Z'),
                    'status' => $reporting->status,
                    'patron_note' => $reporting->patron_note,
                    'updated_at' => $reporting->updated_at->format('Y-m-d\TH:i:s\Z')
                ]
            ], 200);

        } catch (\Illuminate\Database\Eloquent\ModelNotFoundException $e) {
            return response()->json([
                'success' => false,
                'message' => 'Rapport non trouvé'
            ], 404);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de l\'enregistrement de la note: ' . $e->getMessage()
            ], 500);
        }
    }
}
