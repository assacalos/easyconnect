<?php

namespace App\Http\Controllers\API;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\BonDeCommande;
use App\Models\Client;
use App\Models\Fournisseur;

class BonDeCommandeController extends Controller
{
    /**
     * Liste des bons de commande avec filtres avancés
     * Accessible par Commercial, Comptable, Patron et Admin
     */
    public function index(Request $request)
    {
        try {
            $user = $request->user();
            $query = BonDeCommande::with(['client', 'fournisseur', 'createur']);
            
            // Filtrage par statut
            if ($request->has('statut')) {
                $query->where('statut', $request->statut);
            }
            
            // Filtrage par date de commande
            if ($request->has('date_debut')) {
                $query->where('date_commande', '>=', $request->date_debut);
            }
            
            if ($request->has('date_fin')) {
                $query->where('date_commande', '<=', $request->date_fin);
            }
            
            // Filtrage par client
            if ($request->has('client_id')) {
                $query->where('client_id', $request->client_id);
            }
            
            // Filtrage par fournisseur
            if ($request->has('fournisseur_id')) {
                $query->where('fournisseur_id', $request->fournisseur_id);
            }
            
            // Filtrage par montant
            if ($request->has('montant_min')) {
                $query->where('montant_total', '>=', $request->montant_min);
            }
            
            if ($request->has('montant_max')) {
                $query->where('montant_total', '<=', $request->montant_max);
            }
            
            // Filtrage par retard
            if ($request->has('en_retard')) {
                $query->where('date_livraison_prevue', '<', now())
                      ->where('statut', '!=', 'livre');
            }
            
            // Si commercial → filtre ses propres clients
            if ($user->role == 2) { // Commercial
                $query->whereHas('client', function($q) use ($user) {
                    $q->where('user_id', $user->id);
                });
            }
            
            // Pagination
            $perPage = $request->get('per_page', 15);
            $bons = $query->orderBy('date_commande', 'desc')->paginate($perPage);
            
            return response()->json([
                'success' => true,
                'data' => $bons,
                'message' => 'Liste des bons de commande récupérée avec succès'
            ]);
            
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de la récupération des bons de commande: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Détails d'un bon de commande
     * Accessible par Commercial, Comptable, Patron et Admin
     */
    public function show($id)
    {
        $bon = BonDeCommande::with(['client', 'fournisseur'])->findOrFail($id);
        
        // Vérification des permissions pour les commerciaux
        if (auth()->user()->isCommercial() && $bon->client->user_id !== auth()->id()) {
            return response()->json([
                'success' => false,
                'message' => 'Accès refusé à ce bon de commande'
            ], 403);
        }
        
        return response()->json([
            'success' => true,
            'bon_de_commande' => $bon,
            'message' => 'Bon de commande récupéré avec succès'
        ]);
    }

    /**
     * Créer un bon de commande
     * Accessible par Commercial, Comptable et Admin
     */
    public function store(Request $request)
    {
        $request->validate([
            'client_id' => 'required|exists:clients,id',
            'fournisseur_id' => 'required|exists:fournisseurs,id',
            'numero_commande' => 'required|string|unique:bon_de_commandes',
            'date_commande' => 'required|date',
            'date_livraison_prevue' => 'nullable|date|after:date_commande',
            'montant_total' => 'required|numeric|min:0',
            'description' => 'nullable|string',
            'statut' => 'required|in:en_attente,valide,en_cours,livre,annule',
            'commentaire' => 'nullable|string',
            'conditions_paiement' => 'nullable|string',
            'delai_livraison' => 'nullable|integer|min:1'
        ]);

        $bon = BonDeCommande::create([
            'client_id' => $request->client_id,
            'fournisseur_id' => $request->fournisseur_id,
            'numero_commande' => $request->numero_commande,
            'date_commande' => $request->date_commande,
            'date_livraison_prevue' => $request->date_livraison_prevue,
            'montant_total' => $request->montant_total,
            'description' => $request->description,
            'statut' => $request->statut,
            'commentaire' => $request->commentaire,
            'conditions_paiement' => $request->conditions_paiement,
            'delai_livraison' => $request->delai_livraison,
            'user_id' => auth()->id()
        ]);

        return response()->json([
            'success' => true,
            'bon_de_commande' => $bon,
            'message' => 'Bon de commande créé avec succès'
        ], 201);
    }

    /**
     * Modifier un bon de commande
     * Accessible par Commercial, Comptable et Admin
     */
    public function update(Request $request, $id)
    {
        $bon = BonDeCommande::findOrFail($id);
        
        // Vérifier que le bon de commande peut être modifié
        if (in_array($bon->statut, ['valide', 'en_cours', 'livre'])) {
            return response()->json([
                'success' => false,
                'message' => 'Impossible de modifier un bon de commande validé ou en cours'
            ], 400);
        }

        $request->validate([
            'numero_commande' => 'required|string|unique:bon_de_commandes,numero_commande,' . $bon->id,
            'date_commande' => 'required|date',
            'date_livraison_prevue' => 'nullable|date|after:date_commande',
            'montant_total' => 'required|numeric|min:0',
            'description' => 'nullable|string',
            'statut' => 'required|in:en_attente,valide,en_cours,livre,annule',
            'commentaire' => 'nullable|string',
            'conditions_paiement' => 'nullable|string',
            'delai_livraison' => 'nullable|integer|min:1'
        ]);

        $bon->update($request->all());

        return response()->json([
            'success' => true,
            'bon_de_commande' => $bon,
            'message' => 'Bon de commande modifié avec succès'
        ]);
    }

    /**
     * Valider un bon de commande
     * Accessible par Comptable, Patron et Admin
     */
    public function validate($id)
    {
        $bon = BonDeCommande::findOrFail($id);
        
        if ($bon->statut === 'valide') {
            return response()->json([
                'success' => false,
                'message' => 'Ce bon de commande est déjà validé'
            ], 400);
        }
        
        $bon->update([
            'statut' => 'valide',
            'date_validation' => now()
        ]);

        return response()->json([
            'success' => true,
            'bon_de_commande' => $bon,
            'message' => 'Bon de commande validé avec succès'
        ]);
    }

    /**
     * Marquer comme en cours
     * Accessible par Comptable, Patron et Admin
     */
    public function markInProgress($id)
    {
        $bon = BonDeCommande::findOrFail($id);
        
        if ($bon->statut !== 'valide') {
            return response()->json([
                'success' => false,
                'message' => 'Le bon de commande doit être validé avant d\'être marqué comme en cours'
            ], 400);
        }
        
        $bon->update([
            'statut' => 'en_cours',
            'date_debut_traitement' => now()
        ]);

        return response()->json([
            'success' => true,
            'bon_de_commande' => $bon,
            'message' => 'Bon de commande marqué comme en cours'
        ]);
    }

    /**
     * Marquer comme livré
     * Accessible par Comptable, Patron et Admin
     */
    public function markDelivered($id)
    {
        $bon = BonDeCommande::findOrFail($id);
        
        if ($bon->statut !== 'en_cours') {
            return response()->json([
                'success' => false,
                'message' => 'Le bon de commande doit être en cours avant d\'être marqué comme livré'
            ], 400);
        }
        
        $bon->update([
            'statut' => 'livre',
            'date_livraison' => now()
        ]);

        return response()->json([
            'success' => true,
            'bon_de_commande' => $bon,
            'message' => 'Bon de commande marqué comme livré'
        ]);
    }

    /**
     * Annuler un bon de commande
     * Accessible par Comptable, Patron et Admin
     */
    public function cancel(Request $request, $id)
    {
        $request->validate([
            'commentaire' => 'required|string'
        ]);

        $bon = BonDeCommande::findOrFail($id);
        
        if (in_array($bon->statut, ['livre', 'annule'])) {
            return response()->json([
                'success' => false,
                'message' => 'Impossible d\'annuler un bon de commande livré ou déjà annulé'
            ], 400);
        }
        
        $bon->update([
            'statut' => 'annule',
            'commentaire' => $request->commentaire,
            'date_annulation' => now()
        ]);

        return response()->json([
            'success' => true,
            'bon_de_commande' => $bon,
            'message' => 'Bon de commande annulé avec succès'
        ]);
    }

    /**
     * Supprimer un bon de commande
     * Accessible par Admin uniquement
     */
    public function destroy($id)
    {
        $bon = BonDeCommande::findOrFail($id);
        
        // Vérifier que le bon de commande peut être supprimé
        if (in_array($bon->statut, ['valide', 'en_cours', 'livre'])) {
            return response()->json([
                'success' => false,
                'message' => 'Impossible de supprimer un bon de commande validé, en cours ou livré'
            ], 400);
        }
        
        $bon->delete();

        return response()->json([
            'success' => true,
            'message' => 'Bon de commande supprimé avec succès'
        ]);
    }

    /**
     * Rapports de bons de commande
     * Accessible par Comptable, Patron et Admin
     */
    public function reports(Request $request)
    {
        $query = BonDeCommande::with(['client', 'fournisseur']);
        
        // Filtrage par période
        if ($request->has('date_debut')) {
            $query->where('date_commande', '>=', $request->date_debut);
        }
        
        if ($request->has('date_fin')) {
            $query->where('date_commande', '<=', $request->date_fin);
        }
        
        $bons = $query->get();
        
        $rapport = [
            'total_bons' => $bons->count(),
            'montant_total' => $bons->sum('montant_total'),
            'bons_en_attente' => $bons->where('statut', 'en_attente')->count(),
            'montant_en_attente' => $bons->where('statut', 'en_attente')->sum('montant_total'),
            'bons_valides' => $bons->where('statut', 'valide')->count(),
            'montant_valide' => $bons->where('statut', 'valide')->sum('montant_total'),
            'bons_en_cours' => $bons->where('statut', 'en_cours')->count(),
            'montant_en_cours' => $bons->where('statut', 'en_cours')->sum('montant_total'),
            'bons_livres' => $bons->where('statut', 'livre')->count(),
            'montant_livre' => $bons->where('statut', 'livre')->sum('montant_total'),
            'bons_annules' => $bons->where('statut', 'annule')->count(),
            'montant_annule' => $bons->where('statut', 'annule')->sum('montant_total'),
            'par_client' => $bons->groupBy('client_id')->map(function($group, $clientId) {
                $client = Client::find($clientId);
                return [
                    'client' => $client ? $client->nom . ' ' . $client->prenom : 'Client inconnu',
                    'total_bons' => $group->count(),
                    'montant_total' => $group->sum('montant_total')
                ];
            }),
            'par_fournisseur' => $bons->groupBy('fournisseur_id')->map(function($group, $fournisseurId) {
                $fournisseur = Fournisseur::find($fournisseurId);
                return [
                    'fournisseur' => $fournisseur ? $fournisseur->nom : 'Fournisseur inconnu',
                    'total_bons' => $group->count(),
                    'montant_total' => $group->sum('montant_total')
                ];
            })
        ];
        
        return response()->json([
            'success' => true,
            'rapport' => $rapport,
            'message' => 'Rapport de bons de commande généré avec succès'
        ]);
    }

    /**
     * Dashboard des bons de commande
     * Accessible par Comptable, Patron et Admin
     */
    public function dashboard(Request $request)
    {
        try {
            $user = $request->user();
            $query = BonDeCommande::query();
            
            // Filtrage par période
            if ($request->has('date_debut')) {
                $query->where('date_commande', '>=', $request->date_debut);
            }
            
            if ($request->has('date_fin')) {
                $query->where('date_commande', '<=', $request->date_fin);
            }
            
            $bons = $query->get();
            
            $dashboard = [
                'statistiques' => [
                    'total_bons' => $bons->count(),
                    'montant_total' => $bons->sum('montant_total'),
                    'bons_en_attente' => $bons->where('statut', 'en_attente')->count(),
                    'bons_valides' => $bons->where('statut', 'valide')->count(),
                    'bons_en_cours' => $bons->where('statut', 'en_cours')->count(),
                    'bons_livres' => $bons->where('statut', 'livre')->count(),
                    'bons_annules' => $bons->where('statut', 'annule')->count(),
                ],
                'montants_par_statut' => [
                    'en_attente' => $bons->where('statut', 'en_attente')->sum('montant_total'),
                    'valide' => $bons->where('statut', 'valide')->sum('montant_total'),
                    'en_cours' => $bons->where('statut', 'en_cours')->sum('montant_total'),
                    'livre' => $bons->where('statut', 'livre')->sum('montant_total'),
                    'annule' => $bons->where('statut', 'annule')->sum('montant_total'),
                ],
                'bons_en_retard' => $bons->filter(function($bon) {
                    return $bon->date_livraison_prevue && 
                           $bon->date_livraison_prevue < now() && 
                           !in_array($bon->statut, ['livre', 'annule']);
                })->count(),
                'bons_recents' => BonDeCommande::with(['client', 'fournisseur'])
                    ->orderBy('created_at', 'desc')
                    ->limit(5)
                    ->get()
            ];
            
            return response()->json([
                'success' => true,
                'data' => $dashboard,
                'message' => 'Dashboard généré avec succès'
            ]);
            
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de la génération du dashboard: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Statistiques par période
     * Accessible par Comptable, Patron et Admin
     */
    public function statistics(Request $request)
    {
        try {
            $date_debut = $request->get('date_debut', now()->subMonths(6));
            $date_fin = $request->get('date_fin', now());
            
            $bons = BonDeCommande::whereBetween('date_commande', [$date_debut, $date_fin])->get();
            
            $statistiques = [
                'periode' => [
                    'debut' => $date_debut,
                    'fin' => $date_fin
                ],
                'totaux' => [
                    'nombre_bons' => $bons->count(),
                    'montant_total' => $bons->sum('montant_total'),
                    'montant_moyen' => $bons->count() > 0 ? $bons->avg('montant_total') : 0
                ],
                'par_mois' => $bons->groupBy(function($bon) {
                    return $bon->date_commande->format('Y-m');
                })->map(function($group, $mois) {
                    return [
                        'mois' => $mois,
                        'nombre_bons' => $group->count(),
                        'montant_total' => $group->sum('montant_total')
                    ];
                }),
                'par_statut' => $bons->groupBy('statut')->map(function($group, $statut) {
                    return [
                        'statut' => $statut,
                        'nombre' => $group->count(),
                        'montant' => $group->sum('montant_total')
                    ];
                })
            ];
            
            return response()->json([
                'success' => true,
                'data' => $statistiques,
                'message' => 'Statistiques générées avec succès'
            ]);
            
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de la génération des statistiques: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Recherche avancée de bons de commande
     * Accessible par Commercial, Comptable, Patron et Admin
     */
    public function search(Request $request)
    {
        try {
            $user = $request->user();
            $query = BonDeCommande::with(['client', 'fournisseur', 'createur']);
            
            // Recherche par numéro de commande
            if ($request->has('numero')) {
                $query->where('numero_commande', 'like', '%' . $request->numero . '%');
            }
            
            // Recherche par nom de client
            if ($request->has('client_nom')) {
                $query->whereHas('client', function($q) use ($request) {
                    $q->where('nom', 'like', '%' . $request->client_nom . '%')
                      ->orWhere('prenom', 'like', '%' . $request->client_nom . '%');
                });
            }
            
            // Recherche par nom de fournisseur
            if ($request->has('fournisseur_nom')) {
                $query->whereHas('fournisseur', function($q) use ($request) {
                    $q->where('nom', 'like', '%' . $request->fournisseur_nom . '%');
                });
            }
            
            // Recherche par description
            if ($request->has('description')) {
                $query->where('description', 'like', '%' . $request->description . '%');
            }
            
            // Si commercial → filtre ses propres clients
            if ($user->role == 2) {
                $query->whereHas('client', function($q) use ($user) {
                    $q->where('user_id', $user->id);
                });
            }
            
            $bons = $query->orderBy('date_commande', 'desc')->get();
            
            return response()->json([
                'success' => true,
                'data' => $bons,
                'count' => $bons->count(),
                'message' => 'Recherche effectuée avec succès'
            ]);
            
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de la recherche: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Dupliquer un bon de commande
     * Accessible par Commercial, Comptable et Admin
     */
    public function duplicate($id)
    {
        try {
            $originalBon = BonDeCommande::findOrFail($id);
            
            // Génération d'un nouveau numéro
            $numero = 'BC-' . date('Y') . '-' . str_pad(BonDeCommande::count() + 1, 4, '0', STR_PAD_LEFT);
            
            $nouveauBon = BonDeCommande::create([
                'client_id' => $originalBon->client_id,
                'fournisseur_id' => $originalBon->fournisseur_id,
                'numero_commande' => $numero,
                'date_commande' => now()->toDateString(),
                'date_livraison_prevue' => $originalBon->date_livraison_prevue,
                'montant_total' => $originalBon->montant_total,
                'description' => $originalBon->description,
                'statut' => 'en_attente',
                'commentaire' => 'Dupliqué depuis ' . $originalBon->numero_commande,
                'conditions_paiement' => $originalBon->conditions_paiement,
                'delai_livraison' => $originalBon->delai_livraison,
                'user_id' => auth()->id()
            ]);
            
            return response()->json([
                'success' => true,
                'data' => $nouveauBon->load(['client', 'fournisseur', 'createur']),
                'message' => 'Bon de commande dupliqué avec succès'
            ], 201);
            
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de la duplication: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Exporter les bons de commande
     * Accessible par Comptable, Patron et Admin
     */
    public function export(Request $request)
    {
        try {
            $query = BonDeCommande::with(['client', 'fournisseur', 'createur']);
            
            // Appliquer les mêmes filtres que l'index
            if ($request->has('statut')) {
                $query->where('statut', $request->statut);
            }
            
            if ($request->has('date_debut')) {
                $query->where('date_commande', '>=', $request->date_debut);
            }
            
            if ($request->has('date_fin')) {
                $query->where('date_commande', '<=', $request->date_fin);
            }
            
            $bons = $query->orderBy('date_commande', 'desc')->get();
            
            // Format pour export
            $exportData = $bons->map(function($bon) {
                return [
                    'Numéro' => $bon->numero_commande,
                    'Date commande' => $bon->date_commande->format('d/m/Y'),
                    'Client' => $bon->client->nom . ' ' . $bon->client->prenom,
                    'Fournisseur' => $bon->fournisseur->nom,
                    'Montant' => $bon->montant_total,
                    'Statut' => $bon->statut_libelle,
                    'Date livraison prévue' => $bon->date_livraison_prevue ? $bon->date_livraison_prevue->format('d/m/Y') : '',
                    'Date livraison' => $bon->date_livraison ? $bon->date_livraison->format('d/m/Y') : '',
                    'Description' => $bon->description,
                    'Créé par' => $bon->createur->nom . ' ' . $bon->createur->prenom
                ];
            });
            
            return response()->json([
                'success' => true,
                'data' => $exportData,
                'count' => $exportData->count(),
                'message' => 'Données exportées avec succès'
            ]);
            
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de l\'export: ' . $e->getMessage()
            ], 500);
        }
    }
}