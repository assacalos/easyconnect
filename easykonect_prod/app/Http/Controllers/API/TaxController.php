<?php

namespace App\Http\Controllers\API;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;
use App\Models\Tax;
use Illuminate\Support\Facades\Log;

class TaxController extends Controller
{
    /**
     * Liste des taxes avec filtrage par statut
     */
    public function index(Request $request): JsonResponse
    {
        try {
            Log::info('API: Récupération des taxes', [
                'user_id' => auth()->id(),
                'filters' => $request->all()
            ]);

            $query = Tax::with(['taxCategory', 'comptable', 'validatedBy', 'rejectedBy']);

            // Filtrage par statut (pour les onglets)
            if ($request->has('status') && $request->status !== 'all') {
                $query->where('status', $request->status);
            }

            // Recherche
            if ($request->has('search') && !empty($request->search)) {
                $query->where(function($q) use ($request) {
                    $q->where('reference', 'like', '%' . $request->search . '%')
                      ->orWhere('period', 'like', '%' . $request->search . '%')
                      ->orWhere('description', 'like', '%' . $request->search . '%');
                });
            }

            // Tri
            $sortBy = $request->get('sort_by', 'created_at');
            $sortOrder = $request->get('sort_order', 'desc');
            $query->orderBy($sortBy, $sortOrder);

            // Pagination
            $perPage = $request->get('per_page', 15);
            $taxes = $query->paginate($perPage);

            // Statistiques pour les onglets
            $stats = [
                'en_attente' => Tax::where('status', 'en_attente')->count(),
                'valide' => Tax::where('status', 'valide')->count(),
                'rejete' => Tax::where('status', 'rejete')->count(),
                'total' => Tax::count()
            ];

            return response()->json([
                'success' => true,
                'message' => 'Taxes récupérées avec succès',
                'data' => $taxes->items(),
                'pagination' => [
                    'current_page' => $taxes->currentPage(),
                    'last_page' => $taxes->lastPage(),
                    'per_page' => $taxes->perPage(),
                    'total' => $taxes->total(),
                    'from' => $taxes->firstItem(),
                    'to' => $taxes->lastItem(),
                ],
                'stats' => $stats
            ]);

        } catch (\Exception $e) {
            Log::error('Erreur lors de la récupération des taxes', [
                'error' => $e->getMessage(),
                'user_id' => auth()->id()
            ]);

            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de la récupération des taxes',
                'error' => $e->getMessage()
            ], 500);
        }
    }

    /**
     * Valider une taxe
     */
public function validateTax(Request $request, $id): JsonResponse
    {
        try {
            $tax = Tax::findOrFail($id);
            
            if ($tax->status !== 'en_attente') {
                return response()->json([
                    'success' => false,
                    'message' => 'Cette taxe ne peut pas être validée dans son état actuel'
                ], 400);
            }

            $request->validate([
                'validation_comment' => 'nullable|string|max:1000'
            ]);

            $tax->update([
                'status' => 'valide',
                'validated_by' => auth()->id(),
                'validated_at' => now(),
                'validation_comment' => $request->validation_comment
            ]);

            Log::info('Taxe validée', [
                'tax_id' => $tax->id,
                'validated_by' => auth()->id()
            ]);

            return response()->json([
                'success' => true,
                'message' => 'Taxe validée avec succès',
                'tax' => $tax->load(['validatedBy'])
            ]);

        } catch (\Exception $e) {
            Log::error('Erreur lors de la validation de la taxe', [
                'error' => $e->getMessage(),
                'tax_id' => $id,
                'user_id' => auth()->id()
            ]);

            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de la validation de la taxe',
                'error' => $e->getMessage()
            ], 500);
        }
    }

    /**
     * Rejeter une taxe
     */
    public function reject(Request $request, $id): JsonResponse
    {
        try {
            $tax = Tax::findOrFail($id);
            
            if ($tax->status !== 'en_attente') {
                return response()->json([
                    'success' => false,
                    'message' => 'Cette taxe ne peut pas être rejetée dans son état actuel'
                ], 400);
            }

            $request->validate([
                'rejection_reason' => 'required|string|max:255',
                'rejection_comment' => 'required|string|max:1000'
            ]);

            $tax->update([
                'status' => 'rejete',
                'rejected_by' => auth()->id(),
                'rejected_at' => now(),
                'rejection_reason' => $request->rejection_reason,
                'rejection_comment' => $request->rejection_comment
            ]);

            Log::info('Taxe rejetée', [
                'tax_id' => $tax->id,
                'rejected_by' => auth()->id(),
                'reason' => $request->rejection_reason
            ]);

            return response()->json([
                'success' => true,
                'message' => 'Taxe rejetée avec succès',
                'tax' => $tax->load(['rejectedBy'])
            ]);

        } catch (\Exception $e) {
            Log::error('Erreur lors du rejet de la taxe', [
                'error' => $e->getMessage(),
                'tax_id' => $id,
                'user_id' => auth()->id()
            ]);

            return response()->json([
                'success' => false,
                'message' => 'Erreur lors du rejet de la taxe',
                'error' => $e->getMessage()
            ], 500);
        }
    }

    /**
     * Statistiques des taxes
     */
    public function statistics(): JsonResponse
    {
        try {
            $stats = [
                'en_attente' => Tax::where('status', 'en_attente')->count(),
                'valide' => Tax::where('status', 'valide')->count(),
                'rejete' => Tax::where('status', 'rejete')->count(),
                'total' => Tax::count(),
                'montant_total_en_attente' => Tax::where('status', 'en_attente')->sum('total_amount'),
                'montant_total_valide' => Tax::where('status', 'valide')->sum('total_amount'),
                'montant_total_rejete' => Tax::where('status', 'rejete')->sum('total_amount')
            ];

            return response()->json([
                'success' => true,
                'statistics' => $stats,
                'message' => 'Statistiques récupérées avec succès'
            ]);

        } catch (\Exception $e) {
            Log::error('Erreur lors de la récupération des statistiques', [
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
}