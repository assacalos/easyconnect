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
        
        // Filtrage par statut si fourni
        if ($request->has('statut')) {
            $query->where('statut', $request->statut);
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
            'statut' => 'required|in:en_attente,payee,impayee'
        ]);

        $facture = Facture::create([
            'client_id' => $request->client_id,
            'numero_facture' => $request->numero_facture,
            'montant' => $request->montant,
            'date_facture' => $request->date_facture,
            'description' => $request->description,
            'statut' => $request->statut,
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
        if ($facture->statut === 'payee') {
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
            'statut' => 'required|in:en_attente,payee,impayee'
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
        if ($facture->statut === 'payee') {
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
        
        if ($facture->statut === 'payee') {
            return response()->json([
                'success' => false,
                'message' => 'Cette facture est déjà marquée comme payée'
            ], 400);
        }
        
        $facture->update(['statut' => 'payee']);

        return response()->json([
            'success' => true,
            'facture' => $facture,
            'message' => 'Facture marquée comme payée'
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
            'factures_payees' => $factures->where('statut', 'payee')->count(),
            'montant_paye' => $factures->where('statut', 'payee')->sum('montant'),
            'factures_impayees' => $factures->where('statut', 'impayee')->count(),
            'montant_impaye' => $factures->where('statut', 'impayee')->sum('montant'),
            'factures_en_attente' => $factures->where('statut', 'en_attente')->count(),
            'montant_en_attente' => $factures->where('statut', 'en_attente')->sum('montant')
        ];
        
        return response()->json([
            'success' => true,
            'rapport' => $rapport,
            'message' => 'Rapport financier généré avec succès'
        ]);
    }
}