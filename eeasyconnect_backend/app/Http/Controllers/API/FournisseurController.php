<?php

namespace App\Http\Controllers\API;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\Fournisseur;
use App\Models\BonDeCommande;

class FournisseurController extends Controller
{
    /**
     * Liste des fournisseurs
     * Accessible par tous les utilisateurs authentifiés
     */
    public function index(Request $request)
    {
        $query = Fournisseur::query();
        
        // Filtrage par statut si fourni
        if ($request->has('statut')) {
            $query->where('statut', $request->statut);
        }
        
        // Filtrage par nom si fourni
        if ($request->has('nom')) {
            $query->where('nom', 'like', '%' . $request->nom . '%');
        }
        
        // Filtrage par ville si fourni
        if ($request->has('ville')) {
            $query->where('ville', 'like', '%' . $request->ville . '%');
        }
        
        $fournisseurs = $query->orderBy('nom', 'asc')->get();
        
        return response()->json([
            'success' => true,
            'fournisseurs' => $fournisseurs,
            'message' => 'Liste des fournisseurs récupérée avec succès'
        ]);
    }

    /**
     * Détails d'un fournisseur
     * Accessible par tous les utilisateurs authentifiés
     */
    public function show($id)
    {
        $fournisseur = Fournisseur::with(['bonsDeCommande'])->findOrFail($id);
        
        return response()->json([
            'success' => true,
            'fournisseur' => $fournisseur,
            'message' => 'Fournisseur récupéré avec succès'
        ]);
    }

    /**
     * Créer un fournisseur
     * Accessible par Comptable et Admin
     */
    public function store(Request $request)
    {
        $request->validate([
            'nom' => 'required|string|max:255',
            'email' => 'required|email|unique:fournisseurs',
            'telephone' => 'required|string|max:20',
            'adresse' => 'required|string|max:500',
            'ville' => 'required|string|max:100',
            'code_postal' => 'required|string|max:10',
            'pays' => 'required|string|max:100',
            'contact_principal' => 'nullable|string|max:255',
            'telephone_contact' => 'nullable|string|max:20',
            'email_contact' => 'nullable|email',
            'site_web' => 'nullable|url',
            'statut' => 'required|in:actif,inactif,suspendu',
            'commentaire' => 'nullable|string',
            'conditions_paiement' => 'nullable|string',
            'delai_livraison' => 'nullable|integer|min:1'
        ]);

        $fournisseur = Fournisseur::create([
            'nom' => $request->nom,
            'email' => $request->email,
            'telephone' => $request->telephone,
            'adresse' => $request->adresse,
            'ville' => $request->ville,
            'code_postal' => $request->code_postal,
            'pays' => $request->pays,
            'contact_principal' => $request->contact_principal,
            'telephone_contact' => $request->telephone_contact,
            'email_contact' => $request->email_contact,
            'site_web' => $request->site_web,
            'statut' => $request->statut,
            'commentaire' => $request->commentaire,
            'conditions_paiement' => $request->conditions_paiement,
            'delai_livraison' => $request->delai_livraison,
            'user_id' => auth()->id()
        ]);

        return response()->json([
            'success' => true,
            'fournisseur' => $fournisseur,
            'message' => 'Fournisseur créé avec succès'
        ], 201);
    }

    /**
     * Modifier un fournisseur
     * Accessible par Comptable et Admin
     */
    public function update(Request $request, $id)
    {
        $fournisseur = Fournisseur::findOrFail($id);
        
        $request->validate([
            'nom' => 'required|string|max:255',
            'email' => 'required|email|unique:fournisseurs,email,' . $fournisseur->id,
            'telephone' => 'required|string|max:20',
            'adresse' => 'required|string|max:500',
            'ville' => 'required|string|max:100',
            'code_postal' => 'required|string|max:10',
            'pays' => 'required|string|max:100',
            'contact_principal' => 'nullable|string|max:255',
            'telephone_contact' => 'nullable|string|max:20',
            'email_contact' => 'nullable|email',
            'site_web' => 'nullable|url',
            'statut' => 'required|in:actif,inactif,suspendu',
            'commentaire' => 'nullable|string',
            'conditions_paiement' => 'nullable|string',
            'delai_livraison' => 'nullable|integer|min:1'
        ]);

        $fournisseur->update($request->all());

        return response()->json([
            'success' => true,
            'fournisseur' => $fournisseur,
            'message' => 'Fournisseur modifié avec succès'
        ]);
    }

    /**
     * Activer un fournisseur
     * Accessible par Comptable, Patron et Admin
     */
    public function activate($id)
    {
        $fournisseur = Fournisseur::findOrFail($id);
        
        if ($fournisseur->statut === 'actif') {
            return response()->json([
                'success' => false,
                'message' => 'Ce fournisseur est déjà actif'
            ], 400);
        }
        
        $fournisseur->update(['statut' => 'actif']);

        return response()->json([
            'success' => true,
            'fournisseur' => $fournisseur,
            'message' => 'Fournisseur activé avec succès'
        ]);
    }

