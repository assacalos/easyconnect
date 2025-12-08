<?php

namespace App\Http\Controllers\API;

use App\Http\Controllers\API\Controller;
use App\Traits\SendsNotifications;
use App\Models\Bordereau;
use App\Models\BordereauItem;
use App\Models\User;
use App\Http\Resources\BordereauResource;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\DB;

class BordereauController extends Controller
{
    use SendsNotifications;
    // Récupérer tous les bordereaux (avec filtre status facultatif)
    public function index(Request $request)
    {
        try {
            $user = $request->user();
            
            if (!$user) {
                return response()->json([
                    'success' => false,
                    'message' => 'Utilisateur non authentifié'
                ], 401);
            }
            
            $status = $request->query('status'); // facultatif
            $query = Bordereau::with('items', 'client', 'user', 'devis');

            if ($status !== null) {
                $query->where('status', $status);
            }
            
            // Filtres de date
            if ($request->has('start_date')) {
                $query->whereDate('date_creation', '>=', $request->start_date);
            }
            if ($request->has('end_date')) {
                $query->whereDate('date_creation', '<=', $request->end_date);
            }

            $perPage = min($request->get('per_page', 15), 100); // Limite max 100 par page
            $bordereaux = $query->orderBy('created_at', 'desc')->paginate($perPage);
            
            return response()->json([
                'success' => true,
                'data' => BordereauResource::collection($bordereaux->items()),
                'pagination' => [
                    'current_page' => $bordereaux->currentPage(),
                    'last_page' => $bordereaux->lastPage(),
                    'per_page' => $bordereaux->perPage(),
                    'total' => $bordereaux->total(),
                ],
                'message' => 'Liste des bordereaux récupérée avec succès'
            ], 200);
            
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de la récupération des bordereaux: ' . $e->getMessage()
            ], 500);
        }
    }

    // Créer un bordereau (toujours status=1 : soumis)
    public function store(Request $request)
    {
        DB::beginTransaction();
        
        try {
            $validated = $request->validate([
                'reference' => 'required|unique:bordereaus,reference',
                'client_id' => 'required|exists:clients,id',
                'devis_id' => 'nullable|exists:devis,id',
                'user_id' => 'required|exists:users,id',
                'date_creation' => 'required|date',
                'items' => 'required|array|min:1',
                'items.*.designation' => 'required|string',
                'items.*.quantite' => 'required|integer|min:1',
            ]);

            $bordereau = Bordereau::create([
                'reference' => $validated['reference'],
                'client_id' => $validated['client_id'],
                'devis_id' => $validated['devis_id'] ?? null,
                'user_id' => $validated['user_id'],
                'date_creation' => $validated['date_creation'],
                'notes' => $request->notes ?? null,
                'status' => 1, // soumis au patron
            ]);

            foreach ($validated['items'] as $item) {
                BordereauItem::create([
                    'bordereau_id' => $bordereau->id,
                    'designation' => $item['designation'],
                    'quantite' => $item['quantite'],
                    'description' => $item['description'] ?? null,
                ]);
            }
            
            DB::commit();

            // Charger les relations avec gestion d'erreur
            try {
                $bordereau->load('items', 'client', 'user');
                
                // Charger devis seulement s'il existe
                if ($bordereau->devis_id) {
                    $bordereau->load('devis');
                }
            } catch (\Exception $e) {
                Log::warning('Failed to load bordereau relations', [
                    'bordereau_id' => $bordereau->id,
                    'error' => $e->getMessage()
                ]);
                // Continuer même si les relations ne peuvent pas être chargées
            }

            // Notifier le patron lors de la création (status=1 = soumis)
            try {
                $this->notifyApproverOnSubmission($bordereau, 'bordereau', 'Bordereau', 6, $bordereau->reference);
            } catch (\Exception $e) {
                Log::warning('Failed to create notification for bordereau', [
                    'bordereau_id' => $bordereau->id,
                    'error' => $e->getMessage()
                ]);
                // Ne pas faire échouer la création si la notification échoue
            }

            // Recharger le bordereau pour s'assurer d'avoir toutes les données
            $bordereau->refresh();
            
            return response()->json([
                'success' => true,
                'data' => new BordereauResource($bordereau),
                'message' => 'Bordereau créé avec succès'
            ], 201);
            
        } catch (\Illuminate\Validation\ValidationException $e) {
            DB::rollBack();
            return response()->json([
                'success' => false,
                'message' => 'Erreur de validation',
                'errors' => $e->errors()
            ], 422);
        } catch (\Exception $e) {
            DB::rollBack();
            
            Log::error('Bordereau store error', [
                'message' => $e->getMessage(),
                'trace' => $e->getTraceAsString(),
                'file' => $e->getFile(),
                'line' => $e->getLine(),
                'request_data' => $request->except(['password', 'token']),
            ]);
            
            $errorMessage = 'Erreur lors de la création du bordereau';
            $errorDetails = null;
            
            if (config('app.debug')) {
                $errorDetails = [
                    'message' => $e->getMessage(),
                    'file' => $e->getFile(),
                    'line' => $e->getLine(),
                ];
                $errorMessage = $e->getMessage();
            }
            
            return response()->json([
                'success' => false,
                'message' => $errorMessage,
                'error' => $errorDetails
            ], 500);
        }
    }

    // Récupérer un bordereau
    public function show($id)
    {
        $bordereau = Bordereau::with('items', 'client', 'user', 'devis')->findOrFail($id);
        return response()->json([
            'success' => true,
            'data' => new BordereauResource($bordereau)
        ]);
    }

    // Mettre à jour un bordereau (modification tant que status != 2)
    public function update(Request $request, $id)
    {
        $bordereau = Bordereau::findOrFail($id);

        if ($bordereau->status == 2) { // validé
            return response()->json(['message' => 'Impossible de modifier un bordereau validé'], 403);
        }

        $bordereau->update($request->only([
            'notes', 'status', 'commentaire'
        ]));

        // Mise à jour des items si fournis
        if ($request->has('items')) {
            $bordereau->items()->delete(); // supprimer anciens items
            foreach ($request->items as $item) {
                BordereauItem::create([
                    'bordereau_id' => $bordereau->id,
                    'designation' => $item['designation'],
                    'quantite' => $item['quantite'],
                    'description' => $item['description'] ?? null,
                ]);
            }
        }

        return response()->json([
            'success' => true,
            'data' => new BordereauResource($bordereau->load('items', 'client', 'user', 'devis'))
        ]);
    }

    // Supprimer un bordereau (seulement si status != 2)
    public function destroy($id)
    {
        $bordereau = Bordereau::findOrFail($id);

        if ($bordereau->status == 2) {
            return response()->json(['message' => 'Impossible de supprimer un bordereau validé'], 403);
        }

        $bordereau->delete();
        return response()->json(['message' => 'Bordereau supprimé']);
    }

    // ✅ NOUVELLE MÉTHODE : Valider un bordereau
    public function validateBordereau(Request $request, $id)
    {
        try {
            $bordereau = Bordereau::findOrFail($id);
            
            // Vérifier que le bordereau est soumis (status = 1)
            if ($bordereau->status != 1) {
                return response()->json([
                    'success' => false,
                    'message' => 'Seuls les bordereaux soumis peuvent être validés'
                ], 403);
            }

            $bordereau->update([
                'status' => 2, // validé
                'date_validation' => now()->toDateString(),
                'commentaire' => null // effacer tout commentaire de rejet
            ]);

            // Notifier l'auteur du bordereau
            $this->notifySubmitterOnApproval($bordereau, 'bordereau', 'Bordereau', 'user_id', $bordereau->reference);

            // Recharger le bordereau avec ses relations
            $bordereau->refresh();
            $bordereau->load(['items', 'client', 'user']);
            
            // Charger devis seulement s'il existe
            if ($bordereau->devis_id) {
                $bordereau->load('devis');
            }

            return response()->json([
                'success' => true,
                'message' => 'Bordereau validé avec succès',
                'data' => new BordereauResource($bordereau)
            ], 200);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de la validation: ' . $e->getMessage()
            ], 500);
        }
    }

    // ✅ NOUVELLE MÉTHODE : Rejeter un bordereau
    public function reject(Request $request, $id)
    {
        try {
            $bordereau = Bordereau::findOrFail($id);
            
            // Vérifier que le bordereau est soumis (status = 1)
            if ($bordereau->status != 1) {
                return response()->json([
                    'success' => false,
                    'message' => 'Seuls les bordereaux soumis peuvent être rejetés'
                ], 403);
            }

            $validator = Validator::make($request->all(), [
                'commentaire' => 'required|string|max:1000'
            ]);

            if ($validator->fails()) {
                return response()->json([
                    'success' => false,
                    'errors' => $validator->errors()
                ], 422);
            }

            $bordereau->update([
                'status' => 3, // rejeté
                'commentaire' => $request->commentaire
            ]);

            // Notifier l'auteur du bordereau
            $this->notifySubmitterOnRejection($bordereau, 'bordereau', 'Bordereau', $request->commentaire, 'user_id', $bordereau->reference);

            return response()->json([
                'success' => true,
                'message' => 'Bordereau rejeté avec succès',
                'data' => new BordereauResource($bordereau->load(['items', 'client', 'user', 'devis']))
            ], 200);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors du rejet: ' . $e->getMessage()
            ], 500);
        }
    }
    
    /**
     * Compteur de bordereaux avec filtres
     */
    public function count(Request $request)
    {
        try {
            $user = $request->user();
            
            if (!$user) {
                return response()->json([
                    'success' => false,
                    'message' => 'Utilisateur non authentifié'
                ], 401);
            }
            
            $validated = $request->validate([
                'status' => 'nullable|integer',
                'start_date' => 'nullable|date',
                'end_date' => 'nullable|date|after_or_equal:start_date',
                'user_id' => 'nullable|integer|exists:users,id',
            ]);
            
            $query = Bordereau::query();
            
            // Filtre par statut
            if (isset($validated['status'])) {
                $query->where('status', $validated['status']);
            }
            
            // Filtres de date
            if (isset($validated['start_date'])) {
                $query->whereDate('date_creation', '>=', $validated['start_date']);
            }
            if (isset($validated['end_date'])) {
                $query->whereDate('date_creation', '<=', $validated['end_date']);
            }
            
            // Filtre par user_id
            if (isset($validated['user_id'])) {
                $query->where('user_id', $validated['user_id']);
            }
            
            return response()->json([
                'success' => true,
                'count' => $query->count(),
            ], 200);
            
        } catch (\Exception $e) {
            Log::error('BordereauController::count - Erreur', [
                'message' => $e->getMessage(),
            ]);
            
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors du comptage: ' . $e->getMessage(),
            ], 500);
        }
    }
    
    /**
     * Statistiques agrégées des bordereaux
     */
    public function stats(Request $request)
    {
        try {
            $user = $request->user();
            
            if (!$user) {
                return response()->json([
                    'success' => false,
                    'message' => 'Utilisateur non authentifié'
                ], 401);
            }
            
            $validated = $request->validate([
                'status' => 'nullable|integer',
                'start_date' => 'nullable|date',
                'end_date' => 'nullable|date|after_or_equal:start_date',
                'user_id' => 'nullable|integer|exists:users,id',
            ]);
            
            $query = Bordereau::query();
            
            // Filtres de date
            if (isset($validated['start_date'])) {
                $query->whereDate('date_creation', '>=', $validated['start_date']);
            }
            if (isset($validated['end_date'])) {
                $query->whereDate('date_creation', '<=', $validated['end_date']);
            }
            
            // Filtre par statut
            if (isset($validated['status'])) {
                $query->where('status', $validated['status']);
            }
            
            // Filtre par user_id
            if (isset($validated['user_id'])) {
                $query->where('user_id', $validated['user_id']);
            }
            
            $count = $query->count();
            
            // Statistiques par statut
            $byStatus = Bordereau::selectRaw('status, count(*) as count')
                ->when(isset($validated['start_date']), function($q) use ($validated) {
                    $q->whereDate('date_creation', '>=', $validated['start_date']);
                })
                ->when(isset($validated['end_date']), function($q) use ($validated) {
                    $q->whereDate('date_creation', '<=', $validated['end_date']);
                })
                ->when(isset($validated['user_id']), function($q) use ($validated) {
                    $q->where('user_id', $validated['user_id']);
                })
                ->groupBy('status')
                ->get()
                ->pluck('count', 'status');
            
            return response()->json([
                'success' => true,
                'data' => [
                    'count' => $count,
                    'by_status' => $byStatus,
                ],
            ], 200);
            
        } catch (\Exception $e) {
            Log::error('BordereauController::stats - Erreur', [
                'message' => $e->getMessage(),
            ]);
            
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de la récupération des statistiques: ' . $e->getMessage(),
            ], 500);
        }
    }
}
