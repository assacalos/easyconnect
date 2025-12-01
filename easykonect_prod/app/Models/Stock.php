<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Carbon\Carbon;

class Stock extends Model
{
    use HasFactory;

    protected $fillable = [
        'name',
        'description',
        'category',
        'sku',
        'barcode',
        'brand',
        'model',
        'unit',
        'current_quantity',
        'minimum_quantity',
        'maximum_quantity',
        'reorder_point',
        'unit_cost',
        'selling_price',
        'supplier',
        'location',
        'status',
        'notes',
        'specifications',
        'attachments',
        'created_by',
        'updated_by'
    ];

    protected $casts = [
        'current_quantity' => 'decimal:3',
        'minimum_quantity' => 'decimal:3',
        'maximum_quantity' => 'decimal:3',
        'reorder_point' => 'decimal:3',
        'unit_cost' => 'decimal:2',
        'selling_price' => 'decimal:2',
        'specifications' => 'array',
        'attachments' => 'array'
    ];

    // Relations
    public function creator()
    {
        return $this->belongsTo(User::class, 'created_by');
    }

    public function updater()
    {
        return $this->belongsTo(User::class, 'updated_by');
    }

    public function movements()
    {
        return $this->hasMany(StockMovement::class);
    }

    public function alerts()
    {
        return $this->hasMany(StockAlert::class);
    }

    public function orderItems()
    {
        return $this->hasMany(StockOrderItem::class);
    }

    public function categoryInfo()
    {
        return $this->belongsTo(StockCategory::class, 'category', 'name');
    }

    // Scopes
    public function scopeActive($query)
    {
        return $query->where('status', 'active');
    }

    public function scopeInactive($query)
    {
        return $query->where('status', 'inactive');
    }

    public function scopeDiscontinued($query)
    {
        return $query->where('status', 'discontinued');
    }

    public function scopeByCategory($query, $category)
    {
        return $query->where('category', $category);
    }

    public function scopeBySupplier($query, $supplier)
    {
        return $query->where('supplier', $supplier);
    }

    public function scopeByLocation($query, $location)
    {
        return $query->where('location', $location);
    }

    public function scopeByBrand($query, $brand)
    {
        return $query->where('brand', $brand);
    }

    public function scopeLowStock($query)
    {
        return $query->whereRaw('current_quantity <= minimum_quantity');
    }

    public function scopeOutOfStock($query)
    {
        return $query->where('current_quantity', 0);
    }

    public function scopeOverstock($query)
    {
        return $query->whereRaw('current_quantity > maximum_quantity');
    }

    public function scopeNeedsReorder($query)
    {
        return $query->whereRaw('current_quantity <= reorder_point');
    }

    // Accesseurs
    public function getStatusLibelleAttribute()
    {
        $statuses = [
            'active' => 'Actif',
            'inactive' => 'Inactif',
            'discontinued' => 'Discontinué'
        ];

        return $statuses[$this->status] ?? $this->status;
    }

    public function getCreatorNameAttribute()
    {
        return $this->creator ? $this->creator->prenom . ' ' . $this->creator->nom : 'N/A';
    }

    public function getUpdaterNameAttribute()
    {
        return $this->updater ? $this->updater->prenom . ' ' . $this->updater->nom : 'N/A';
    }

    public function getFormattedUnitCostAttribute()
    {
        return $this->unit_cost ? number_format($this->unit_cost, 2, ',', ' ') . ' €' : 'N/A';
    }

    public function getFormattedSellingPriceAttribute()
    {
        return $this->selling_price ? number_format($this->selling_price, 2, ',', ' ') . ' €' : 'N/A';
    }

    public function getFormattedCurrentQuantityAttribute()
    {
        return number_format($this->current_quantity, 3, ',', ' ') . ' ' . $this->unit;
    }

    public function getFormattedMinimumQuantityAttribute()
    {
        return number_format($this->minimum_quantity, 3, ',', ' ') . ' ' . $this->unit;
    }

