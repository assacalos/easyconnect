<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Fournisseur extends Model
{
    use HasFactory;

    protected $fillable = [
        'nom',
        'email',
        'telephone',
        'adresse',
        'ville',
        'pays',
        'contact_principal',
        'description',
        'statut',
        'note_evaluation',
        'commentaires'
    ];

    protected $casts = [
        'note_evaluation' => 'decimal:2'
    ];

    // Relations
    public function bonsDeCommande()
    {
        return $this->hasMany(BonDeCommande::class);
    }

    // Scopes
    public function scopeActifs($query)
    {
        return $query->where('statut', 'actif');
    }

    public function scopeInactifs($query)
    {
        return $query->where('statut', 'inactif');
    }

    public function scopeSuspendus($query)
    {
        return $query->where('statut', 'suspendu');
    }

    // Accesseurs
    public function getStatutLibelleAttribute()
    {
        $statuts = [
            'actif' => 'Actif',
            'inactif' => 'Inactif',
            'suspendu' => 'Suspendu'
        ];

        return $statuts[$this->statut] ?? $this->statut;
    }

    public function getNoteFormateeAttribute()
    {
        return $this->note_evaluation ? number_format($this->note_evaluation, 1) . '/5' : 'Non évalué';
    }
}
