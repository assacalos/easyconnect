<?php

namespace App\Http\Controllers\API;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\Client;

class ClientController extends Controller
{
    // Liste des clients avec filtre rôle et statut
    public function index(Request $request)
    {
        $status = $request->query('status'); // optionnel
        $user = $request->user();             // utilisateur connecté
        $query = Client::query();

        if ($status !== null) {
            $query->where('status', $status);
        }

        // Si commercial → filtre uniquement ses clients
        if ($user->role == 2) { // 2 = commercial
            $query->where('user_id', $user->id);
        }

        return response()->json([
            'success' => true,
            'data' => $query->orderBy('created_at', 'desc')->get(),
        ], 200);
    }

    // Afficher un client
    public function show($id)
    {
        $client = Client::findOrFail($id);
        return response()->json([
            'success' => true,
            'data' => $client
        ], 200);
    }

    // Créer un client
    public function store(Request $request)
    {
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

        return response()->json([
            'success' => true,
            'data' => $client,
            'message' => 'Client créé avec succès'
        ], 201);
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

        return response()->json([
            'success' => true,
            'data' => $client,
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

        return response()->json([
            'success' => true,
            'data' => $client,
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

        return response()->json([
            'success' => true,
            'data' => $client,
            'message' => 'Client rejeté avec succès'
        ], 200);
    }

    // Statistiques des clients
    public function stats(Request $request)
    {
        $user = $request->user();
        $query = Client::query();

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

        return response()->json([
            'success' => true,
            'data' => [
                'total_clients' => $totalClients,
                'repartition_statuts' => $repartitionStatuts,
                'clients_par_mois' => $clientsParMois,
                'top_situations_geographiques' => $topSituations,
                'taux_validation' => $totalClients > 0 ? round(($clientsValides / $totalClients) * 100, 2) : 0,
                'taux_rejet' => $totalClients > 0 ? round(($clientsRejetes / $totalClients) * 100, 2) : 0
            ]
        ], 200);
    }
}
