<?php

namespace App\Http\Controllers\API;

use App\Http\Controllers\Controller;
use App\Models\Stock;
use App\Models\StockCategory;
use App\Models\StockMovement;
use App\Models\StockAlert;
use App\Models\StockOrder;
use App\Models\StockOrderItem;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class StockController extends Controller
{
    /**
     * Afficher la liste des stocks
     */
    public function index(Request $request)
    {
        try {
            $user = $request->user();
            $query = Stock::with(['creator', 'updater', 'movements', 'alerts']);

            // Filtrage par statut
            if ($request->has('status')) {
                $query->where('status', $request->status);
            }

            // Filtrage par catégorie
            if ($request->has('category')) {
                $query->where('category', $request->category);
            }

            // Filtrage par fournisseur
            if ($request->has('supplier')) {
                $query->where('supplier', $request->supplier);
            }

            // Filtrage par localisation
            if ($request->has('location')) {
                $query->where('location', 'like', '%' . $request->location . '%');
            }

            // Filtrage par marque
            if ($request->has('brand')) {
                $query->where('brand', $request->brand);
            }

            // Filtrage par SKU
            if ($request->has('sku')) {
                $query->where('sku', 'like', '%' . $request->sku . '%');
            }

            // Filtrage par code-barres
            if ($request->has('barcode')) {
                $query->where('barcode', 'like', '%' . $request->barcode . '%');
            }

            // Filtrage par stock faible
            if ($request->has('low_stock')) {
                if ($request->low_stock === 'true') {
                    $query->lowStock();
                }
            }

            // Filtrage par stock épuisé
            if ($request->has('out_of_stock')) {
                if ($request->out_of_stock === 'true') {
                    $query->outOfStock();
                }
            }

            // Filtrage par surstock
            if ($request->has('overstock')) {
                if ($request->overstock === 'true') {
                    $query->overstock();
                }
            }

            // Filtrage par réapprovisionnement nécessaire
            if ($request->has('needs_reorder')) {
                if ($request->needs_reorder === 'true') {
                    $query->needsReorder();
                }
            }

            // Pagination
            $perPage = $request->get('per_page', 15);
            $stocks = $query->orderBy('name')->paginate($perPage);

            // Transformer les données
            $stocks->getCollection()->transform(function ($stock) {
                return [
                    'id' => $stock->id,
                    'name' => $stock->name,
                    'description' => $stock->description,
                    'category' => $stock->category,
                    'sku' => $stock->sku,
                    'barcode' => $stock->barcode,
                    'brand' => $stock->brand,
                    'model' => $stock->model,
                    'unit' => $stock->unit,
                    'current_quantity' => $stock->current_quantity,
                    'minimum_quantity' => $stock->minimum_quantity,
                    'maximum_quantity' => $stock->maximum_quantity,
                    'reorder_point' => $stock->reorder_point,
                    'unit_cost' => $stock->unit_cost,
                    'selling_price' => $stock->selling_price,
                    'supplier' => $stock->supplier,
                    'location' => $stock->location,
                    'status' => $stock->status,
                    'status_libelle' => $stock->status_libelle,
                    'notes' => $stock->notes,
                    'specifications' => $stock->specifications,
                    'attachments' => $stock->attachments,
                    'created_by' => $stock->created_by,
                    'creator_name' => $stock->creator_name,
                    'updated_by' => $stock->updated_by,
                    'updater_name' => $stock->updater_name,
                    'formatted_current_quantity' => $stock->formatted_current_quantity,
                    'formatted_minimum_quantity' => $stock->formatted_minimum_quantity,
                    'formatted_maximum_quantity' => $stock->formatted_maximum_quantity,
                    'formatted_reorder_point' => $stock->formatted_reorder_point,
                    'formatted_unit_cost' => $stock->formatted_unit_cost,
                    'formatted_selling_price' => $stock->formatted_selling_price,
                    'stock_value' => $stock->stock_value,
                    'formatted_stock_value' => $stock->formatted_stock_value,
                    'is_low_stock' => $stock->is_low_stock,
                    'is_out_of_stock' => $stock->is_out_of_stock,
                    'is_overstock' => $stock->is_overstock,
                    'needs_reorder' => $stock->needs_reorder,
                    'movements' => $stock->movements->map(function ($movement) {
                        return [
                            'id' => $movement->id,
                            'type' => $movement->type,
                            'type_libelle' => $movement->type_libelle,
                            'reason' => $movement->reason,
                            'reason_libelle' => $movement->reason_libelle,
                            'quantity' => $movement->quantity,
                            'formatted_quantity' => $movement->formatted_quantity,
                            'unit_cost' => $movement->unit_cost,
                            'formatted_unit_cost' => $movement->formatted_unit_cost,
                            'total_cost' => $movement->total_cost,
                            'formatted_total_cost' => $movement->formatted_total_cost,
                            'reference' => $movement->reference,
                            'location_from' => $movement->location_from,
                            'location_to' => $movement->location_to,
                            'notes' => $movement->notes,
                            'creator_name' => $movement->creator_name,
                            'created_at' => $movement->created_at->format('Y-m-d H:i:s')
                        ];
                    }),
                    'alerts' => $stock->alerts->map(function ($alert) {
                        return [
                            'id' => $alert->id,
                            'type' => $alert->type,
                            'type_libelle' => $alert->type_libelle,
                            'priority' => $alert->priority,
                            'priority_libelle' => $alert->priority_libelle,
                            'status' => $alert->status,
                            'status_libelle' => $alert->status_libelle,
                            'message' => $alert->message,
                            'notes' => $alert->notes,
                            'triggered_at' => $alert->triggered_at->format('Y-m-d H:i:s'),
                            'acknowledged_at' => $alert->acknowledged_at?->format('Y-m-d H:i:s'),
                            'resolved_at' => $alert->resolved_at?->format('Y-m-d H:i:s'),
                            'acknowledged_by' => $alert->acknowledged_by,
                            'acknowledged_by_name' => $alert->acknowledged_by_name,
                            'resolved_by' => $alert->resolved_by,
                            'resolved_by_name' => $alert->resolved_by_name,
                            'duration' => $alert->duration,
                            'is_active' => $alert->is_active,
                            'is_acknowledged' => $alert->is_acknowledged,
                            'is_resolved' => $alert->is_resolved,
                            'is_dismissed' => $alert->is_dismissed
                        ];
                    }),
                    'created_at' => $stock->created_at->format('Y-m-d H:i:s'),
                    'updated_at' => $stock->updated_at->format('Y-m-d H:i:s')
                ];
            });

            return response()->json([
                'success' => true,
                'data' => $stocks,
                'message' => 'Liste des stocks récupérée avec succès'
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de la récupération des stocks: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Afficher un stock spécifique
     */
    public function show($id)
    {
        try {
            $stock = Stock::with(['creator', 'updater', 'movements', 'alerts'])->find($id);

            if (!$stock) {
                return response()->json([
                    'success' => false,
                    'message' => 'Stock non trouvé'
                ], 404);
            }

            return response()->json([
                'success' => true,
                'data' => $stock,
                'message' => 'Stock récupéré avec succès'
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de la récupération du stock: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Créer un nouveau stock
     */
    public function store(Request $request)
    {
        try {
            $validated = $request->validate([
                'name' => 'required|string|max:255',
                'description' => 'required|string',
                'category' => 'required|string|max:255',
                'sku' => 'required|string|max:255|unique:stocks,sku',
                'barcode' => 'nullable|string|max:255|unique:stocks,barcode',
                'brand' => 'nullable|string|max:255',
                'model' => 'nullable|string|max:255',
                'unit' => 'required|string|max:50',
                'current_quantity' => 'required|numeric|min:0',
                'minimum_quantity' => 'required|numeric|min:0',
                'maximum_quantity' => 'nullable|numeric|min:0',
                'reorder_point' => 'required|numeric|min:0',
                'unit_cost' => 'required|numeric|min:0',
                'selling_price' => 'nullable|numeric|min:0',
                'supplier' => 'nullable|string|max:255',
                'location' => 'nullable|string|max:255',
                'status' => 'required|in:active,inactive,discontinued',
                'notes' => 'nullable|string',
                'specifications' => 'nullable|array',
                'attachments' => 'nullable|array'
            ]);

            DB::beginTransaction();

            $stock = Stock::create([
                'name' => $validated['name'],
                'description' => $validated['description'],
                'category' => $validated['category'],
                'sku' => $validated['sku'],
                'barcode' => $validated['barcode'] ?? null,
                'brand' => $validated['brand'] ?? null,
                'model' => $validated['model'] ?? null,
                'unit' => $validated['unit'],
                'current_quantity' => $validated['current_quantity'],
                'minimum_quantity' => $validated['minimum_quantity'],
                'maximum_quantity' => $validated['maximum_quantity'] ?? null,
                'reorder_point' => $validated['reorder_point'],
                'unit_cost' => $validated['unit_cost'],
                'selling_price' => $validated['selling_price'] ?? null,
                'supplier' => $validated['supplier'] ?? null,
                'location' => $validated['location'] ?? null,
                'status' => $validated['status'],
                'notes' => $validated['notes'] ?? null,
                'specifications' => $validated['specifications'] ?? null,
                'attachments' => $validated['attachments'] ?? null,
                'created_by' => $request->user()->id
            ]);

            // Vérifier les alertes
            $stock->checkAlerts();

            DB::commit();

            return response()->json([
                'success' => true,
                'data' => $stock->load(['creator']),
                'message' => 'Stock créé avec succès'
            ], 201);

        } catch (\Exception $e) {
            DB::rollback();
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de la création du stock: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Mettre à jour un stock
     */
    public function update(Request $request, $id)
    {
        try {
            $stock = Stock::find($id);

            if (!$stock) {
                return response()->json([
                    'success' => false,
                    'message' => 'Stock non trouvé'
                ], 404);
            }

            $validated = $request->validate([
                'name' => 'sometimes|string|max:255',
                'description' => 'sometimes|string',
                'category' => 'sometimes|string|max:255',
                'sku' => 'sometimes|string|max:255|unique:stocks,sku,' . $id,
                'barcode' => 'nullable|string|max:255|unique:stocks,barcode,' . $id,
                'brand' => 'nullable|string|max:255',
                'model' => 'nullable|string|max:255',
                'unit' => 'sometimes|string|max:50',
                'minimum_quantity' => 'sometimes|numeric|min:0',
                'maximum_quantity' => 'nullable|numeric|min:0',
                'reorder_point' => 'sometimes|numeric|min:0',
                'unit_cost' => 'sometimes|numeric|min:0',
                'selling_price' => 'nullable|numeric|min:0',
                'supplier' => 'nullable|string|max:255',
                'location' => 'nullable|string|max:255',
                'status' => 'sometimes|in:active,inactive,discontinued',
                'notes' => 'nullable|string',
                'specifications' => 'nullable|array',
                'attachments' => 'nullable|array'
            ]);

            $stock->update(array_merge($validated, [
                'updated_by' => $request->user()->id
            ]));

            // Vérifier les alertes
            $stock->checkAlerts();

            return response()->json([
                'success' => true,
                'data' => $stock->load(['creator', 'updater']),
                'message' => 'Stock mis à jour avec succès'
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de la mise à jour du stock: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Supprimer un stock
     */
    public function destroy($id)
    {
        try {
            $stock = Stock::find($id);

            if (!$stock) {
                return response()->json([
                    'success' => false,
                    'message' => 'Stock non trouvé'
                ], 404);
            }

            $stock->delete();

            return response()->json([
                'success' => true,
                'message' => 'Stock supprimé avec succès'
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de la suppression du stock: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Ajouter du stock
     */
    public function addStock(Request $request, $id)
    {
        try {
            $stock = Stock::find($id);

            if (!$stock) {
                return response()->json([
                    'success' => false,
                    'message' => 'Stock non trouvé'
                ], 404);
            }

            $validated = $request->validate([
                'quantity' => 'required|numeric|min:0.001',
                'unit_cost' => 'nullable|numeric|min:0',
                'reason' => 'required|in:purchase,sale,transfer,adjustment,return,loss,damage,expired,other',
                'reference' => 'nullable|string|max:255',
                'notes' => 'nullable|string|max:1000'
            ]);

            $movement = $stock->addStock(
                $validated['quantity'],
                $validated['unit_cost'],
                $validated['reason'],
                $validated['reference'],
                $validated['notes'],
                $request->user()->id
            );

            return response()->json([
                'success' => true,
                'data' => $movement,
                'message' => 'Stock ajouté avec succès'
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de l\'ajout du stock: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Retirer du stock
     */
    public function removeStock(Request $request, $id)
    {
        try {
            $stock = Stock::find($id);

            if (!$stock) {
                return response()->json([
                    'success' => false,
                    'message' => 'Stock non trouvé'
                ], 404);
            }

            $validated = $request->validate([
                'quantity' => 'required|numeric|min:0.001',
                'reason' => 'required|in:purchase,sale,transfer,adjustment,return,loss,damage,expired,other',
                'reference' => 'nullable|string|max:255',
                'notes' => 'nullable|string|max:1000'
            ]);

            $movement = $stock->removeStock(
                $validated['quantity'],
                $validated['reason'],
                $validated['reference'],
                $validated['notes'],
                $request->user()->id
            );

            return response()->json([
                'success' => true,
                'data' => $movement,
                'message' => 'Stock retiré avec succès'
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors du retrait du stock: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Ajuster le stock
     */
    public function adjustStock(Request $request, $id)
    {
        try {
            $stock = Stock::find($id);

            if (!$stock) {
                return response()->json([
                    'success' => false,
                    'message' => 'Stock non trouvé'
                ], 404);
            }

            $validated = $request->validate([
                'new_quantity' => 'required|numeric|min:0',
                'reason' => 'required|in:purchase,sale,transfer,adjustment,return,loss,damage,expired,other',
                'notes' => 'nullable|string|max:1000'
            ]);

            $movement = $stock->adjustStock(
                $validated['new_quantity'],
                $validated['reason'],
                $validated['notes'],
                $request->user()->id
            );

            return response()->json([
                'success' => true,
                'data' => $movement,
                'message' => 'Stock ajusté avec succès'
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de l\'ajustement du stock: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Transférer du stock
     */
    public function transferStock(Request $request, $id)
    {
        try {
            $stock = Stock::find($id);

            if (!$stock) {
                return response()->json([
                    'success' => false,
                    'message' => 'Stock non trouvé'
                ], 404);
            }

            $validated = $request->validate([
                'quantity' => 'required|numeric|min:0.001',
                'location_to' => 'required|string|max:255',
                'notes' => 'nullable|string|max:1000'
            ]);

            $movement = $stock->transferStock(
                $validated['quantity'],
                $validated['location_to'],
                $validated['notes'],
                $request->user()->id
            );

            return response()->json([
                'success' => true,
                'data' => $movement,
                'message' => 'Stock transféré avec succès'
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors du transfert du stock: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Statistiques des stocks
     */
    public function statistics(Request $request)
    {
        try {
            $stats = Stock::getStockStats();

            return response()->json([
                'success' => true,
                'data' => $stats,
                'message' => 'Statistiques récupérées avec succès'
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de la récupération des statistiques: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Récupérer les catégories de stocks
     */
    public function categories()
    {
        try {
            $categories = StockCategory::getActiveCategories();

            return response()->json([
                'success' => true,
                'data' => $categories,
                'message' => 'Catégories récupérées avec succès'
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de la récupération des catégories: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Récupérer les stocks faibles
     */
    public function lowStock()
    {
        try {
            $stocks = Stock::getLowStockItems();

            return response()->json([
                'success' => true,
                'data' => $stocks,
                'message' => 'Stocks faibles récupérés avec succès'
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de la récupération des stocks faibles: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Récupérer les stocks épuisés
     */
    public function outOfStock()
    {
        try {
            $stocks = Stock::getOutOfStockItems();

            return response()->json([
                'success' => true,
                'data' => $stocks,
                'message' => 'Stocks épuisés récupérés avec succès'
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de la récupération des stocks épuisés: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Récupérer les surstocks
     */
    public function overstock()
    {
        try {
            $stocks = Stock::getOverstockItems();

            return response()->json([
                'success' => true,
                'data' => $stocks,
                'message' => 'Surstocks récupérés avec succès'
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de la récupération des surstocks: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Récupérer les stocks nécessitant un réapprovisionnement
     */
    public function needsReorder()
    {
        try {
            $stocks = Stock::getItemsNeedingReorder();

            return response()->json([
                'success' => true,
                'data' => $stocks,
                'message' => 'Stocks nécessitant un réapprovisionnement récupérés avec succès'
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de la récupération des stocks nécessitant un réapprovisionnement: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Rejeter un stock avec commentaire
     */
    public function rejeter(Request $request, $id)
    {
        try {
            $stock = Stock::find($id);

            if (!$stock) {
                return response()->json([
                    'success' => false,
                    'message' => 'Stock non trouvé'
                ], 404);
            }

            $validated = $request->validate([
                'commentaire' => 'required|string|max:1000'
            ]);

            DB::beginTransaction();

            // Mettre à jour le statut du stock à 'rejete'
            $stock->update([
                'status' => 'rejete',
                'commentaire' => $validated['commentaire'],
                'updated_by' => $request->user()->id
            ]);

            DB::commit();

            return response()->json([
                'success' => true,
                'data' => $stock->load(['creator', 'updater']),
                'message' => 'Stock rejeté avec succès'
            ]);

        } catch (\Exception $e) {
            DB::rollback();
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors du rejet du stock: ' . $e->getMessage()
            ], 500);
        }
    }
}
