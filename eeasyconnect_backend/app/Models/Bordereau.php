<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Bordereau extends Model
{
    use HasFactory;

    protected $fillable = [
        'reference',
        'client_id',
        'user_id',
        'date_creation',
        'date_validation',
        'notes',
        'remise_globale',
        'tva',
        'conditions',
        'status',
        'commentaire',
    ];

    protected $casts = [
        'date_creation' => 'date',
        'date_validation' => 'date',
    ];

    public function client() {
        return $this->belongsTo(Client::class);
    }

    public function commercial() {
        return $this->belongsTo(User::class, 'user_id');
    }

    public function items() {
        return $this->hasMany(BordereauItem::class);
    }
}

