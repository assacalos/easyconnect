<?php

namespace App\Http\Controllers\API;

use App\Http\Controllers\API\Controller;
use App\Traits\SendsNotifications;
use App\Traits\CachesData;
use Illuminate\Http\Request;
use App\Models\Client;
use App\Http\Resources\ClientResource;
use Carbon\Carbon;

class ClientController extends Controller
{
    use CachesData, SendsNotifications;
    // Liste des clients avec filtre rôle et statut
    // Accessible aux commerciaux, comptables, techniciens, admin et patron
    // Seuls les commerciaux (role 2) voient uniquement leurs propres clients
    // Les autres rôles (comptable role 3, technicien role 5, etc.) voient tous les clients
    public function index(Request $request)
    {
        try {
            $status = $request->query('status'); // optionnel
            $user = $request->user();             // utilisateur connecté
            
            if (!$user) {
                return response()->json([
                    'success' => false,
                    'message' => 'Utilisateur non authentifié'
                ], 401);
            }
            
            $query = Client::with(['user']);

            // Filtre par statut
            if ($status !== null) {
                $query->where('status', $status);
            } else {
                // Par défaut, ne retourner que les clients validés (status = 1) pour faciliter la sélection
                // Sauf si un filtre explicite est demandé
                if (!$request->has('status') && !$request->has('include_pending')) {
                    $query->where('status', 1); // Seulement les clients validés
                }
            }

            // Filtre par recherche (nom, email, entreprise)
            if ($request->has('search')) {
                $search = $request->query('search');
                $query->where(function($q) use ($search) {
                    $q->where('nom', 'like', '%' . $search . '%')
                      ->orWhere('prenom', 'like', '%' . $search . '%')
                      ->orWhere('email', 'like', '%' . $search . '%')
                      ->orWhere('nom_entreprise', 'like', '%' . $search . '%')
                      ->orWhere('contact', 'like', '%' . $search . '%');
                });
            }

            // Si commercial (role 2) → filtre uniquement ses clients
            // Les comptables (role 3), techniciens (role 5) et autres voient tous les clients
            if ($user->role == 2) { // 2 = commercial
                $query->where('user_id', $user->id);
            }

            $perPage = $request->get('per_page', 15);
            $clients = $query->orderBy('nom')->orderBy('prenom')->paginate($perPage);

            return response()->json([
                'success' => true,
                'data' => ClientResource::collection($clients->items()),
                'pagination' => [
                    'current_page' => $clients->currentPage(),
                    'last_page' => $clients->lastPage(),
                    'per_page' => $clients->perPage(),
                    'total' => $clients->total(),
                ],
                'message' => 'Liste des clients récupérée avec succès'
            ], 200);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de la récupération des clients: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Obtenir le libellé du statut
     */
    private function getStatusLabel($status)
    {
        $statuses = [
            0 => 'En attente',
            1 => 'Validé',
            2 => 'Rejeté'
        ];

        return $statuses[$status] ?? 'Inconnu';
    }

    // Afficher un client
    public function show($id)
    {
        $client = Client::with(['user'])->findOrFail($id);
        return response()->json([
            'success' => true,
            'data' => new ClientResource($client)
        ], 200);
    }

    // Créer un client
    public function store(Request $request)
    {
        try {
            $validated = $request->validate([
            'nom' => 'required|string|max:255',
            'prenom' => 'required|string|max:255',
            'email' => 'required|string|email|max:255|unique:clients',
            'contact' => 'required|string|max:255',
            'adresse' => 'required|string|max:255',
            'nom_entreprise' => 'required|string|max:255',
            'situation_geographique' => 'required|string|max:255',
            'status' => 'nullable|integer|in:0,1,2'
        ]);

        $client = new Client($validated);
        $client->user_id = $request->user()->id;
        $client->status = $validated['status'] ?? 0; // toujours "en attente" par défaut
        $client->save();

        $client->load(['user']);

            return response()->json([
                'success' => true,
                'data' => new ClientResource($client),
                'message' => 'Client créé avec succès'
            ], 201);
        } catch (\Illuminate\Validation\ValidationException $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur de validation',
                'errors' => $e->errors()
            ], 422);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de la création du client: ' . $e->getMessage()
            ], 500);
        }
    }

    // Mettre à jour un client
    public function update(Request $request, $id)
    {
        $client = Client::findOrFail($id);

        // Validation
        $request->validate([
            'nom' => 'required|string|max:255',
            'prenom' => 'required|string|max:255',
            'email' => 'required|email|unique:clients,email,' . $client->id,
            'contact' => 'required|string|max:255',
            'adresse' => 'required|string|max:255',
            'nom_entreprise' => 'required|string|max:255',
            'situation_geographique' => 'required|string|max:255',
        ]);

        $client->update($request->all());
        $client->load(['user']);

        return response()->json([
            'success' => true,
            'data' => new ClientResource($client),
            'message' => 'Client mis à jour avec succès'
        ], 200);
    }

    // Supprimer un client
    public function destroy($id)
    {
        $client = Client::findOrFail($id);
        $client->delete();
        return response()->json([
            'success' => true,
            'message' => 'Client supprimé avec succès'
        ], 200);
    }

    // Valider un client (patron)
    public function approve($id)
    {
        $client = Client::findOrFail($id);
        $client->status = 1; // validé
        $client->save();
        $client->load(['user']);

        // Notifier l'auteur du client
        if ($client->user_id) {
            $clientName = $client->nom_entreprise ?? ($client->nom . ' ' . $client->prenom);
            $this->createNotification([
                'user_id' => $client->user_id,
                'title' => 'Validation Client',
                'message' => "Client {$clientName} a été validé",
                'type' => 'success',
                'entity_type' => 'client',
                'entity_id' => $client->id,
                'action_route' => "/clients/{$client->id}",
            ]);
        }

        return response()->json([
            'success' => true,
            'data' => new ClientResource($client),
            'message' => 'Client validé avec succès'
        ], 200);
    }

    // Rejeter un client (patron)
    public function reject(Request $request, $id)
    {
        $client = Client::findOrFail($id);
        $client->status = 2; // rejeté
        $client->commentaire = $request->commentaire;
        $client->save();
        $client->load(['user']);

        // Notifier l'auteur du client
        if ($client->user_id) {
            $reason = $request->commentaire ?? 'Rejeté';
            $clientName = $client->nom_entreprise ?? ($client->nom . ' ' . $client->prenom);
            $this->createNotification([
                'user_id' => $client->user_id,
                'title' => 'Rejet Client',
                'message' => "Client {$clientName} a été rejeté. Raison: {$reason}",
                'type' => 'error',
                'entity_type' => 'client',
                'entity_id' => $client->id,
                'action_route' => "/clients/{$client->id}",
                'metadata' => ['reason' => $reason],
            ]);
        }

        return response()->json([
            'success' => true,
            'data' => new ClientResource($client),
            'message' => 'Client rejeté avec succès'
        ], 200);
    }

    // Statistiques des clients
    public function stats(Request $request)
    {
        $user = $request->user();
        $dateKey = Carbon::now()->format('Y-m-d');
        $cacheKey = $user->role == 2 ? "client_stats:{$dateKey}:{$user->id}" : "client_stats:{$dateKey}";

        $data = $this->rememberDailyStats($cacheKey, $dateKey, function () use ($user) {
            $query = Client::with(['user']);

            // Si commercial → filtre uniquement ses clients
            if ($user->role == 2) { // 2 = commercial
                $query->where('user_id', $user->id);
            }

            $totalClients = $query->count();
            $clientsEnAttente = $query->where('status', 0)->count();
            $clientsValides = $query->where('status', 1)->count();
            $clientsRejetes = $query->where('status', 2)->count();

            // Statistiques par mois (derniers 12 mois)
            $clientsParMois = $query->selectRaw('DATE_FORMAT(created_at, "%Y-%m") as mois, COUNT(*) as total')
                ->where('created_at', '>=', now()->subMonths(12))
                ->groupBy('mois')
                ->orderBy('mois')
                ->get();

            // Top 5 des situations géographiques
            $topSituations = $query->selectRaw('situation_geographique, COUNT(*) as total')
                ->groupBy('situation_geographique')
                ->orderBy('total', 'desc')
                ->limit(5)
                ->get();

            // Répartition par statut
            $repartitionStatuts = [
                'en_attente' => $clientsEnAttente,
                'valides' => $clientsValides,
                'rejetes' => $clientsRejetes
            ];

            return [
                'total_clients' => $totalClients,
                'repartition_statuts' => $repartitionStatuts,
                'clients_par_mois' => $clientsParMois,
                'top_situations_geographiques' => $topSituations,
                'taux_validation' => $totalClients > 0 ? round(($clientsValides / $totalClients) * 100, 2) : 0,
                'taux_rejet' => $totalClients > 0 ? round(($clientsRejetes / $totalClients) * 100, 2) : 0
            ];
        });

        return response()->json([
            'success' => true,
            'data' => $data
        ], 200);
    }
}
