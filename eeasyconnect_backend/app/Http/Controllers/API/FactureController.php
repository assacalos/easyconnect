<?php

namespace App\Http\Controllers\API;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\Facture;
use App\Models\Client;

class FactureController extends Controller
{
    /**
     * Liste des factures
     * Accessible par tous les utilisateurs authentifiés
     */
    public function index(Request $request)
    {
        $query = Facture::with('client');
        
        // Filtrage par status si fourni
        if ($request->has('status')) {
            $query->where('status', $request->status);
        }
        
        // Filtrage par date si fourni
        if ($request->has('date_debut')) {
            $query->where('date_facture', '>=', $request->date_debut);
        }
        
        if ($request->has('date_fin')) {
            $query->where('date_facture', '<=', $request->date_fin);
        }
        
        // Si commercial → filtre ses propres clients
        if (auth()->user()->isCommercial()) {
            $query->whereHas('client', function($q) {
                $q->where('user_id', auth()->id());
            });
        }
        
        $factures = $query->get();
        
        return response()->json([
            'success' => true,
            'factures' => $factures,
            'message' => 'Liste des factures récupérée avec succès'
        ]);
    }

    /**
     * Détails d'une facture
     * Accessible par tous les utilisateurs authentifiés
     */
    public function show($id)
    {
        $facture = Facture::with('client', 'paiements')->findOrFail($id);
        
        // Vérification des permissions pour les commerciaux
        if (auth()->user()->isCommercial() && $facture->client->user_id !== auth()->id()) {
            return response()->json([
                'success' => false,
                'message' => 'Accès refusé à cette facture'
            ], 403);
        }
        
        return response()->json([
            'success' => true,
            'facture' => $facture,
            'message' => 'Facture récupérée avec succès'
        ]);
    }

    /**
     * Créer une facture
     * Accessible par Comptable et Admin
     */
    public function store(Request $request)
    {
        $request->validate([
            'client_id' => 'required|exists:clients,id',
            'numero_facture' => 'required|string|unique:factures',
            'montant' => 'required|numeric|min:0',
            'date_facture' => 'required|date',
            'description' => 'nullable|string',
            'status' => 'required|in:en_attente,payee,impayee'
        ]);

        $facture = Facture::create([
            'client_id' => $request->client_id,
            'numero_facture' => $request->numero_facture,
            'montant' => $request->montant,
            'date_facture' => $request->date_facture,
            'description' => $request->description,
            'status' => $request->status,
            'user_id' => auth()->id()
        ]);

        return response()->json([
            'success' => true,
            'facture' => $facture,
            'message' => 'Facture créée avec succès'
        ], 201);
    }

    /**
     * Modifier une facture
     * Accessible par Comptable et Admin
     */
    public function update(Request $request, $id)
    {
        $facture = Facture::findOrFail($id);
        
        // Vérification que la facture peut être modifiée
        if ($facture->status === 'payee') {
            return response()->json([
                'success' => false,
                'message' => 'Impossible de modifier une facture payée'
            ], 400);
        }

        $request->validate([
            'numero_facture' => 'required|string|unique:factures,numero_facture,' . $facture->id,
            'montant' => 'required|numeric|min:0',
            'date_facture' => 'required|date',
            'description' => 'nullable|string',
            'status' => 'required|in:en_attente,payee,impayee'
        ]);

        $facture->update($request->all());

        return response()->json([
            'success' => true,
            'facture' => $facture,
            'message' => 'Facture modifiée avec succès'
        ]);
    }

    /**
     * Supprimer une facture
     * Accessible par Admin uniquement
     */
    public function destroy($id)
    {
        $facture = Facture::findOrFail($id);
        
        // Vérification que la facture peut être supprimée
        if ($facture->status === 'payee') {
            return response()->json([
                'success' => false,
                'message' => 'Impossible de supprimer une facture payée'
            ], 400);
        }
        
        $facture->delete();

        return response()->json([
            'success' => true,
            'message' => 'Facture supprimée avec succès'
        ]);
    }

    /**
     * Marquer une facture comme payée
     * Accessible par Comptable et Admin
     */
    public function markAsPaid($id)
    {
        $facture = Facture::findOrFail($id);
        
        if ($facture->status === 'payee') {
            return response()->json([
                'success' => false,
                'message' => 'Cette facture est déjà marquée comme payée'
            ], 400);
        }
        
        $facture->update(['status' => 'payee']);

        return response()->json([
            'success' => true,
            'facture' => $facture,
            'message' => 'Facture marquée comme payée'
        ]);
    }

    /**
     * Valider une facture par le patron
     * Accessible par Patron et Admin uniquement
     */
    public function validateFacture(Request $request, $id)
    {
        $facture = Facture::findOrFail($id);
        
        // Vérification que la facture est en attente de validation
        if ($facture->status !== 'en_attente') {
            return response()->json([
                'success' => false,
                'message' => 'Cette facture ne peut pas être validée dans son état actuel'
            ], 400);
        }
        
        $request->validate([
            'commentaire' => 'nullable|string|max:500'
        ]);
        
        $facture->update([
            'status' => 'validee',
            'validated_by' => auth()->id(),
            'validated_at' => now(),
            'validation_comment' => $request->commentaire
        ]);
        
        // Log de l'action
        \Log::info("Facture {$facture->numero_facture} validée par " . auth()->user()->nom);
        
        return response()->json([
            'success' => true,
            'facture' => $facture->fresh(),
            'message' => 'Facture validée avec succès'
        ]);
    }
    
