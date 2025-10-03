<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Client extends Model
{
  
    use HasFactory;
    protected $fillable = [
        'user_id',
        'nom',
        'prenom',
        'email',
        'contact',
        'adresse',
        'situation_geographique',
        'nom_entreprise',
        'commentaire',
        'status',
    ];
    
    public function user()
    {
        return $this->belongsTo(User::class);
    }
}
