<?php

namespace App\Http\Controllers;

use App\Models\Bordereau;
use App\Models\BordereauItem;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;

class BordereauController extends Controller
{
    // Récupérer tous les bordereaux (avec filtre status facultatif)
    public function index(Request $request)
    {
        $status = $request->query('status'); // facultatif
        $query = Bordereau::with('items', 'client', 'user');

        if ($status !== null) {
            $query->where('status', $status);
        }

        $bordereaux = $query->get();
        return response()->json($bordereaux);
    }

    // Créer un bordereau (toujours status=1 : soumis)
    public function store(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'reference' => 'required|unique:bordereaux,reference',
            'client_id' => 'required|exists:clients,id',
            'user_id' => 'required|exists:users,id',
            'date_creation' => 'required|date',
            'items' => 'required|array|min:1',
            'items.*.designation' => 'required|string',
            'items.*.unite' => 'required|string',
            'items.*.quantite' => 'required|integer|min:1',
            'items.*.prix_unitaire' => 'required|numeric|min:0',
        ]);

        if ($validator->fails()) {
            return response()->json(['errors'=>$validator->errors()], 422);
        }

        $bordereau = Bordereau::create([
            'reference' => $request->reference,
            'client_id' => $request->client_id,
            'user_id' => $request->user_id,
            'date_creation' => $request->date_creation,
            'notes' => $request->notes,
            'remise_globale' => $request->remise_globale,
            'tva' => $request->tva ?? 20,
            'conditions' => $request->conditions,
            'status' => 1, // soumis au patron
        ]);

        foreach ($request->items as $item) {
            BordereauItem::create([
                'bordereau_id' => $bordereau->id,
                'designation' => $item['designation'],
                'unite' => $item['unite'],
                'quantite' => $item['quantite'],
                'prix_unitaire' => $item['prix_unitaire'],
                'description' => $item['description'] ?? null,
            ]);
        }

        return response()->json($bordereau->load('items'), 201);
    }

    // Récupérer un bordereau
    public function show($id)
    {
        $bordereau = Bordereau::with('items', 'client', 'user')->findOrFail($id);
        return response()->json($bordereau);
    }

    // Mettre à jour un bordereau (modification tant que status != 2)
    public function update(Request $request, $id)
    {
        $bordereau = Bordereau::findOrFail($id);

        if ($bordereau->status == 2) { // validé
            return response()->json(['message' => 'Impossible de modifier un bordereau validé'], 403);
        }

        $bordereau->update($request->only([
            'notes', 'remise_globale', 'tva', 'conditions', 'status', 'commentaire_rejet'
        ]));

        // Mise à jour des items si fournis
        if ($request->has('items')) {
            $bordereau->items()->delete(); // supprimer anciens items
            foreach ($request->items as $item) {
                BordereauItem::create([
                    'bordereau_id' => $bordereau->id,
                    'designation' => $item['designation'],
                    'unite' => $item['unite'],
                    'quantite' => $item['quantite'],
                    'prix_unitaire' => $item['prix_unitaire'],
                    'description' => $item['description'] ?? null,
                ]);
            }
        }

        return response()->json($bordereau->load('items'));
    }

    // Supprimer un bordereau (seulement si status != 2)
    public function destroy($id)
    {
        $bordereau = Bordereau::findOrFail($id);

        if ($bordereau->status == 2) {
            return response()->json(['message' => 'Impossible de supprimer un bordereau validé'], 403);
        }

        $bordereau->delete();
        return response()->json(['message' => 'Bordereau supprimé']);
    }

    // Valider ou rejeter (seulement par le patron)
    public function validateBordereau(Request $request, $id)
    {
        $bordereau = Bordereau::findOrFail($id);
        $action = $request->input('action'); // 'valider' ou 'rejeter'
        $commentaire = $request->input('commentaire');

        if ($action === 'valider') {
            $bordereau->update([
                'status' => 2,
                'date_validation' => now(),
                'commentaire' => null
            ]);
        } elseif ($action === 'rejeter') {
            $bordereau->update([
                'status' => 3,
                'commentaire' => $commentaire
            ]);
        } else {
            return response()->json(['message' => 'Action invalide'], 422);
        }

        return response()->json($bordereau->load('items'));
    }
}
