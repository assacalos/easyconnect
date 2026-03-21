<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class CatalogArticle extends Model
{
    protected $fillable = [
        'name',
        'description',
        'price',
        'image_url',
        'category',
        'is_offer',
        'sort_order',
        'is_active',
    ];

    protected $casts = [
        'price' => 'decimal:2',
        'is_offer' => 'boolean',
        'is_active' => 'boolean',
    ];

    public function scopeActive($query)
    {
        return $query->where('is_active', true);
    }

    public function scopeOffers($query)
    {
        return $query->where('is_offer', true);
    }
}
