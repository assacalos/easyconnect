<?php

namespace App\Http\Controllers\API;

use App\Http\Controllers\API\Controller;
use App\Traits\SendsNotifications;
use Illuminate\Http\Request;
use App\Models\Devis;
use App\Models\DevisItem;
use App\Models\Client;
use App\Models\User;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;

class DevisController extends Controller
{
    use SendsNotifications;
    /**
     * Liste des devis avec filtres par rôle et statut
     */
    public function index(Request $request)
    {
        try {
            $user = $request->user();
            $status = $request->query('status');
            $client_id = $request->query('client_id');
            $date_from = $request->query('date_from');
            $date_to = $request->query('date_to');

            $query = Devis::with(['client', 'commercial', 'items']);

            // Filtre par statut
            if ($status !== null) {
                $query->where('status', $status);
            }

            // Filtre par client
            if ($client_id) {
                $query->where('client_id', $client_id);
            }

            // Filtre par date
            if ($date_from) {
                $query->where('date_creation', '>=', $date_from);
            }
            if ($date_to) {
                $query->where('date_creation', '<=', $date_to);
            }

            // Filtre par rôle : commercial ne voit que ses devis
            if ($user->role == 2) { // Commercial
                $query->where('user_id', $user->id);
            }

            $devis = $query->orderBy('created_at', 'desc')->get();

            return response()->json([
                'success' => true,
                'data' => $devis,
                'count' => $devis->count()
            ], 200);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de la récupération des devis: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Créer un nouveau devis
     */
    public function store(Request $request)
    {
        try {
            $validated = $request->validate([
                'client_id' => 'required|exists:clients,id',
                'date_validite' => 'nullable|date|after:today',
                'notes' => 'nullable|string',
                'remise_globale' => 'nullable|numeric|min:0',
                'tva' => 'nullable|numeric|min:0|max:100',
                'conditions' => 'nullable|string',
                'commentaire' => 'nullable|string',
                'items' => 'required|array|min:1',
                'items.*.designation' => 'required|string',
                'items.*.quantite' => 'required|integer|min:1',
                'items.*.prix_unitaire' => 'required|numeric|min:0'
            ]);

            DB::beginTransaction();

            // Génération de la référence
            $reference = 'DEV-' . date('Y') . '-' . str_pad(Devis::count() + 1, 4, '0', STR_PAD_LEFT);

            $devis = Devis::create([
                'client_id' => $validated['client_id'],
                'reference' => $reference,
                'date_creation' => now()->toDateString(),
                'date_validite' => $validated['date_validite'],
                'notes' => $validated['notes'],
                'status' => 1, // Brouillon
                'remise_globale' => $validated['remise_globale'] ?? 0,
                'tva' => $validated['tva'] ?? 0,
                'conditions' => $validated['conditions'],
                'commentaire' => $validated['commentaire'],
                'user_id' => $request->user()->id
            ]);

            // Création des items
            foreach ($validated['items'] as $item) {
                DevisItem::create([
                    'devis_id' => $devis->id,
                    'designation' => $item['designation'],
                    'quantite' => $item['quantite'],
                    'prix_unitaire' => $item['prix_unitaire']
                ]);
            }

            DB::commit();

            return response()->json([
                'success' => true,
                'message' => 'Devis créé avec succès',
                'data' => $devis->load(['client', 'commercial', 'items'])
            ], 201);

        } catch (\Exception $e) {
            DB::rollback();
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de la création du devis: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Afficher un devis spécifique
     */
    public function show($id)
    {
        try {
            $devis = Devis::with(['client', 'commercial', 'items'])->findOrFail($id);
            
            return response()->json([
                'success' => true,
                'data' => $devis
            ], 200);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Devis non trouvé: ' . $e->getMessage()
            ], 404);
        }
    }

    /**
     * Modifier un devis (uniquement si brouillon)
     */
    public function update(Request $request, $id)
    {
        try {
            $devis = Devis::findOrFail($id);

            // Vérifier que le devis est en brouillon
            if ($devis->status != 0) {
                return response()->json([
                    'success' => false,
                    'message' => 'Modification interdite, devis déjà envoyé'
                ], 403);
            }

            $validated = $request->validate([
                'client_id' => 'required|exists:clients,id',
                'date_validite' => 'nullable|date|after:today',
                'notes' => 'nullable|string',
                'remise_globale' => 'nullable|numeric|min:0',
                'tva' => 'nullable|numeric|min:0|max:100',
                'conditions' => 'nullable|string',
                'commentaire' => 'nullable|string',
                'items' => 'required|array|min:1',
                'items.*.designation' => 'required|string',
                'items.*.quantite' => 'required|integer|min:1',
                'items.*.prix_unitaire' => 'required|numeric|min:0'
            ]);

            DB::beginTransaction();

            $devis->update([
                'client_id' => $validated['client_id'],
                'date_validite' => $validated['date_validite'],
                'notes' => $validated['notes'],
                'remise_globale' => $validated['remise_globale'] ?? 0,
                'tva' => $validated['tva'] ?? 0,
                'conditions' => $validated['conditions'],
                'commentaire' => $validated['commentaire']
            ]);

            // Supprimer les anciens items et créer les nouveaux
            $devis->items()->delete();
            foreach ($validated['items'] as $item) {
                DevisItem::create([
                    'devis_id' => $devis->id,
                    'designation' => $item['designation'],
                    'quantite' => $item['quantite'],
                    'prix_unitaire' => $item['prix_unitaire']
                ]);
            }

            DB::commit();

            return response()->json([
                'success' => true,
                'message' => 'Devis modifié avec succès',
                'data' => $devis->load(['client', 'commercial', 'items'])
            ], 200);

        } catch (\Exception $e) {
            DB::rollback();
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de la modification du devis: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Supprimer un devis (uniquement si brouillon)
     */
    public function destroy($id)
    {
        try {
            $devis = Devis::findOrFail($id);

            // Vérifier que le devis est en brouillon
            if ($devis->status != 0) {
                return response()->json([
                    'success' => false,
                    'message' => 'Suppression interdite, devis déjà envoyé'
                ], 403);
            }

            $devis->delete();

            return response()->json([
                'success' => true,
                'message' => 'Devis supprimé avec succès'
            ], 200);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de la suppression du devis: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Envoyer un devis (changer le statut à "envoyé")
     */
    public function send($id)
    {
        try {
            $devis = Devis::findOrFail($id);

            if ($devis->status != 0) {
                return response()->json([
                    'success' => false,
                    'message' => 'Devis déjà envoyé'
                ], 403);
            }

            $devis->update(['status' => 1]); // Envoyé

            // Notifier le patron
            $patron = User::where('role', 6)->first();
            if ($patron) {
                $this->createNotification([
                    'user_id' => $patron->id,
                    'title' => 'Soumission Devis',
                    'message' => "Devis #{$devis->reference} a été soumis pour validation",
                    'type' => 'info',
                    'entity_type' => 'devis',
                    'entity_id' => $devis->id,
                    'action_route' => "/devis/{$devis->id}",
                ]);
            }

            return response()->json([
                'success' => true,
                'message' => 'Devis envoyé avec succès',
                'data' => $devis
            ], 200);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de l\'envoi du devis: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Accepter un devis
     */
    public function accept($id) {
        try {
            $devis = Devis::findOrFail($id);
            
            // Vérifier que le devis est envoyé (status = 1)
            if ($devis->status != 1) {
                return response()->json([
                    'success' => false,
                    'message' => 'Seuls les devis envoyés peuvent être acceptés'
                ], 403);
            }

            $devis->status = 2; // Accepté/Validé
            $devis->save();
            
            // Notifier l'auteur du devis
            if ($devis->commercial_id) {
                $this->createNotification([
                    'user_id' => $devis->commercial_id,
                    'title' => 'Validation Devis',
                    'message' => "Devis #{$devis->reference} a été validé",
                    'type' => 'success',
                    'entity_type' => 'devis',
                    'entity_id' => $devis->id,
                    'action_route' => "/devis/{$devis->id}",
                ]);
            }
            
            return response()->json([
                'success' => true,
                'message' => 'Devis accepté avec succès',
                'data' => $devis->load(['client', 'commercial', 'items'])
            ], 200);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de l\'acceptation: ' . $e->getMessage()
            ], 500);
        }
    }
    
    /**
     * Valider un devis (méthode pour les patrons) - alias de accept
     */
    public function validateDevis($id) {
        return $this->accept($id);
    }

    /**
     * Refuser un devis
     */
    public function reject(Request $request, $id)
    {
        try {
            $validated = $request->validate([
                'commentaire' => 'required|string'
            ]);

            $devis = Devis::findOrFail($id);

            if ($devis->status != 1) {
                return response()->json([
                    'success' => false,
                    'message' => 'Devis non envoyé'
                ], 403);
            }

            $devis->update([
                'status' => 3, // Refusé
                'commentaire' => $validated['commentaire']
            ]);

            // Notifier l'auteur du devis
            if ($devis->commercial_id) {
                $this->createNotification([
                    'user_id' => $devis->commercial_id,
                    'title' => 'Rejet Devis',
                    'message' => "Devis #{$devis->reference} a été rejeté. Raison: {$validated['commentaire']}",
                    'type' => 'error',
                    'entity_type' => 'devis',
                    'entity_id' => $devis->id,
                    'action_route' => "/devis/{$devis->id}",
                    'metadata' => ['reason' => $validated['commentaire']],
                ]);
            }

            return response()->json([
                'success' => true,
                'message' => 'Devis refusé avec succès',
                'data' => $devis
            ], 200);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors du refus du devis: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Calculer les totaux d'un devis
     */
    public function calculateTotals($id)
    {
        try {
            $devis = Devis::with('items')->findOrFail($id);
            
            $sous_total = 0;

            foreach ($devis->items as $item) {
                $prix_item = $item->quantite * $item->prix_unitaire;
                $sous_total += $prix_item;
            }

            $remise_globale = $sous_total * ($devis->remise_globale / 100);
            $total_ht = $sous_total - $remise_globale;
            $tva = $total_ht * ($devis->tva / 100);
            $total_ttc = $total_ht + $tva;

            return response()->json([
                'success' => true,
                'data' => [
                    'sous_total' => round($sous_total, 2),
                    'remise_globale' => round($remise_globale, 2),
                    'total_ht' => round($total_ht, 2),
                    'tva' => round($tva, 2),
                    'total_ttc' => round($total_ttc, 2)
                ]
            ], 200);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors du calcul: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Dupliquer un devis
     */
    public function duplicate($id)
    {
        try {
            $originalDevis = Devis::with('items')->findOrFail($id);

            DB::beginTransaction();

            // Génération d'une nouvelle référence
            $reference = 'DEV-' . date('Y') . '-' . str_pad(Devis::count() + 1, 4, '0', STR_PAD_LEFT);

            $newDevis = Devis::create([
                'client_id' => $originalDevis->client_id,
                'reference' => $reference,
                'date_creation' => now()->toDateString(),
                'date_validite' => $originalDevis->date_validite,
                'notes' => $originalDevis->notes,
                'status' => 0, // Brouillon
                'remise_globale' => $originalDevis->remise_globale,
                'tva' => $originalDevis->tva,
                'conditions' => $originalDevis->conditions,
                'commentaire' => $originalDevis->commentaire,
                'user_id' => $originalDevis->user_id
            ]);

            // Dupliquer les items
            foreach ($originalDevis->items as $item) {
                DevisItem::create([
                    'devis_id' => $newDevis->id,
                    'designation' => $item->designation,
                    'quantite' => $item->quantite,
                    'prix_unitaire' => $item->prix_unitaire
                ]);
            }

            DB::commit();

            return response()->json([
                'success' => true,
                'message' => 'Devis dupliqué avec succès',
                'data' => $newDevis->load(['client', 'commercial', 'items'])
            ], 201);

        } catch (\Exception $e) {
            DB::rollback();
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de la duplication: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Rapports et statistiques des devis
     */
    public function reports(Request $request)
    {
        try {
            $date_from = $request->query('date_from');
            $date_to = $request->query('date_to');
            $user_id = $request->query('user_id');

            $query = Devis::query();

            if ($date_from) {
                $query->where('date_creation', '>=', $date_from);
            }
            if ($date_to) {
                $query->where('date_creation', '<=', $date_to);
            }
            if ($user_id) {
                $query->where('user_id', $user_id);
            }

            $devis = $query->get();

            $stats = [
                'total_devis' => $devis->count(),
                'brouillons' => $devis->where('status', 0)->count(),
                'envoyes' => $devis->where('status', 1)->count(),
                'acceptes' => $devis->where('status', 2)->count(),
                'refuses' => $devis->where('status', 3)->count(),
                'taux_acceptation' => $devis->where('status', 1)->count() > 0 
                    ? round(($devis->where('status', 2)->count() / $devis->where('status', 1)->count()) * 100, 2) 
                    : 0
            ];

            return response()->json([
                'success' => true,
                'data' => $stats
            ], 200);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de la génération des rapports: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Devis par client
     */
    public function byClient($client_id)
    {
        try {
            $devis = Devis::with(['client', 'commercial', 'items'])
                ->where('client_id', $client_id)
                ->orderBy('created_at', 'desc')
                ->get();

            return response()->json([
                'success' => true,
                'data' => $devis
            ], 200);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de la récupération: ' . $e->getMessage()
            ], 500);
        }
    }
}