    public function getFormattedMaximumQuantityAttribute()
    {
        return $this->maximum_quantity ? number_format($this->maximum_quantity, 3, ',', ' ') . ' ' . $this->unit : 'N/A';
    }

    public function getFormattedReorderPointAttribute()
    {
        return number_format($this->reorder_point, 3, ',', ' ') . ' ' . $this->unit;
    }

    public function getIsLowStockAttribute()
    {
        return $this->current_quantity <= $this->minimum_quantity;
    }

    public function getIsOutOfStockAttribute()
    {
        return $this->current_quantity == 0;
    }

    public function getIsOverstockAttribute()
    {
        return $this->maximum_quantity && $this->current_quantity > $this->maximum_quantity;
    }

    public function getNeedsReorderAttribute()
    {
        return $this->current_quantity <= $this->reorder_point;
    }

    public function getStockValueAttribute()
    {
        return $this->current_quantity * $this->unit_cost;
    }

    public function getFormattedStockValueAttribute()
    {
        return number_format($this->stock_value, 2, ',', ' ') . ' €';
    }

    // Méthodes utilitaires
    public function addStock($quantity, $unitCost = null, $reason = 'purchase', $reference = null, $notes = null, $createdBy = null)
    {
        $unitCost = $unitCost ?? $this->unit_cost;
        $totalCost = $quantity * $unitCost;

        // Créer le mouvement
        $movement = StockMovement::create([
            'stock_id' => $this->id,
            'type' => 'in',
            'reason' => $reason,
            'quantity' => $quantity,
            'unit_cost' => $unitCost,
            'total_cost' => $totalCost,
            'reference' => $reference,
            'notes' => $notes,
            'created_by' => $createdBy ?? auth()->id()
        ]);

        // Mettre à jour la quantité
        $this->update([
            'current_quantity' => $this->current_quantity + $quantity,
            'unit_cost' => $unitCost,
            'updated_by' => $createdBy ?? auth()->id()
        ]);

        // Vérifier les alertes
        $this->checkAlerts();

        return $movement;
    }

    public function removeStock($quantity, $reason = 'sale', $reference = null, $notes = null, $createdBy = null)
    {
        if ($this->current_quantity < $quantity) {
            throw new \Exception('Quantité insuffisante en stock');
        }

        // Créer le mouvement
        $movement = StockMovement::create([
            'stock_id' => $this->id,
            'type' => 'out',
            'reason' => $reason,
            'quantity' => $quantity,
            'unit_cost' => $this->unit_cost,
            'total_cost' => $quantity * $this->unit_cost,
            'reference' => $reference,
            'notes' => $notes,
            'created_by' => $createdBy ?? auth()->id()
        ]);

        // Mettre à jour la quantité
        $this->update([
            'current_quantity' => $this->current_quantity - $quantity,
            'updated_by' => $createdBy ?? auth()->id()
        ]);

        // Vérifier les alertes
        $this->checkAlerts();

        return $movement;
    }

    public function adjustStock($newQuantity, $reason = 'adjustment', $notes = null, $createdBy = null)
    {
        $difference = $newQuantity - $this->current_quantity;
        $type = $difference > 0 ? 'in' : 'out';
        $quantity = abs($difference);

        // Créer le mouvement
        $movement = StockMovement::create([
            'stock_id' => $this->id,
            'type' => $type,
            'reason' => $reason,
            'quantity' => $quantity,
            'unit_cost' => $this->unit_cost,
            'total_cost' => $quantity * $this->unit_cost,
            'notes' => $notes,
            'created_by' => $createdBy ?? auth()->id()
        ]);

        // Mettre à jour la quantité
        $this->update([
            'current_quantity' => $newQuantity,
            'updated_by' => $createdBy ?? auth()->id()
        ]);

        // Vérifier les alertes
        $this->checkAlerts();

        return $movement;
    }

