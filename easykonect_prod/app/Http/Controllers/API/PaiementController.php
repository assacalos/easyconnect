<?php

namespace App\Http\Controllers\API;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\Paiement;
use App\Models\Facture;
use App\Models\Client;

class PaiementController extends Controller
{
    /**
     * Liste des paiements
     * Accessible par Comptable, Patron et Admin
     */
    public function index(Request $request)
    {
        $query = Paiement::with(['facture.client']);
        
        // Filtrage par statut si fourni
        if ($request->has('status')) {
            $query->where('status', $request->status);
        }
        
        // Filtrage par type de paiement
        if ($request->has('type')) {
            $query->where('type', $request->type);
        }
        
        // Filtrage par date si fourni
        if ($request->has('date_debut')) {
            $query->where('date_paiement', '>=', $request->date_debut);
        }
        
        if ($request->has('date_fin')) {
            $query->where('date_paiement', '<=', $request->date_fin);
        }
        
        // Filtrage par montant si fourni
        if ($request->has('montant_min')) {
            $query->where('montant', '>=', $request->montant_min);
        }
        
        if ($request->has('montant_max')) {
            $query->where('montant', '<=', $request->montant_max);
        }
        
        // Si commercial → filtre ses propres clients
        if (auth()->user()->isCommercial()) {
            $query->whereHas('facture.client', function($q) {
                $q->where('user_id', auth()->id());
            });
        }
        
        $paiements = $query->orderBy('created_at', 'desc')->paginate($request->get('per_page', 15));
        
        return response()->json([
            'success' => true,
            'paiements' => $paiements,
            'message' => 'Liste des paiements récupérée avec succès'
        ]);
    }

    /**
     * Détails d'un paiement
     * Accessible par Comptable, Patron et Admin
     */
    public function show($id)
    {
        $paiement = Paiement::with(['facture.client'])->findOrFail($id);
        
        // Vérification des permissions pour les commerciaux
        if (auth()->user()->isCommercial() && $paiement->facture->client->user_id !== auth()->id()) {
            return response()->json([
                'success' => false,
                'message' => 'Accès refusé à ce paiement'
            ], 403);
        }
        
        return response()->json([
            'success' => true,
            'paiement' => $paiement,
            'message' => 'Paiement récupéré avec succès'
        ]);
    }

    /**
     * Créer un paiement
     * Accessible par Comptable et Admin
     */
    public function store(Request $request)
    {
        $request->validate([
            'facture_id' => 'required|exists:factures,id',
            'montant' => 'required|numeric|min:0.01',
            'date_paiement' => 'required|date',
            'mode_paiement' => 'required|in:especes,cheque,virement,carte_bancaire',
            'reference' => 'nullable|string|max:255',
            'statut' => 'required|in:en_attente,valide,rejete',
            'commentaire' => 'nullable|string'
        ]);

        // Vérifier que la facture existe et n'est pas déjà payée
        $facture = Facture::findOrFail($request->facture_id);
        
        if ($facture->statut === 'payee') {
            return response()->json([
                'success' => false,
                'message' => 'Cette facture est déjà marquée comme payée'
            ], 400);
        }

        $paiement = Paiement::create([
            'facture_id' => $request->facture_id,
            'montant' => $request->montant,
            'date_paiement' => $request->date_paiement,
            'mode_paiement' => $request->mode_paiement,
            'reference' => $request->reference,
            'statut' => $request->statut,
            'commentaire' => $request->commentaire,
            'user_id' => auth()->id()
        ]);

        // Si le paiement est validé, marquer la facture comme payée
        if ($request->statut === 'valide') {
            $facture->update(['statut' => 'payee']);
        }

        return response()->json([
            'success' => true,
            'paiement' => $paiement,
            'message' => 'Paiement créé avec succès'
        ], 201);
    }

    /**
     * Modifier un paiement
     * Accessible par Comptable et Admin
     */
    public function update(Request $request, $id)
    {
        $paiement = Paiement::findOrFail($id);
        
        // Vérifier que le paiement peut être modifié
        if ($paiement->statut === 'valide') {
            return response()->json([
                'success' => false,
                'message' => 'Impossible de modifier un paiement validé'
            ], 400);
        }

        $request->validate([
            'montant' => 'required|numeric|min:0.01',
            'date_paiement' => 'required|date',
            'mode_paiement' => 'required|in:especes,cheque,virement,carte_bancaire',
            'reference' => 'nullable|string|max:255',
            'statut' => 'required|in:en_attente,valide,rejete',
            'commentaire' => 'nullable|string'
        ]);

        $paiement->update($request->all());

        // Si le paiement est validé, marquer la facture comme payée
        if ($request->statut === 'valide') {
            $paiement->facture->update(['statut' => 'payee']);
        }

        return response()->json([
            'success' => true,
            'paiement' => $paiement,
            'message' => 'Paiement modifié avec succès'
        ]);
    }

    /**
     * Valider un paiement
     * Accessible par Comptable et Admin
     */
    public function validatePaiement($id)
    {
        $paiement = Paiement::findOrFail($id);
        
        if ($paiement->statut === 'valide') {
            return response()->json([
                'success' => false,
                'message' => 'Ce paiement est déjà validé'
            ], 400);
        }
        
        $paiement->update([
            'statut' => 'valide',
            'date_validation' => now()
        ]);

        // Marquer la facture comme payée
        $paiement->facture->update(['statut' => 'payee']);

        return response()->json([
            'success' => true,
            'paiement' => $paiement,
            'message' => 'Paiement validé avec succès'
        ]);
    }

