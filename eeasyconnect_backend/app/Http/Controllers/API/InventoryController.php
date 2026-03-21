<?php

namespace App\Http\Controllers\API;

use App\Http\Controllers\API\Controller;
use App\Http\Resources\InventorySessionResource;
use App\Models\InventorySession;
use App\Models\InventorySessionItem;
use App\Models\Stock;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\Rule;

class InventoryController extends Controller
{
    /**
     * Liste des sessions d'inventaire
     */
    public function index(Request $request)
    {
        $query = InventorySession::withCount('items')
            ->with('creator')
            ->orderByDesc('date')
            ->orderByDesc('created_at');

        if ($request->has('status') && $request->status !== 'all') {
            $query->where('status', $request->status);
        }

        $perPage = min((int) $request->get('per_page', 20), 100);
        $sessions = $query->paginate($perPage);

        return response()->json([
            'success' => true,
            'data' => InventorySessionResource::collection($sessions->items())->resolve(),
            'meta' => [
                'current_page' => $sessions->currentPage(),
                'last_page' => $sessions->lastPage(),
                'per_page' => $sessions->perPage(),
                'total' => $sessions->total(),
            ],
        ], 200, [], JSON_UNESCAPED_UNICODE);
    }

    /**
     * Créer une session d'inventaire (avec tous les articles du stock actuel)
     */
    public function store(Request $request)
    {
        $validated = $request->validate([
            'date' => 'required|date',
            'depot' => 'nullable|string|max:255',
        ]);

        $user = $request->user();
        $session = DB::transaction(function () use ($validated, $user) {
            $session = InventorySession::create([
                'date' => $validated['date'],
                'depot' => $validated['depot'] ?? null,
                'status' => InventorySession::STATUS_IN_PROGRESS,
                'created_by' => $user?->id,
            ]);

            $stocks = Stock::whereIn('status', ['valide', 'active', 'en_attente'])->get();
            foreach ($stocks as $stock) {
                $qty = $stock->current_quantity ?? $stock->quantity ?? 0;
                InventorySessionItem::create([
                    'inventory_session_id' => $session->id,
                    'stock_id' => $stock->id,
                    'quantity_theoretical' => $qty,
                    'quantity_counted' => null,
                ]);
            }

            return $session->load(['items.stock']);
        });

        return response()->json([
            'success' => true,
            'data' => new InventorySessionResource($session),
            'message' => 'Session d\'inventaire créée',
        ], 201, [], JSON_UNESCAPED_UNICODE);
    }

    /**
     * Détail d'une session (avec lignes et écarts)
     */
    public function show($id)
    {
        $session = InventorySession::with(['items.stock', 'creator'])->find($id);

        if (!$session) {
            return response()->json([
                'success' => false,
                'message' => 'Session d\'inventaire non trouvée',
            ], 404);
        }

        return response()->json([
            'success' => true,
            'data' => new InventorySessionResource($session),
        ], 200, [], JSON_UNESCAPED_UNICODE);
    }

    /**
     * Mettre à jour la session (date, dépôt) ou les quantités comptées
     */
    public function update(Request $request, $id)
    {
        $session = InventorySession::find($id);

        if (!$session) {
            return response()->json([
                'success' => false,
                'message' => 'Session d\'inventaire non trouvée',
            ], 404);
        }

        if ($session->isClosed()) {
            return response()->json([
                'success' => false,
                'message' => 'Session déjà clôturée',
            ], 422);
        }

        if ($request->has('date') || $request->has('depot')) {
            $request->validate([
                'date' => 'sometimes|date',
                'depot' => 'nullable|string|max:255',
            ]);
            $session->update($request->only(['date', 'depot']));
        }

        if ($request->has('items') && is_array($request->items)) {
            foreach ($request->items as $row) {
                $itemId = $row['id'] ?? $row['inventory_session_item_id'] ?? null;
                $counted = isset($row['quantity_counted']) ? (float) $row['quantity_counted'] : null;
                if ($itemId) {
                    $item = InventorySessionItem::where('inventory_session_id', $session->id)
                        ->where('id', $itemId)
                        ->first();
                    if ($item) {
                        $item->update(['quantity_counted' => $counted]);
                    }
                }
            }
        }

        $session->load(['items.stock']);
        return response()->json([
            'success' => true,
            'data' => new InventorySessionResource($session),
            'message' => 'Session mise à jour',
        ], 200, [], JSON_UNESCAPED_UNICODE);
    }

    /**
     * Mettre à jour la quantité comptée d'une ligne
     */
    public function updateItem(Request $request, $sessionId, $itemId)
    {
        $item = InventorySessionItem::where('inventory_session_id', $sessionId)->where('id', $itemId)->first();

        if (!$item) {
            return response()->json([
                'success' => false,
                'message' => 'Ligne non trouvée',
            ], 404);
        }

        if ($item->inventorySession->isClosed()) {
            return response()->json([
                'success' => false,
                'message' => 'Session déjà clôturée',
            ], 422);
        }

        $validated = $request->validate([
            'quantity_counted' => 'required|numeric|min:0',
        ]);

        $item->update(['quantity_counted' => $validated['quantity_counted']]);
        $item->load('stock');

        return response()->json([
            'success' => true,
            'data' => new \App\Http\Resources\InventorySessionItemResource($item),
            'message' => 'Quantité comptée enregistrée',
        ], 200, [], JSON_UNESCAPED_UNICODE);
    }

    /**
     * Clôturer l'inventaire : applique les écarts (ajustements de stock) et marque la session clôturée
     */
    public function close(Request $request, $id)
    {
        $session = InventorySession::with('items.stock')->find($id);

        if (!$session) {
            return response()->json([
                'success' => false,
                'message' => 'Session d\'inventaire non trouvée',
            ], 404);
        }

        if ($session->isClosed()) {
            return response()->json([
                'success' => false,
                'message' => 'Session déjà clôturée',
            ], 422);
        }

        $userId = $request->user()?->id;

        DB::transaction(function () use ($session, $userId) {
            foreach ($session->items as $item) {
                $counted = $item->quantity_counted;
                if ($counted === null) {
                    continue;
                }
                $theoretical = (float) $item->quantity_theoretical;
                $counted = (float) $counted;
                if ($counted == $theoretical) {
                    continue;
                }
                $stock = $item->stock;
                if (!$stock) {
                    continue;
                }
                $stock->adjustStock(
                    $counted,
                    'inventaire',
                    'Clôture inventaire session #' . $session->id . ' (' . $session->date->format('Y-m-d') . ')',
                    $userId
                );
            }

            $session->update([
                'status' => InventorySession::STATUS_CLOSED,
                'closed_by' => $userId,
                'closed_at' => now(),
            ]);
        });

        $session->load(['items.stock']);
        return response()->json([
            'success' => true,
            'data' => new InventorySessionResource($session),
            'message' => 'Inventaire clôturé ; quantités mises à jour.',
        ], 200, [], JSON_UNESCAPED_UNICODE);
    }

    /**
     * Supprimer une session (uniquement si en_cours et sans impact stock)
     */
    public function destroy($id)
    {
        $session = InventorySession::find($id);

        if (!$session) {
            return response()->json([
                'success' => false,
                'message' => 'Session d\'inventaire non trouvée',
            ], 404);
        }

        if ($session->isClosed()) {
            return response()->json([
                'success' => false,
                'message' => 'Impossible de supprimer une session clôturée',
            ], 422);
        }

        $session->delete();
        return response()->json([
            'success' => true,
            'message' => 'Session supprimée',
        ], 200, [], JSON_UNESCAPED_UNICODE);
    }
}
