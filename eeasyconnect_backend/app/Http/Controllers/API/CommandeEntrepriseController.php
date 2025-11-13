<?php

namespace App\Http\Controllers\API;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\CommandeEntreprise;
use App\Models\CommandeItem;
use App\Models\Client;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;

class CommandeEntrepriseController extends Controller
{
    /**
     * Liste des commandes entreprise avec filtres
     */
    public function index(Request $request)
    {
        try {
            $user = $request->user();
            $query = CommandeEntreprise::with(['client', 'commercial', 'items']);

            // Filtrage par statut
            if ($request->has('status')) {
                $query->where('status', $request->status);
            }

            // Filtrage par date de création
            if ($request->has('date_debut')) {
                $query->where('date_creation', '>=', $request->date_debut);
            }

            if ($request->has('date_fin')) {
                $query->where('date_creation', '<=', $request->date_fin);
            }

            // Filtrage par client
            if ($request->has('client_id')) {
                $query->where('client_id', $request->client_id);
            }

            // Filtrage par commercial
            if ($request->has('user_id')) {
                $query->where('user_id', $request->user_id);
            }

            // Si commercial → filtre ses propres commandes
            if ($user->role == 2) { // Commercial
                $query->where('user_id', $user->id);
            }

            // Filtrage par référence
            if ($request->has('reference')) {
                $query->where('reference', 'like', '%' . $request->reference . '%');
            }

            // Pagination
            $perPage = $request->get('per_page', 15);
            $commandes = $query->orderBy('date_creation', 'desc')->paginate($perPage);

            // Ajouter les montants calculés
            $commandes->getCollection()->transform(function ($commande) {
                $commande->montant_ht = $commande->montant_ht;
                $commande->montant_tva = $commande->montant_tva;
                $commande->montant_ttc = $commande->montant_ttc;
                $commande->status_text = $commande->status_text;
                return $commande;
            });

            return response()->json([
                'success' => true,
                'data' => $commandes,
                'message' => 'Liste des commandes récupérée avec succès'
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de la récupération des commandes: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Détails d'une commande entreprise
     */
    public function show($id)
    {
        try {
            $commande = CommandeEntreprise::with(['client', 'commercial', 'items'])
                ->findOrFail($id);

            // Vérification des permissions pour les commerciaux
            $user = auth()->user();
            if ($user->role == 2 && $commande->user_id !== $user->id) {
                return response()->json([
                    'success' => false,
                    'message' => 'Accès refusé à cette commande'
                ], 403);
            }

            // Ajouter les montants calculés
            $commande->montant_ht = $commande->montant_ht;
            $commande->montant_tva = $commande->montant_tva;
            $commande->montant_ttc = $commande->montant_ttc;
            $commande->status_text = $commande->status_text;

            return response()->json([
                'success' => true,
                'id' => $commande->id,
                'reference' => $commande->reference,
                'numero_commande' => $commande->reference,
                'client_id' => $commande->client_id,
                'cliennt_id' => $commande->client_id, // Pour compatibilité Flutter
                'user_id' => $commande->user_id,
                'date_creation' => $commande->date_creation->toIso8601String(),
                'date_commande' => $commande->date_creation->toIso8601String(),
                'date_validation' => $commande->date_validation?->toIso8601String(),
                'date_livraison_prevue' => $commande->date_livraison_prevue?->toIso8601String(),
                'adresse_livraison' => $commande->adresse_livraison,
                'notes' => $commande->notes,
                'description' => $commande->notes,
                'items' => $commande->items->map(function ($item) {
                    return [
                        'id' => $item->id,
                        'designation' => $item->designation,
                        'unite' => $item->unite,
                        'quantite' => $item->quantite,
                        'prix_unitaire' => $item->prix_unitaire,
                        'description' => $item->description,
                        'date_livraison' => $item->date_livraison?->toIso8601String(),
                    ];
                }),
                'remise_globale' => $commande->remise_globale,
                'tva' => $commande->tva,
                'conditions' => $commande->conditions,
                'conditions_paiement' => $commande->conditions,
                'status' => $commande->status,
                'commentaire' => $commande->commentaire_rejet,
                'numero_facture' => $commande->numero_facture,
                'est_facture' => $commande->est_facture ? 1 : 0,
                'est_livre' => $commande->est_livre ? 1 : 0,
                'montant_ht' => $commande->montant_ht,
                'montant_tva' => $commande->montant_tva,
                'montant_ttc' => $commande->montant_ttc,
                'status_text' => $commande->status_text,
                'client' => $commande->client,
                'commercial' => $commande->commercial,
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de la récupération de la commande: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Créer une commande entreprise
     */
    public function store(Request $request)
    {
        try {
            $request->validate([
                'reference' => 'nullable|string|unique:commandes_entreprise,reference',
                'client_id' => 'required|exists:clients,id',
                'user_id' => 'nullable|exists:users,id',
                'date_creation' => 'nullable|date',
                'date_livraison_prevue' => 'nullable|date',
                'adresse_livraison' => 'nullable|string',
                'notes' => 'nullable|string',
                'items' => 'required|array|min:1',
                'items.*.designation' => 'required|string',
                'items.*.unite' => 'required|string',
                'items.*.quantite' => 'required|integer|min:1',
                'items.*.prix_unitaire' => 'required|numeric|min:0',
                'items.*.description' => 'nullable|string',
                'items.*.date_livraison' => 'nullable|date',
                'remise_globale' => 'nullable|numeric|min:0|max:100',
                'tva' => 'nullable|numeric|min:0|max:100',
                'conditions' => 'nullable|string',
            ]);

            DB::beginTransaction();

            // Générer une référence si non fournie
            $reference = $request->reference ?? 'CMD-' . strtoupper(Str::random(8));

            // Créer la commande
            $commande = CommandeEntreprise::create([
                'reference' => $reference,
                'client_id' => $request->client_id,
                'user_id' => $request->user_id ?? auth()->id(),
                'date_creation' => $request->date_creation ?? now(),
                'date_livraison_prevue' => $request->date_livraison_prevue,
                'adresse_livraison' => $request->adresse_livraison,
                'notes' => $request->notes,
                'remise_globale' => $request->remise_globale,
                'tva' => $request->tva ?? 20.0,
                'conditions' => $request->conditions,
                'status' => 1, // Soumis par défaut
            ]);

            // Créer les items
            foreach ($request->items as $itemData) {
                CommandeItem::create([
                    'commande_entreprise_id' => $commande->id,
                    'designation' => $itemData['designation'],
                    'unite' => $itemData['unite'],
                    'quantite' => $itemData['quantite'],
                    'prix_unitaire' => $itemData['prix_unitaire'],
                    'description' => $itemData['description'] ?? null,
                    'date_livraison' => isset($itemData['date_livraison']) ? $itemData['date_livraison'] : null,
                ]);
            }

            DB::commit();

            $commande->load(['client', 'commercial', 'items']);

            return response()->json([
                'success' => true,
                'id' => $commande->id,
                'reference' => $commande->reference,
                'numero_commande' => $commande->reference,
                'client_id' => $commande->client_id,
                'user_id' => $commande->user_id,
                'date_creation' => $commande->date_creation->toIso8601String(),
                'date_commande' => $commande->date_creation->toIso8601String(),
                'date_livraison_prevue' => $commande->date_livraison_prevue?->toIso8601String(),
                'adresse_livraison' => $commande->adresse_livraison,
                'notes' => $commande->notes,
                'items' => $commande->items,
                'remise_globale' => $commande->remise_globale,
                'tva' => $commande->tva,
                'conditions' => $commande->conditions,
                'status' => $commande->status,
                'montant_ht' => $commande->montant_ht,
                'montant_tva' => $commande->montant_tva,
                'montant_ttc' => $commande->montant_ttc,
                'message' => 'Commande créée avec succès'
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
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de la création de la commande: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Modifier une commande entreprise
     */
    public function update(Request $request, $id)
    {
        try {
            $commande = CommandeEntreprise::findOrFail($id);

            // Vérifier que la commande peut être modifiée
            if ($commande->status != 1) { // Seulement si soumis
                return response()->json([
                    'success' => false,
                    'message' => 'Impossible de modifier une commande validée, rejetée ou livrée'
                ], 400);
            }

            $request->validate([
                'reference' => 'nullable|string|unique:commandes_entreprise,reference,' . $commande->id,
                'client_id' => 'nullable|exists:clients,id',
                'date_livraison_prevue' => 'nullable|date',
                'adresse_livraison' => 'nullable|string',
                'notes' => 'nullable|string',
                'items' => 'nullable|array',
                'items.*.designation' => 'required_with:items|string',
                'items.*.unite' => 'required_with:items|string',
                'items.*.quantite' => 'required_with:items|integer|min:1',
                'items.*.prix_unitaire' => 'required_with:items|numeric|min:0',
                'items.*.description' => 'nullable|string',
                'items.*.date_livraison' => 'nullable|date',
                'remise_globale' => 'nullable|numeric|min:0|max:100',
                'tva' => 'nullable|numeric|min:0|max:100',
                'conditions' => 'nullable|string',
            ]);

            DB::beginTransaction();

            // Mettre à jour la commande
            $commande->update($request->only([
                'reference', 'client_id', 'date_livraison_prevue',
                'adresse_livraison', 'notes', 'remise_globale', 'tva', 'conditions'
            ]));

            // Mettre à jour les items si fournis
            if ($request->has('items')) {
                // Supprimer les anciens items
                $commande->items()->delete();

                // Créer les nouveaux items
                foreach ($request->items as $itemData) {
                    CommandeItem::create([
                        'commande_entreprise_id' => $commande->id,
                        'designation' => $itemData['designation'],
                        'unite' => $itemData['unite'],
                        'quantite' => $itemData['quantite'],
                        'prix_unitaire' => $itemData['prix_unitaire'],
                        'description' => $itemData['description'] ?? null,
                        'date_livraison' => isset($itemData['date_livraison']) ? $itemData['date_livraison'] : null,
                    ]);
                }
            }

            DB::commit();

            $commande->load(['client', 'commercial', 'items']);

            return response()->json([
                'success' => true,
                'id' => $commande->id,
                'reference' => $commande->reference,
                'numero_commande' => $commande->reference,
                'client_id' => $commande->client_id,
                'user_id' => $commande->user_id,
                'date_creation' => $commande->date_creation->toIso8601String(),
                'date_commande' => $commande->date_creation->toIso8601String(),
                'date_livraison_prevue' => $commande->date_livraison_prevue?->toIso8601String(),
                'adresse_livraison' => $commande->adresse_livraison,
                'notes' => $commande->notes,
                'items' => $commande->items,
                'remise_globale' => $commande->remise_globale,
                'tva' => $commande->tva,
                'conditions' => $commande->conditions,
                'status' => $commande->status,
                'montant_ht' => $commande->montant_ht,
                'montant_tva' => $commande->montant_tva,
                'montant_ttc' => $commande->montant_ttc,
                'message' => 'Commande modifiée avec succès'
            ]);

        } catch (\Illuminate\Validation\ValidationException $e) {
            DB::rollBack();
            return response()->json([
                'success' => false,
                'message' => 'Erreur de validation',
                'errors' => $e->errors()
            ], 422);
        } catch (\Exception $e) {
            DB::rollBack();
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de la modification de la commande: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Valider une commande
     * Accessible par Patron et Admin
     */
    public function validateCommande($id)
    {
        try {
            $commande = CommandeEntreprise::findOrFail($id);

            if ($commande->status == 2) {
                return response()->json([
                    'success' => false,
                    'message' => 'Cette commande est déjà validée'
                ], 400);
            }

            if ($commande->status == 3) {
                return response()->json([
                    'success' => false,
                    'message' => 'Impossible de valider une commande rejetée'
                ], 400);
            }

            if ($commande->status == 4) {
                return response()->json([
                    'success' => false,
                    'message' => 'Impossible de valider une commande déjà livrée'
                ], 400);
            }

            $commande->update([
                'status' => 2,
                'date_validation' => now(),
            ]);

            $commande->load(['client', 'commercial', 'items']);

            // Format de réponse compatible avec Flutter
            return response()->json([
                'success' => true,
                'id' => $commande->id,
                'reference' => $commande->reference,
                'numero_commande' => $commande->reference,
                'client_id' => $commande->client_id,
                'cliennt_id' => $commande->client_id, // Pour compatibilité Flutter
                'user_id' => $commande->user_id,
                'date_creation' => $commande->date_creation->toIso8601String(),
                'date_commande' => $commande->date_creation->toIso8601String(),
                'date_validation' => $commande->date_validation?->toIso8601String(),
                'date_livraison_prevue' => $commande->date_livraison_prevue?->toIso8601String(),
                'adresse_livraison' => $commande->adresse_livraison,
                'notes' => $commande->notes,
                'description' => $commande->notes,
                'items' => $commande->items->map(function ($item) {
                    return [
                        'id' => $item->id,
                        'designation' => $item->designation,
                        'unite' => $item->unite,
                        'quantite' => $item->quantite,
                        'prix_unitaire' => $item->prix_unitaire,
                        'description' => $item->description,
                        'date_livraison' => $item->date_livraison?->toIso8601String(),
                    ];
                }),
                'remise_globale' => $commande->remise_globale,
                'tva' => $commande->tva,
                'conditions' => $commande->conditions,
                'conditions_paiement' => $commande->conditions,
                'status' => $commande->status,
                'commentaire' => $commande->commentaire_rejet,
                'numero_facture' => $commande->numero_facture,
                'est_facture' => $commande->est_facture ? 1 : 0,
                'est_livre' => $commande->est_livre ? 1 : 0,
                'montant_ht' => $commande->montant_ht,
                'montant_tva' => $commande->montant_tva,
                'montant_ttc' => $commande->montant_ttc,
                'status_text' => $commande->status_text,
                'client' => $commande->client,
                'commercial' => $commande->commercial,
                'message' => 'Commande validée avec succès'
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de la validation: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Rejeter une commande
     * Accessible par Patron et Admin
     */
    public function rejectCommande(Request $request, $id)
    {
        try {
            $request->validate([
                'commentaire_rejet' => 'required|string',
            ]);

            $commande = CommandeEntreprise::findOrFail($id);

            if ($commande->status == 3) {
                return response()->json([
                    'success' => false,
                    'message' => 'Cette commande est déjà rejetée'
                ], 400);
            }

            if ($commande->status == 4) {
                return response()->json([
                    'success' => false,
                    'message' => 'Impossible de rejeter une commande livrée'
                ], 400);
            }

            $commande->update([
                'status' => 3,
                'commentaire_rejet' => $request->commentaire_rejet,
            ]);

            $commande->load(['client', 'commercial', 'items']);

            // Format de réponse compatible avec Flutter
            return response()->json([
                'success' => true,
                'id' => $commande->id,
                'reference' => $commande->reference,
                'numero_commande' => $commande->reference,
                'client_id' => $commande->client_id,
                'cliennt_id' => $commande->client_id, // Pour compatibilité Flutter
                'user_id' => $commande->user_id,
                'date_creation' => $commande->date_creation->toIso8601String(),
                'date_commande' => $commande->date_creation->toIso8601String(),
                'date_validation' => $commande->date_validation?->toIso8601String(),
                'date_livraison_prevue' => $commande->date_livraison_prevue?->toIso8601String(),
                'adresse_livraison' => $commande->adresse_livraison,
                'notes' => $commande->notes,
                'description' => $commande->notes,
                'items' => $commande->items->map(function ($item) {
                    return [
                        'id' => $item->id,
                        'designation' => $item->designation,
                        'unite' => $item->unite,
                        'quantite' => $item->quantite,
                        'prix_unitaire' => $item->prix_unitaire,
                        'description' => $item->description,
                        'date_livraison' => $item->date_livraison?->toIso8601String(),
                    ];
                }),
                'remise_globale' => $commande->remise_globale,
                'tva' => $commande->tva,
                'conditions' => $commande->conditions,
                'conditions_paiement' => $commande->conditions,
                'status' => $commande->status,
                'commentaire' => $commande->commentaire_rejet,
                'commentaire_rejet' => $commande->commentaire_rejet,
                'numero_facture' => $commande->numero_facture,
                'est_facture' => $commande->est_facture ? 1 : 0,
                'est_livre' => $commande->est_livre ? 1 : 0,
                'montant_ht' => $commande->montant_ht,
                'montant_tva' => $commande->montant_tva,
                'montant_ttc' => $commande->montant_ttc,
                'status_text' => $commande->status_text,
                'client' => $commande->client,
                'commercial' => $commande->commercial,
                'message' => 'Commande rejetée avec succès'
            ]);

        } catch (\Illuminate\Validation\ValidationException $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur de validation',
                'errors' => $e->errors()
            ], 422);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors du rejet: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Marquer une commande comme livrée
     */
    public function markAsDelivered($id)
    {
        try {
            $commande = CommandeEntreprise::findOrFail($id);

            if ($commande->status != 2) {
                return response()->json([
                    'success' => false,
                    'message' => 'Seules les commandes validées peuvent être marquées comme livrées'
                ], 400);
            }

            $commande->update([
                'status' => 4,
                'est_livre' => true,
            ]);

            $commande->load(['client', 'commercial', 'items']);

            return response()->json([
                'success' => true,
                'commande' => $commande,
                'message' => 'Commande marquée comme livrée avec succès'
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de la mise à jour: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Marquer une commande comme facturée
     */
    public function markAsInvoiced(Request $request, $id)
    {
        try {
            $request->validate([
                'numero_facture' => 'nullable|string',
            ]);

            $commande = CommandeEntreprise::findOrFail($id);

            $commande->update([
                'est_facture' => true,
                'numero_facture' => $request->numero_facture,
            ]);

            $commande->load(['client', 'commercial', 'items']);

            return response()->json([
                'success' => true,
                'commande' => $commande,
                'message' => 'Commande marquée comme facturée avec succès'
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de la mise à jour: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Supprimer une commande
     */
    public function destroy($id)
    {
        try {
            $commande = CommandeEntreprise::findOrFail($id);

            // Vérifier que la commande peut être supprimée
            if ($commande->status != 1) {
                return response()->json([
                    'success' => false,
                    'message' => 'Impossible de supprimer une commande validée, rejetée ou livrée'
                ], 400);
            }

            $commande->delete();

            return response()->json([
                'success' => true,
                'message' => 'Commande supprimée avec succès'
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de la suppression: ' . $e->getMessage()
            ], 500);
        }
    }
}