    /**
     * Désactiver un fournisseur
     * Accessible par Comptable, Patron et Admin
     */
    public function deactivate($id)
    {
        $fournisseur = Fournisseur::findOrFail($id);
        
        if ($fournisseur->statut === 'inactif') {
            return response()->json([
                'success' => false,
                'message' => 'Ce fournisseur est déjà inactif'
            ], 400);
        }
        
        $fournisseur->update(['statut' => 'inactif']);

        return response()->json([
            'success' => true,
            'fournisseur' => $fournisseur,
            'message' => 'Fournisseur désactivé avec succès'
        ]);
    }

    /**
     * Suspendre un fournisseur
     * Accessible par Patron et Admin
     */
    public function suspend(Request $request, $id)
    {
        $request->validate([
            'commentaire' => 'required|string'
        ]);

        $fournisseur = Fournisseur::findOrFail($id);
        
        $fournisseur->update([
            'statut' => 'suspendu',
            'commentaire' => $request->commentaire
        ]);

        return response()->json([
            'success' => true,
            'fournisseur' => $fournisseur,
            'message' => 'Fournisseur suspendu avec succès'
        ]);
    }

    /**
     * Supprimer un fournisseur
     * Accessible par Admin uniquement
     */
    public function destroy($id)
    {
        $fournisseur = Fournisseur::findOrFail($id);
        
        // Vérifier qu'il n'y a pas de bons de commande associés
        $bonsDeCommande = BonDeCommande::where('fournisseur_id', $fournisseur->id)->count();
        
        if ($bonsDeCommande > 0) {
            return response()->json([
                'success' => false,
                'message' => 'Impossible de supprimer un fournisseur ayant des bons de commande associés'
            ], 400);
        }
        
        $fournisseur->delete();

        return response()->json([
            'success' => true,
            'message' => 'Fournisseur supprimé avec succès'
        ]);
    }

    /**
     * Statistiques d'un fournisseur
     * Accessible par Comptable, Patron et Admin
     */
    public function statistics($id)
    {
        $fournisseur = Fournisseur::findOrFail($id);
        
        $bonsDeCommande = BonDeCommande::where('fournisseur_id', $fournisseur->id)->get();
        
        $statistiques = [
            'fournisseur' => $fournisseur,
            'total_bons_commande' => $bonsDeCommande->count(),
            'montant_total_commandes' => $bonsDeCommande->sum('montant_total'),
            'bons_en_attente' => $bonsDeCommande->where('statut', 'en_attente')->count(),
            'bons_valides' => $bonsDeCommande->where('statut', 'valide')->count(),
            'bons_en_cours' => $bonsDeCommande->where('statut', 'en_cours')->count(),
            'bons_livres' => $bonsDeCommande->where('statut', 'livre')->count(),
            'bons_annules' => $bonsDeCommande->where('statut', 'annule')->count(),
            'montant_moyen_commande' => $bonsDeCommande->count() > 0 ? $bonsDeCommande->avg('montant_total') : 0,
            'derniere_commande' => $bonsDeCommande->sortByDesc('date_commande')->first()
        ];
        
        return response()->json([
            'success' => true,
            'statistiques' => $statistiques,
            'message' => 'Statistiques du fournisseur récupérées avec succès'
        ]);
    }

    /**
     * Rapports de fournisseurs
     * Accessible par Comptable, Patron et Admin
     */
    public function reports(Request $request)
    {
        $query = Fournisseur::with(['bonsDeCommande']);
        
        // Filtrage par statut si fourni
        if ($request->has('statut')) {
            $query->where('statut', $request->statut);
        }
        
        $fournisseurs = $query->get();
        
        $rapport = [
            'total_fournisseurs' => $fournisseurs->count(),
            'fournisseurs_actifs' => $fournisseurs->where('statut', 'actif')->count(),
            'fournisseurs_inactifs' => $fournisseurs->where('statut', 'inactif')->count(),
            'fournisseurs_suspendus' => $fournisseurs->where('statut', 'suspendu')->count(),
            'par_ville' => $fournisseurs->groupBy('ville')->map(function($group) {
                return [
                    'ville' => $group->first()->ville,
                    'count' => $group->count()
                ];
            }),
            'par_pays' => $fournisseurs->groupBy('pays')->map(function($group) {
                return [
                    'pays' => $group->first()->pays,
                    'count' => $group->count()
                ];
            }),
            'top_fournisseurs' => $fournisseurs->map(function($fournisseur) {
                $bons = $fournisseur->bonsDeCommande;
                return [
                    'fournisseur' => $fournisseur->nom,
                    'total_commandes' => $bons->count(),
                    'montant_total' => $bons->sum('montant_total')
                ];
            })->sortByDesc('montant_total')->take(10)
        ];
        
        return response()->json([
            'success' => true,
            'rapport' => $rapport,
            'message' => 'Rapport de fournisseurs généré avec succès'
        ]);
    }
}