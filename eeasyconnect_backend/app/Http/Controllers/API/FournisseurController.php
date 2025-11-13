<?php

namespace App\Http\Controllers\API;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;
use App\Models\Fournisseur;
use App\Models\BonDeCommande;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Validator;

class FournisseurController extends Controller
{
    /**
     * Liste des fournisseurs
     * Accessible par tous les utilisateurs authentifiés
     */
    public function index(Request $request): JsonResponse
    {
        try {
            Log::info('API: Récupération des fournisseurs', [
                'user_id' => auth()->id(),
                'filters' => $request->all()
            ]);

            $query = Fournisseur::query();

            // Filtrage par statut
            if ($request->has('statut') && $request->statut !== 'all') {
                $query->where('statut', $request->statut);
            }

            // Recherche
            if ($request->has('search') && !empty($request->search)) {
                $query->where(function($q) use ($request) {
                    $q->where('nom', 'like', '%' . $request->search . '%')
                      ->orWhere('email', 'like', '%' . $request->search . '%');
                });
            }

            // Tri
            $sortBy = $request->get('sort_by', 'created_at');
            $sortOrder = $request->get('sort_order', 'desc');
            $query->orderBy($sortBy, $sortOrder);

            // Pagination
            $perPage = $request->get('per_page', 15);
            $suppliers = $query->paginate($perPage);

            return response()->json([
                'success' => true,
                'message' => 'Fournisseurs récupérés avec succès',
                'data' => $suppliers->items(),
                'pagination' => [
                    'current_page' => $suppliers->currentPage(),
                    'last_page' => $suppliers->lastPage(),
                    'per_page' => $suppliers->perPage(),
                    'total' => $suppliers->total(),
                    'from' => $suppliers->firstItem(),
                    'to' => $suppliers->lastItem(),
                ]
            ]);

        } catch (\Exception $e) {
            Log::error('API: Erreur lors de la récupération des fournisseurs', [
                'error' => $e->getMessage(),
                'user_id' => auth()->id()
            ]);

            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de la récupération des fournisseurs',
                'error' => $e->getMessage()
            ], 500);
        }
    }

    /**
     * Afficher un fournisseur spécifique
     */
    public function show($id): JsonResponse
    {
        try {
            $fournisseur = Fournisseur::findOrFail($id);
            
            Log::info('API: Récupération du fournisseur', [
                'fournisseur_id' => $fournisseur->id,
                'user_id' => auth()->id()
            ]);

            return response()->json([
                'success' => true,
                'message' => 'Fournisseur récupéré avec succès',
                'data' => $fournisseur
            ]);

        } catch (\Exception $e) {
            Log::error('API: Erreur lors de la récupération du fournisseur', [
                'fournisseur_id' => $id,
                'error' => $e->getMessage(),
                'user_id' => auth()->id()
            ]);

            return response()->json([
                'success' => false,
                'message' => 'Fournisseur non trouvé',
                'error' => $e->getMessage()
            ], 404);
        }
    }

    /**
     * Créer un nouveau fournisseur
     */
    public function store(Request $request): JsonResponse
    {
        // Normaliser les champs camelCase vers snake_case (compatibilité Flutter)
        $data = $request->all();
        
        $normalized = [
            'nom' => $data['nom'] ?? $data['name'] ?? null,
            'email' => $data['email'] ?? null,
            'telephone' => $data['telephone'] ?? $data['phone'] ?? null,
            'adresse' => $data['adresse'] ?? $data['address'] ?? null,
            'ville' => $data['ville'] ?? $data['city'] ?? null,
            'pays' => $data['pays'] ?? $data['country'] ?? null,
            'description' => $data['description'] ?? null,
            'note_evaluation' => $data['noteEvaluation'] ?? $data['note_evaluation'] ?? null,
            'commentaires' => $data['commentaires'] ?? $data['comments'] ?? null,
        ];
        
        $request->merge($normalized);

        // Validation
        $validator = \Validator::make($request->all(), [
            'nom' => 'required|string|max:255',
            'email' => 'required|email|unique:fournisseurs,email',
            'telephone' => 'required|string|max:20',
            'adresse' => 'required|string|max:500',
            'ville' => 'required|string|max:100',
            'pays' => 'required|string|max:100',
            'description' => 'nullable|string|max:1000',
            'statut' => 'nullable|in:pending,approved,rejected,active,inactive',
            'note_evaluation' => 'nullable|numeric|min:0|max:5',
            'commentaires' => 'nullable|string|max:1000',
        ], [
            'nom.required' => 'Le nom du fournisseur est obligatoire.',
            'nom.max' => 'Le nom ne peut pas dépasser 255 caractères.',
            'email.required' => 'L\'email est obligatoire.',
            'email.email' => 'L\'email doit être valide.',
            'email.unique' => 'Cet email est déjà utilisé par un autre fournisseur.',
            'telephone.required' => 'Le téléphone est obligatoire.',
            'telephone.max' => 'Le téléphone ne peut pas dépasser 20 caractères.',
            'adresse.required' => 'L\'adresse est obligatoire.',
            'adresse.max' => 'L\'adresse ne peut pas dépasser 500 caractères.',
            'ville.required' => 'La ville est obligatoire.',
            'ville.max' => 'La ville ne peut pas dépasser 100 caractères.',
            'pays.required' => 'Le pays est obligatoire.',
            'pays.max' => 'Le pays ne peut pas dépasser 100 caractères.',
            'description.max' => 'La description ne peut pas dépasser 1000 caractères.',
            'statut.in' => 'Le statut doit être l\'un des suivants: pending, approved, rejected, active, inactive.',
            'note_evaluation.numeric' => 'La note d\'évaluation doit être un nombre.',
            'note_evaluation.min' => 'La note d\'évaluation doit être au minimum 0.',
            'note_evaluation.max' => 'La note d\'évaluation doit être au maximum 5.',
            'commentaires.max' => 'Les commentaires ne peuvent pas dépasser 1000 caractères.',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Erreurs de validation',
                'errors' => $validator->errors()
            ], 422);
        }

        try {
            Log::info('API: Création d\'un nouveau fournisseur', [
                'user_id' => auth()->id(),
                'data' => $request->all()
            ]);

            DB::beginTransaction();

            $validated = $validator->validated();
            $fournisseur = Fournisseur::create([
                'nom' => $validated['nom'],
                'email' => $validated['email'],
                'telephone' => $validated['telephone'],
                'adresse' => $validated['adresse'],
                'ville' => $validated['ville'],
                'pays' => $validated['pays'],
                'description' => $validated['description'] ?? null,
                'status' => 'en_attente',
                'note_evaluation' => $validated['note_evaluation'] ?? null,
                'commentaires' => $validated['commentaires'] ?? null,
                'created_by' => auth()->id(),
                'updated_by' => auth()->id(),
            ]);

            DB::commit();

            Log::info('API: Fournisseur créé avec succès', [
                'fournisseur_id' => $fournisseur->id,
                'user_id' => auth()->id()
            ]);

            return response()->json([
                'success' => true,
                'message' => 'Fournisseur créé avec succès',
                'data' => $fournisseur
            ], 201);

        } catch (\Exception $e) {
            DB::rollBack();
            
            Log::error('API: Erreur lors de la création du fournisseur', [
                'error' => $e->getMessage(),
                'user_id' => auth()->id()
            ]);

            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de la création du fournisseur',
                'error' => $e->getMessage()
            ], 500);
        }
    }

    /**
     * Mettre à jour un fournisseur
     */
    public function update(Request $request, Supplier $supplier): JsonResponse
    {
        // Validation
        $validator = Validator::make($request->all(), [
            'nom' => 'sometimes|required|string|max:255',
            'email' => 'sometimes|required|email|unique:suppliers,email,' . $supplier->id,
            'telephone' => 'sometimes|required|string|max:20',
            'adresse' => 'sometimes|required|string|max:500',
            'ville' => 'sometimes|required|string|max:100',
            'pays' => 'sometimes|required|string|max:100',
            'description' => 'nullable|string|max:1000',
            'statut' => 'nullable|in:pending,approved,rejected,active,inactive',
            'note_evaluation' => 'nullable|numeric|min:0|max:5',
            'commentaires' => 'nullable|string|max:1000',
        ], [
            'nom.required' => 'Le nom du fournisseur est obligatoire.',
            'nom.max' => 'Le nom ne peut pas dépasser 255 caractères.',
            'email.required' => 'L\'email est obligatoire.',
            'email.email' => 'L\'email doit être valide.',
            'email.unique' => 'Cet email est déjà utilisé par un autre fournisseur.',
            'telephone.required' => 'Le téléphone est obligatoire.',
            'telephone.max' => 'Le téléphone ne peut pas dépasser 20 caractères.',
            'adresse.required' => 'L\'adresse est obligatoire.',
            'adresse.max' => 'L\'adresse ne peut pas dépasser 500 caractères.',
            'ville.required' => 'La ville est obligatoire.',
            'ville.max' => 'La ville ne peut pas dépasser 100 caractères.',
            'pays.required' => 'Le pays est obligatoire.',
            'pays.max' => 'Le pays ne peut pas dépasser 100 caractères.',
            'description.max' => 'La description ne peut pas dépasser 1000 caractères.',
            'statut.in' => 'Le statut doit être l\'un des suivants: pending, approved, rejected, active, inactive.',
            'note_evaluation.numeric' => 'La note d\'évaluation doit être un nombre.',
            'note_evaluation.min' => 'La note d\'évaluation doit être au minimum 0.',
            'note_evaluation.max' => 'La note d\'évaluation doit être au maximum 5.',
            'commentaires.max' => 'Les commentaires ne peuvent pas dépasser 1000 caractères.',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Erreurs de validation',
                'errors' => $validator->errors()
            ], 422);
        }

        try {
            Log::info('API: Mise à jour du fournisseur', [
                'supplier_id' => $supplier->id,
                'user_id' => auth()->id(),
                'data' => $request->all()
            ]);

            DB::beginTransaction();

            $supplier->update([
                ...$request->all(),
                'updated_by' => auth()->id(),
            ]);

            DB::commit();

            Log::info('API: Fournisseur mis à jour avec succès', [
                'supplier_id' => $supplier->id,
                'user_id' => auth()->id()
            ]);

            return response()->json([
                'success' => true,
                'message' => 'Fournisseur mis à jour avec succès',
                'data' => new SupplierResource($supplier->fresh())
            ]);

        } catch (\Exception $e) {
            DB::rollBack();
            
            Log::error('API: Erreur lors de la mise à jour du fournisseur', [
                'supplier_id' => $supplier->id,
                'error' => $e->getMessage(),
                'user_id' => auth()->id()
            ]);

            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de la mise à jour du fournisseur',
                'error' => $e->getMessage()
            ], 500);
        }
    }

    /**
     * Supprimer un fournisseur
     */
    public function destroy(Supplier $supplier): JsonResponse
    {
        try {
            Log::info('API: Suppression du fournisseur', [
                'supplier_id' => $supplier->id,
                'user_id' => auth()->id()
            ]);

            $supplier->delete();

            Log::info('API: Fournisseur supprimé avec succès', [
                'supplier_id' => $supplier->id,
                'user_id' => auth()->id()
            ]);

            return response()->json([
                'success' => true,
                'message' => 'Fournisseur supprimé avec succès'
            ]);

        } catch (\Exception $e) {
            Log::error('API: Erreur lors de la suppression du fournisseur', [
                'supplier_id' => $supplier->id,
                'error' => $e->getMessage(),
                'user_id' => auth()->id()
            ]);

            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de la suppression du fournisseur',
                'error' => $e->getMessage()
            ], 500);
        }
    }

    /**
     * Approuver un fournisseur
     */
    public function approve(Request $request, Supplier $supplier): JsonResponse
    {
        // Validation
        $validator = Validator::make($request->all(), [
            'comments' => 'nullable|string|max:1000',
        ], [
            'comments.max' => 'Les commentaires ne peuvent pas dépasser 1000 caractères.',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Erreurs de validation',
                'errors' => $validator->errors()
            ], 422);
        }

        try {
            Log::info('API: Approbation du fournisseur', [
                'supplier_id' => $supplier->id,
                'user_id' => auth()->id(),
                'comments' => $request->comments
            ]);

            DB::beginTransaction();

            $supplier->approve($request->comments);

            DB::commit();

            Log::info('API: Fournisseur approuvé avec succès', [
                'supplier_id' => $supplier->id,
                'user_id' => auth()->id()
            ]);

            return response()->json([
                'success' => true,
                'message' => 'Fournisseur approuvé avec succès',
                'data' => new SupplierResource($supplier->fresh())
            ]);

        } catch (\Exception $e) {
            DB::rollBack();
            
            Log::error('API: Erreur lors de l\'approbation du fournisseur', [
                'supplier_id' => $supplier->id,
                'error' => $e->getMessage(),
                'user_id' => auth()->id()
            ]);

            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de l\'approbation du fournisseur',
                'error' => $e->getMessage()
            ], 500);
        }
    }

    /**
     * Rejeter un fournisseur
     */
    public function reject(Request $request, Supplier $supplier): JsonResponse
    {
        // Validation
        $validator = Validator::make($request->all(), [
            'reason' => 'required|string|max:1000',
        ], [
            'reason.required' => 'Le motif du rejet est obligatoire.',
            'reason.max' => 'Le motif du rejet ne peut pas dépasser 1000 caractères.',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Erreurs de validation',
                'errors' => $validator->errors()
            ], 422);
        }

        try {
            Log::info('API: Rejet du fournisseur', [
                'supplier_id' => $supplier->id,
                'user_id' => auth()->id(),
                'reason' => $request->reason
            ]);

            DB::beginTransaction();

            $supplier->reject($request->reason);

            DB::commit();

            Log::info('API: Fournisseur rejeté avec succès', [
                'supplier_id' => $supplier->id,
                'user_id' => auth()->id()
            ]);

            return response()->json([
                'success' => true,
                'message' => 'Fournisseur rejeté avec succès',
                'data' => new SupplierResource($supplier->fresh())
            ]);

        } catch (\Exception $e) {
            DB::rollBack();
            
            Log::error('API: Erreur lors du rejet du fournisseur', [
                'supplier_id' => $supplier->id,
                'error' => $e->getMessage(),
                'user_id' => auth()->id()
            ]);

            return response()->json([
                'success' => false,
                'message' => 'Erreur lors du rejet du fournisseur',
                'error' => $e->getMessage()
            ], 500);
        }
    }

    /**
     * Évaluer un fournisseur
     */
    public function rate(Request $request, Supplier $supplier): JsonResponse
    {
        // Validation
        $validator = Validator::make($request->all(), [
            'rating' => 'required|numeric|min:1|max:5',
            'comments' => 'nullable|string|max:1000',
        ], [
            'rating.required' => 'La note est obligatoire.',
            'rating.numeric' => 'La note doit être un nombre.',
            'rating.min' => 'La note doit être au minimum 1.',
            'rating.max' => 'La note doit être au maximum 5.',
            'comments.max' => 'Les commentaires ne peuvent pas dépasser 1000 caractères.',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Erreurs de validation',
                'errors' => $validator->errors()
            ], 422);
        }

        try {
            Log::info('API: Évaluation du fournisseur', [
                'supplier_id' => $supplier->id,
                'user_id' => auth()->id(),
                'rating' => $request->rating,
                'comments' => $request->comments
            ]);

            DB::beginTransaction();

            $supplier->rate($request->rating, $request->comments);

            DB::commit();

            Log::info('API: Fournisseur évalué avec succès', [
                'supplier_id' => $supplier->id,
                'user_id' => auth()->id()
            ]);

            return response()->json([
                'success' => true,
                'message' => 'Fournisseur évalué avec succès',
                'data' => new SupplierResource($supplier->fresh())
            ]);

        } catch (\Exception $e) {
            DB::rollBack();
            
            Log::error('API: Erreur lors de l\'évaluation du fournisseur', [
                'supplier_id' => $supplier->id,
                'error' => $e->getMessage(),
                'user_id' => auth()->id()
            ]);

            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de l\'évaluation du fournisseur',
                'error' => $e->getMessage()
            ], 500);
        }
    }

    /**
     * Récupérer les statistiques des fournisseurs
     */
    public function stats(): JsonResponse
    {
        try {
            Log::info('API: Récupération des statistiques des fournisseurs', [
                'user_id' => auth()->id()
            ]);

            $stats = [
                'total' => Supplier::count(),
                'pending' => Supplier::pending()->count(),
                'approved' => Supplier::approved()->count(),
                'rejected' => Supplier::rejected()->count(),
                'active' => Supplier::active()->count(),
                'inactive' => Supplier::inactive()->count(),
                'average_rating' => Supplier::whereNotNull('note_evaluation')
                    ->avg('note_evaluation') ?? 0,
            ];

            return response()->json([
                'success' => true,
                'message' => 'Statistiques récupérées avec succès',
                'data' => $stats
            ]);

        } catch (\Exception $e) {
            Log::error('API: Erreur lors de la récupération des statistiques', [
                'error' => $e->getMessage(),
                'user_id' => auth()->id()
            ]);

            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de la récupération des statistiques',
                'error' => $e->getMessage()
            ], 500);
        }
    }

    /**
     * Récupérer les fournisseurs en attente
     */
    public function pending(): JsonResponse
    {
        try {
            Log::info('API: Récupération des fournisseurs en attente', [
                'user_id' => auth()->id()
            ]);

            $suppliers = Supplier::pending()
                ->orderBy('created_at', 'desc')
                ->get();

            return response()->json([
                'success' => true,
                'message' => 'Fournisseurs en attente récupérés avec succès',
                'data' => SupplierResource::collection($suppliers)
            ]);

        } catch (\Exception $e) {
            Log::error('API: Erreur lors de la récupération des fournisseurs en attente', [
                'error' => $e->getMessage(),
                'user_id' => auth()->id()
            ]);

            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de la récupération des fournisseurs en attente',
                'error' => $e->getMessage()
            ], 500);
        }
    }
}