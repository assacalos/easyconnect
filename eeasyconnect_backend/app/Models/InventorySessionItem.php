<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class InventorySessionItem extends Model
{
    use HasFactory;

    protected $fillable = [
        'inventory_session_id',
        'stock_id',
        'quantity_theoretical',
        'quantity_counted',
    ];

    protected $casts = [
        'quantity_theoretical' => 'decimal:3',
        'quantity_counted' => 'decimal:3',
    ];

    public function inventorySession()
    {
        return $this->belongsTo(InventorySession::class);
    }

    public function stock()
    {
        return $this->belongsTo(Stock::class);
    }

    /** Écart = compté - théorique */
    public function getQuantityVarianceAttribute()
    {
        if ($this->quantity_counted === null) {
            return null;
        }
        return (float) $this->quantity_counted - (float) $this->quantity_theoretical;
    }

    public function hasVariance(): bool
    {
        $v = $this->quantity_variance;
        return $v !== null && $v != 0;
    }
}