    /**
     * Rejeter une facture par le patron
     * Accessible par Patron et Admin uniquement
     */
    public function reject(Request $request, $id)
    {
        $facture = Facture::findOrFail($id);
        
        // Vérification que la facture peut être rejetée
        if (!in_array($facture->status, ['en_attente', 'validee'])) {
            return response()->json([
                'success' => false,
                'message' => 'Cette facture ne peut pas être rejetée dans son état actuel'
            ], 400);
        }
        
        $request->validate([
            'raison_rejet' => 'required|string|max:500',
            'commentaire' => 'nullable|string|max:500'
        ]);
        
        $facture->update([
            'status' => 'rejetee',
            'rejected_by' => auth()->id(),
            'rejected_at' => now(),
            'rejection_reason' => $request->raison_rejet,
            'rejection_comment' => $request->commentaire
        ]);
        
        // Log de l'action
        \Log::info("Facture {$facture->numero_facture} rejetée par " . auth()->user()->nom . " - Raison: " . $request->raison_rejet);
        
        return response()->json([
            'success' => true,
            'facture' => $facture->fresh(),
            'message' => 'Facture rejetée avec succès'
        ]);
    }
    
    /**
     * Annuler le rejet d'une facture (remettre en attente)
     * Accessible par Patron et Admin uniquement
     */
    public function cancelRejection(Request $request, $id)
    {
        $facture = Facture::findOrFail($id);
        
        if ($facture->status !== 'rejetee') {
            return response()->json([
                'success' => false,
                'message' => 'Cette facture n\'est pas rejetée'
            ], 400);
        }
        
        $facture->update([
            'status' => 'en_attente',
            'rejected_by' => null,
            'rejected_at' => null,
            'rejection_reason' => null,
            'rejection_comment' => null
        ]);
        
        // Log de l'action
        \Log::info("Rejet de la facture {$facture->numero_facture} annulé par " . auth()->user()->nom);
        
        return response()->json([
            'success' => true,
            'facture' => $facture->fresh(),
            'message' => 'Rejet de la facture annulé avec succès'
        ]);
    }
    
    /**
     * Obtenir l'historique des validations/rejets d'une facture
     * Accessible par Patron et Admin uniquement
     */
    public function validationHistory($id)
    {
        $facture = Facture::with(['client'])->findOrFail($id);
        
        $history = [];
        
        if ($facture->validated_by) {
            $validator = \App\Models\User::find($facture->validated_by);
            $history[] = [
                'action' => 'validated',
                'user' => $validator ? $validator->nom . ' ' . $validator->prenom : 'Utilisateur supprimé',
                'date' => $facture->validated_at,
                'comment' => $facture->validation_comment
            ];
        }
        
        if ($facture->rejected_by) {
            $rejector = \App\Models\User::find($facture->rejected_by);
            $history[] = [
                'action' => 'rejected',
                'user' => $rejector ? $rejector->nom . ' ' . $rejector->prenom : 'Utilisateur supprimé',
                'date' => $facture->rejected_at,
                'reason' => $facture->rejection_reason,
                'comment' => $facture->rejection_comment
            ];
        }
        
        return response()->json([
            'success' => true,
            'facture' => $facture,
            'history' => $history,
            'message' => 'Historique récupéré avec succès'
        ]);
    }
    
    /**
     * Rapports financiers
     * Accessible par Comptable, Patron et Admin
     */
    public function reports(Request $request)
    {
        $query = Facture::query();
        
        // Filtrage par période
        if ($request->has('date_debut')) {
            $query->where('date_facture', '>=', $request->date_debut);
        }
        
        if ($request->has('date_fin')) {
            $query->where('date_facture', '<=', $request->date_fin);
        }
        
        $factures = $query->get();
        
        $rapport = [
            'total_factures' => $factures->count(),
            'montant_total' => $factures->sum('montant'),
            'factures_payees' => $factures->where('status', 'payee')->count(),
            'montant_paye' => $factures->where('status', 'payee')->sum('montant'),
            'factures_impayees' => $factures->where('status', 'impayee')->count(),
            'montant_impaye' => $factures->where('status', 'impayee')->sum('montant'),
            'factures_en_attente' => $factures->where('status', 'en_attente')->count(),
            'montant_en_attente' => $factures->where('status', 'en_attente')->sum('montant'),
            'factures_validees' => $factures->where('status', 'validee')->count(),
            'montant_valide' => $factures->where('status', 'validee')->sum('montant'),
            'factures_rejetees' => $factures->where('status', 'rejetee')->count(),
            'montant_rejete' => $factures->where('status', 'rejetee')->sum('montant')
        ];
        
        return response()->json([
            'success' => true,
            'rapport' => $rapport,
            'message' => 'Rapport financier généré avec succès'
        ]);
    }
}