<?php

namespace App\Http\Controllers\API;

use App\Http\Controllers\Controller;
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
        $query = Bordereau::with('items', 'client', 'user', 'devis');

        if ($status !== null) {
            $query->where('status', $status);
        }

        $bordereaux = $query->orderBy('created_at', 'desc')->get();
        return response()->json($bordereaux);
    }

    // Créer un bordereau (toujours status=1 : soumis)
    public function store(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'reference' => 'required|unique:bordereaus,reference',
            'client_id' => 'required|exists:clients,id',
            'devis_id' => 'nullable|exists:devis,id',
            'user_id' => 'required|exists:users,id',
            'date_creation' => 'required|date',
            'items' => 'required|array|min:1',
            'items.*.designation' => 'required|string',
            'items.*.quantite' => 'required|integer|min:1',
            'items.*.prix_unitaire' => 'required|numeric|min:0',
        ]);

        if ($validator->fails()) {
            return response()->json(['errors'=>$validator->errors()], 422);
        }

        $bordereau = Bordereau::create([
            'reference' => $request->reference,
            'client_id' => $request->client_id,
            'devis_id' => $request->devis_id,
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
            'notes', 'remise_globale', 'tva', 'conditions', 'status', 'commentaire'
        ]));

        // Mise à jour des items si fournis
        if ($request->has('items')) {
            $bordereau->items()->delete(); // supprimer anciens items
            foreach ($request->items as $item) {
                BordereauItem::create([
                    'bordereau_id' => $bordereau->id,
                    'designation' => $item['designation'],
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

    // ✅ NOUVELLE MÉTHODE : Valider un bordereau
    public function validateBordereau(Request $request, $id)
    {
        try {
            $bordereau = Bordereau::findOrFail($id);
            
            // Vérifier que le bordereau est soumis (status = 1)
            if ($bordereau->status != 1) {
                return response()->json([
                    'success' => false,
                    'message' => 'Seuls les bordereaux soumis peuvent être validés'
                ], 403);
            }

            $bordereau->update([
                'status' => 2, // validé
                'date_validation' => now()->toDateString(),
                'commentaire' => null // effacer tout commentaire de rejet
            ]);

            // Recharger le bordereau avec ses relations
            $bordereau->refresh();
            $bordereau->load(['items', 'client', 'user']);
            
            // Charger devis seulement s'il existe
            if ($bordereau->devis_id) {
                $bordereau->load('devis');
            }

            return response()->json([
                'success' => true,
                'message' => 'Bordereau validé avec succès',
                'data' => $bordereau
            ], 200);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de la validation: ' . $e->getMessage()
            ], 500);
        }
    }

    // ✅ NOUVELLE MÉTHODE : Rejeter un bordereau
    public function reject(Request $request, $id)
    {
        try {
            $bordereau = Bordereau::findOrFail($id);
            
            // Vérifier que le bordereau est soumis (status = 1)
            if ($bordereau->status != 1) {
                return response()->json([
                    'success' => false,
                    'message' => 'Seuls les bordereaux soumis peuvent être rejetés'
                ], 403);
            }

            $validator = Validator::make($request->all(), [
                'commentaire' => 'required|string|max:1000'
            ]);

            if ($validator->fails()) {
                return response()->json([
                    'success' => false,
                    'errors' => $validator->errors()
                ], 422);
            }

            $bordereau->update([
                'status' => 3, // rejeté
                'commentaire' => $request->commentaire
            ]);

            return response()->json([
                'success' => true,
                'message' => 'Bordereau rejeté avec succès',
                'data' => $bordereau->load(['items', 'client', 'user', 'devis'])
            ], 200);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors du rejet: ' . $e->getMessage()
            ], 500);
        }
    }
}