    /**
     * Rejeter un paiement
     * Accessible par Comptable et Admin
     */
    public function reject(Request $request, $id)
    {
        $request->validate([
            'commentaire' => 'required|string'
        ]);

        $paiement = Paiement::findOrFail($id);
        
        $paiement->update([
            'statut' => 'rejete',
            'commentaire' => $request->commentaire
        ]);

        return response()->json([
            'success' => true,
            'paiement' => $paiement,
            'message' => 'Paiement rejeté avec succès'
        ]);
    }

    /**
     * Supprimer un paiement
     * Accessible par Admin uniquement
     */
    public function destroy($id)
    {
        $paiement = Paiement::findOrFail($id);
        
        // Vérifier que le paiement peut être supprimé
        if ($paiement->statut === 'valide') {
            return response()->json([
                'success' => false,
                'message' => 'Impossible de supprimer un paiement validé'
            ], 400);
        }
        
        $paiement->delete();

        return response()->json([
            'success' => true,
            'message' => 'Paiement supprimé avec succès'
        ]);
    }

    /**
     * Rapports de paiements
     * Accessible par Comptable, Patron et Admin
     */
    public function reports(Request $request)
    {
        $query = Paiement::query();
        
        // Filtrage par période
        if ($request->has('date_debut')) {
            $query->where('date_paiement', '>=', $request->date_debut);
        }
        
        if ($request->has('date_fin')) {
            $query->where('date_paiement', '<=', $request->date_fin);
        }
        
        $paiements = $query->get();
        
        $rapport = [
            'total_paiements' => $paiements->count(),
            'montant_total' => $paiements->sum('montant'),
            'paiements_valides' => $paiements->where('statut', 'valide')->count(),
            'montant_valide' => $paiements->where('statut', 'valide')->sum('montant'),
            'paiements_en_attente' => $paiements->where('statut', 'en_attente')->count(),
            'montant_en_attente' => $paiements->where('statut', 'en_attente')->sum('montant'),
            'paiements_rejetes' => $paiements->where('statut', 'rejete')->count(),
            'montant_rejete' => $paiements->where('statut', 'rejete')->sum('montant'),
            'par_mode_paiement' => $paiements->groupBy('mode_paiement')->map(function($group) {
                return [
                    'count' => $group->count(),
                    'montant' => $group->sum('montant')
                ];
            })
        ];
        
        return response()->json([
            'success' => true,
            'rapport' => $rapport,
            'message' => 'Rapport de paiements généré avec succès'
        ]);
    }

    /**
     * Soumettre un paiement
     */
    public function submit($id)
    {
        $paiement = Paiement::findOrFail($id);

        if ($paiement->submit()) {
            return response()->json([
                'success' => true,
                'paiement' => $paiement,
                'message' => 'Paiement soumis avec succès'
            ]);
        }

        return response()->json([
            'success' => false,
            'message' => 'Impossible de soumettre ce paiement'
        ], 400);
    }

    /**
     * Approuver un paiement
     */
    public function approve(Request $request, $id)
    {
        $paiement = Paiement::findOrFail($id);

        $request->validate([
            'comment' => 'nullable|string'
        ]);

        if ($paiement->approve(auth()->id(), $request->comment)) {
            return response()->json([
                'success' => true,
                'paiement' => $paiement,
                'message' => 'Paiement approuvé avec succès'
            ]);
        }

        return response()->json([
            'success' => false,
            'message' => 'Impossible d\'approuver ce paiement'
        ], 400);
    }

    /**
     * Marquer comme payé
     */
    public function markAsPaid($id)
    {
        $paiement = Paiement::findOrFail($id);

        if ($paiement->pay(auth()->id())) {
            return response()->json([
                'success' => true,
                'paiement' => $paiement,
                'message' => 'Paiement marqué comme payé avec succès'
            ]);
        }

        return response()->json([
            'success' => false,
            'message' => 'Impossible de marquer ce paiement comme payé'
        ], 400);
    }

    /**
     * Marquer comme en retard
     */
    public function markAsOverdue($id)
    {
        $paiement = Paiement::findOrFail($id);

        if ($paiement->markAsOverdue()) {
            return response()->json([
                'success' => true,
                'paiement' => $paiement,
                'message' => 'Paiement marqué comme en retard avec succès'
            ]);
        }

        return response()->json([
            'success' => false,
            'message' => 'Impossible de marquer ce paiement comme en retard'
        ], 400);
    }

    /**
     * Créer un paiement avec numéro automatique
     */
    public function createWithNumber(Request $request)
    {
        $request->validate([
            'facture_id' => 'required|exists:factures,id',
            'montant' => 'required|numeric|min:0.01',
            'date_paiement' => 'required|date',
            'due_date' => 'nullable|date|after:date_paiement',
            'type' => 'required|in:one_time,monthly',
            'type_paiement' => 'required|in:especes,virement,cheque,carte_bancaire,mobile_money',
            'currency' => 'nullable|string|max:3',
            'description' => 'nullable|string',
            'commentaire' => 'nullable|string',
            'reference' => 'nullable|string|max:255'
        ]);

        $paiement = Paiement::create([
            'payment_number' => Paiement::generatePaymentNumber(),
            'type' => $request->type,
            'facture_id' => $request->facture_id,
            'montant' => $request->montant,
            'date_paiement' => $request->date_paiement,
            'due_date' => $request->due_date,
            'currency' => $request->currency ?? 'FCFA',
            'type_paiement' => $request->type_paiement,
            'status' => 'draft',
            'description' => $request->description,
            'commentaire' => $request->commentaire,
            'reference' => $request->reference,
            'user_id' => auth()->id()
        ]);

        return response()->json([
            'success' => true,
            'paiement' => $paiement,
            'message' => 'Paiement créé avec succès'
        ], 201);
    }
}