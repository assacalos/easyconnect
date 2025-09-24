<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Carbon\Carbon;

class Notification extends Model
{
    use HasFactory;

    protected $fillable = [
        'user_id',
        'type',
        'titre',
        'message',
        'data',
        'statut',
        'priorite',
        'canal',
        'date_lecture',
        'date_expiration',
        'envoyee'
    ];

    protected $casts = [
        'data' => 'array',
        'date_lecture' => 'datetime',
        'date_expiration' => 'datetime',
        'envoyee' => 'boolean'
    ];

    /**
     * Relation avec l'utilisateur
     */
    public function user()
    {
        return $this->belongsTo(User::class);
    }

    /**
     * Obtenir le statut en français
     */
    public function getStatutLibelle()
    {
        $statuts = [
            'non_lue' => 'Non lue',
            'lue' => 'Lue',
            'archivee' => 'Archivée'
        ];

        return $statuts[$this->statut] ?? 'Inconnu';
    }

    /**
     * Obtenir la priorité en français
     */
    public function getPrioriteLibelle()
    {
        $priorites = [
            'basse' => 'Basse',
            'normale' => 'Normale',
            'haute' => 'Haute',
            'urgente' => 'Urgente'
        ];

        return $priorites[$this->priorite] ?? 'Normale';
    }

    /**
     * Obtenir le type en français
     */
    public function getTypeLibelle()
    {
        $types = [
            'pointage' => 'Pointage',
            'conge' => 'Congé',
            'evaluation' => 'Évaluation',
            'facture' => 'Facture',
            'paiement' => 'Paiement',
            'client' => 'Client',
            'systeme' => 'Système',
            'rapport' => 'Rapport'
        ];

        return $types[$this->type] ?? 'Autre';
    }

    /**
     * Vérifier si la notification est expirée
     */
    public function isExpiree()
    {
        return $this->date_expiration && $this->date_expiration < Carbon::now();
    }

    /**
     * Marquer comme lue
     */
    public function marquerCommeLue()
    {
        $this->update([
            'statut' => 'lue',
            'date_lecture' => Carbon::now()
        ]);
    }

    /**
     * Marquer comme archivée
     */
    public function archiver()
    {
        $this->update(['statut' => 'archivee']);
    }

    /**
     * Scope pour les notifications non lues
     */
    public function scopeNonLues($query)
    {
        return $query->where('statut', 'non_lue');
    }

    /**
     * Scope pour les notifications lues
     */
    public function scopeLues($query)
    {
        return $query->where('statut', 'lue');
    }

    /**
     * Scope pour les notifications d'un type
     */
    public function scopeDeType($query, $type)
    {
        return $query->where('type', $type);
    }

    /**
     * Scope pour les notifications d'une priorité
     */
    public function scopeDePriorite($query, $priorite)
    {
        return $query->where('priorite', $priorite);
    }

    /**
     * Scope pour les notifications urgentes
     */
    public function scopeUrgentes($query)
    {
        return $query->where('priorite', 'urgente');
    }

    /**
     * Scope pour les notifications d'un utilisateur
     */
    public function scopePourUtilisateur($query, $userId)
    {
        return $query->where('user_id', $userId);
    }

    /**
     * Scope pour les notifications non expirées
     */
    public function scopeNonExpirees($query)
    {
        return $query->where(function($q) {
            $q->whereNull('date_expiration')
              ->orWhere('date_expiration', '>', Carbon::now());
        });
    }

    /**
     * Scope pour les notifications récentes
     */
    public function scopeRecent($query, $jours = 7)
    {
        return $query->where('created_at', '>=', Carbon::now()->subDays($jours));
    }
}
