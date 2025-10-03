<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Devis extends Model
{
    use HasFactory;

    protected $fillable = [
        'client_id',
        'reference',
        'date_creation',
        'date_validite',
        'notes',
        'status',
        'remise_globale',
        'tva',
        'conditions',
        'commentaire',
        'user_id',
    ];

    public function client() {
        return $this->belongsTo(Client::class);
    }

    public function commercial() {
        return $this->belongsTo(User::class, 'user_id');
    }

    public function items() {
        return $this->hasMany(DevisItem::class);
    }

    public function bordereaux() {
        return $this->hasMany(Bordereau::class);
    }
}
