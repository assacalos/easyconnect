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
            'data' => $query->get(),
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
        $request->validate([
            'commentaire' => 'required|string|max:255',
        ]);

        $client = Client::findOrFail($id);
        $client->status = 2; // rejeté
        $client->commentaire_rejet = $request->commentaire;
        $client->save();

        return response()->json([
            'success' => true,
            'data' => $client,
            'message' => 'Client rejeté avec succès'
        ], 200);
    }
}
