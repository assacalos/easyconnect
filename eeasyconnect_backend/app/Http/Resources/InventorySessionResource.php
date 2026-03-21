<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class InventorySessionResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'date' => $this->date->format('Y-m-d'),
            'depot' => $this->depot,
            'status' => $this->status,
            'created_by' => $this->created_by,
            'closed_by' => $this->closed_by,
            'closed_at' => $this->closed_at?->format('Y-m-d H:i:s'),
            'created_at' => $this->created_at?->format('Y-m-d H:i:s'),
            'updated_at' => $this->updated_at?->format('Y-m-d H:i:s'),
            'items' => InventorySessionItemResource::collection($this->whenLoaded('items')),
            'items_count' => $this->when(isset($this->items_count), $this->items_count),
            'variances_count' => $this->when(isset($this->variances_count), $this->variances_count),
        ];
    }
}
