<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Client extends Model
{
  
    use HasFactory;
    protected $fillable = [
        'user_id',       // commercial créateur du client
        'portal_user_id', // utilisateur (rôle 7) pour l'accès portail client
        'nom',
        'prenom',
        'email',
        'contact',
        'adresse',
        'situation_geographique',
        'nom_entreprise',
        'numero_contribuable',
        'commentaire',
        'status',
    ];

    /** Commercial qui a créé / gère ce client */
    public function user()
    {
        return $this->belongsTo(User::class, 'user_id');
    }

    /** Compte utilisateur (rôle 7) lié pour l'accès au portail client */
    public function portalUser()
    {
        return $this->belongsTo(User::class, 'portal_user_id');
    }
}
