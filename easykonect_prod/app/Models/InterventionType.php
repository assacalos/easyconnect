<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class InterventionType extends Model
{
    use HasFactory;

    protected $fillable = [
        'name',
        'code',
        'description',
        'icon',
        'color',
        'is_active',
        'default_settings'
    ];

    protected $casts = [
        'is_active' => 'boolean',
        'default_settings' => 'array'
    ];

    // Scopes
    public function scopeActive($query)
    {
        return $query->where('is_active', true);
    }

    // Accesseurs
    public function getFormattedColorAttribute()
    {
        return $this->color ? '#' . ltrim($this->color, '#') : '#3B82F6';
    }

    // Méthodes utilitaires
    public function activate()
    {
        $this->update(['is_active' => true]);
    }

    public function deactivate()
    {
        $this->update(['is_active' => false]);
    }

    // Méthodes statiques
    public static function getActiveTypes()
    {
        return self::active()->orderBy('name')->get();
    }

    public static function getTypeByCode($code)
    {
        return self::where('code', $code)->active()->first();
    }
}
