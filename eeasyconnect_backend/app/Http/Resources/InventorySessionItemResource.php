<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class InventorySessionItemResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        $counted = $this->quantity_counted !== null ? (float) $this->quantity_counted : null;
        $theoretical = (float) $this->quantity_theoretical;
        $variance = $counted !== null ? $counted - $theoretical : null;

        return [
            'id' => $this->id,
            'inventory_session_id' => $this->inventory_session_id,
            'stock_id' => $this->stock_id,
            'quantity_theoretical' => $theoretical,
            'quantity_counted' => $counted,
            'quantity_variance' => $variance,
            'stock' => $this->whenLoaded('stock', function () {
                return [
                    'id' => $this->stock->id,
                    'name' => $this->stock->name,
                    'sku' => $this->stock->sku,
                    'category' => $this->stock->category,
                    'unit' => $this->stock->unit ?? 'pièce',
                ];
            }),
        ];
    }
}