    public function transferStock($quantity, $locationTo, $notes = null, $createdBy = null)
    {
        if ($this->current_quantity < $quantity) {
            throw new \Exception('Quantité insuffisante en stock');
        }

        // Créer le mouvement
        $movement = StockMovement::create([
            'stock_id' => $this->id,
            'type' => 'transfer',
            'reason' => 'transfer',
            'quantity' => $quantity,
            'unit_cost' => $this->unit_cost,
            'total_cost' => $quantity * $this->unit_cost,
            'location_from' => $this->location,
            'location_to' => $locationTo,
            'notes' => $notes,
            'created_by' => $createdBy ?? auth()->id()
        ]);

        // Mettre à jour la quantité
        $this->update([
            'current_quantity' => $this->current_quantity - $quantity,
            'updated_by' => $createdBy ?? auth()->id()
        ]);

        // Vérifier les alertes
        $this->checkAlerts();

        return $movement;
    }

    public function checkAlerts()
    {
        // Supprimer les alertes existantes
        $this->alerts()->where('status', 'active')->delete();

        // Vérifier les nouvelles alertes
        if ($this->current_quantity == 0) {
            $this->createAlert('out_of_stock', 'high', 'Stock épuisé');
        } elseif ($this->current_quantity <= $this->minimum_quantity) {
            $this->createAlert('low_stock', 'medium', 'Stock faible');
        } elseif ($this->maximum_quantity && $this->current_quantity > $this->maximum_quantity) {
            $this->createAlert('overstock', 'low', 'Stock excédentaire');
        }

        if ($this->current_quantity <= $this->reorder_point) {
            $this->createAlert('reorder', 'high', 'Réapprovisionnement nécessaire');
        }
    }

    public function createAlert($type, $priority, $message)
    {
        return StockAlert::create([
            'stock_id' => $this->id,
            'type' => $type,
            'priority' => $priority,
            'message' => $message,
            'triggered_at' => now()
        ]);
    }

    // Méthodes statiques
    public static function getStockStats()
    {
        $stocks = self::all();
        
        return [
            'total_stocks' => $stocks->count(),
            'active_stocks' => $stocks->where('status', 'active')->count(),
            'inactive_stocks' => $stocks->where('status', 'inactive')->count(),
            'discontinued_stocks' => $stocks->where('status', 'discontinued')->count(),
            'low_stock' => $stocks->filter(function ($stock) {
                return $stock->is_low_stock;
            })->count(),
            'out_of_stock' => $stocks->filter(function ($stock) {
                return $stock->is_out_of_stock;
            })->count(),
            'overstock' => $stocks->filter(function ($stock) {
                return $stock->is_overstock;
            })->count(),
            'needs_reorder' => $stocks->filter(function ($stock) {
                return $stock->needs_reorder;
            })->count(),
            'total_value' => $stocks->sum('stock_value'),
            'average_value' => $stocks->avg('stock_value') ?? 0,
            'stocks_by_category' => $stocks->groupBy('category')->map->count(),
            'stocks_by_status' => $stocks->groupBy('status')->map->count(),
            'stocks_by_supplier' => $stocks->groupBy('supplier')->map->count()
        ];
    }

    public static function getStocksByCategory($category)
    {
        return self::byCategory($category)->with(['creator', 'updater'])->get();
    }

    public static function getStocksBySupplier($supplier)
    {
        return self::bySupplier($supplier)->with(['creator', 'updater'])->get();
    }

    public static function getStocksByLocation($location)
    {
        return self::byLocation($location)->with(['creator', 'updater'])->get();
    }

    public static function getLowStockItems()
    {
        return self::lowStock()->with(['creator', 'updater'])->get();
    }

    public static function getOutOfStockItems()
    {
        return self::outOfStock()->with(['creator', 'updater'])->get();
    }

    public static function getOverstockItems()
    {
        return self::overstock()->with(['creator', 'updater'])->get();
    }

    public static function getItemsNeedingReorder()
    {
        return self::needsReorder()->with(['creator', 'updater'])->get();
    }
}
