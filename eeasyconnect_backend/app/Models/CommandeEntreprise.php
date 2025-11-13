<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class CommandeEntreprise extends Model
{
    use HasFactory;

    protected $table = 'commandes_entreprise';

    protected $fillable = [
        'reference',
        'client_id',
        'user_id',
        'date_creation',
        'date_validation',
        'date_livraison_prevue',
        'adresse_livraison',
        'notes',
        'remise_globale',
        'tva',
        'conditions',
        'status',
        'commentaire_rejet',
        'numero_facture',
        'est_facture',
        'est_livre',
    ];

    protected $casts = [
        'date_creation' => 'datetime',
        'date_validation' => 'datetime',
        'date_livraison_prevue' => 'datetime',
        'remise_globale' => 'decimal:2',
        'tva' => 'decimal:2',
        'status' => 'integer',
        'est_facture' => 'boolean',
        'est_livre' => 'boolean',
    ];

    // Relations
    public function client()
    {
        return $this->belongsTo(Client::class);
    }

    public function commercial()
    {
        return $this->belongsTo(User::class, 'user_id');
    }

    public function items()
    {
        return $this->hasMany(CommandeItem::class, 'commande_entreprise_id');
    }

    // Accesseurs
    public function getMontantHtAttribute()
    {
        $total = $this->items->sum(function ($item) {
            return $item->quantite * $item->prix_unitaire;
        });

        if ($this->remise_globale) {
            $total = $total * (1 - $this->remise_globale / 100);
        }

        return round($total, 2);
    }

    public function getMontantTvaAttribute()
    {
        return $this->tva ? round($this->montant_ht * ($this->tva / 100), 2) : 0;
    }

    public function getMontantTtcAttribute()
    {
        return round($this->montant_ht + $this->montant_tva, 2);
    }

    public function getStatusTextAttribute()
    {
        return match($this->status) {
            1 => 'En attente',
            2 => 'Validé',
            3 => 'Rejeté',
            4 => 'Livré',
            default => 'Inconnu',
        };
    }

    // Scopes
    public function scopeSoumis($query)
    {
        return $query->where('status', 1);
    }

    public function scopeValides($query)
    {
        return $query->where('status', 2);
    }

    public function scopeRejetes($query)
    {
        return $query->where('status', 3);
    }

    public function scopeLives($query)
    {
        return $query->where('status', 4);
    }
}
