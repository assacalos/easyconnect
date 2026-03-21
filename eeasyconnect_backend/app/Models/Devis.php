<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Devis extends Model
{
    use HasFactory;

    /**
     * Génère la prochaine référence unique pour l'année en cours.
     * Format: DEV-YYYY-NNNN. Utilise le max des numéros existants + 1
     * pour éviter les conflits après suppression de devis.
     */
    public static function generateNextReference(): string
    {
        $year = date('Y');
        $prefix = 'DEV-' . $year . '-';

        $maxNumber = static::where('reference', 'like', $prefix . '%')
            ->get()
            ->map(function ($devis) use ($prefix) {
                $suffix = substr($devis->reference, strlen($prefix));
                return is_numeric($suffix) ? (int) $suffix : 0;
            })
            ->filter(fn ($n) => $n > 0)
            ->max();

        $next = ($maxNumber ?? 0) + 1;

        return $prefix . str_pad((string) $next, 4, '0', STR_PAD_LEFT);
    }

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
        'titre',
        'delai_livraison',
        'garantie',
        'user_id',
        'paid_at',
    ];

    protected $casts = [
        'date_creation' => 'date',
        'date_validite' => 'date',
        'paid_at' => 'datetime',
        'remise_globale' => 'decimal:2',
        'tva' => 'decimal:2',
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

    // Accesseurs pour les totaux (calculés une seule fois, mis en cache)
    protected $totalsCache = null;

    public function getSousTotalAttribute()
    {
        if ($this->totalsCache === null) {
            $this->calculateTotals();
        }
        return $this->totalsCache['sous_total'];
    }

    public function getRemiseGlobaleAmountAttribute()
    {
        if ($this->totalsCache === null) {
            $this->calculateTotals();
        }
        return $this->totalsCache['remise_globale_amount'];
    }

    public function getTotalHtAttribute()
    {
        if ($this->totalsCache === null) {
            $this->calculateTotals();
        }
        return $this->totalsCache['total_ht'];
    }

    public function getTvaAmountAttribute()
    {
        if ($this->totalsCache === null) {
            $this->calculateTotals();
        }
        return $this->totalsCache['tva_amount'];
    }

    public function getTotalTtcAttribute()
    {
        if ($this->totalsCache === null) {
            $this->calculateTotals();
        }
        return $this->totalsCache['total_ttc'];
    }

    protected function calculateTotals()
    {
        $sous_total = 0;
        
        // Charger les items si pas déjà chargés
        if (!$this->relationLoaded('items')) {
            $this->load('items');
        }
        
        if ($this->items && $this->items->count() > 0) {
            $sous_total = $this->items->sum(function ($item) {
                return ($item->quantite ?? 0) * ($item->prix_unitaire ?? 0);
            });
        }
        
        $remise_globale_amount = $sous_total * (($this->remise_globale ?? 0) / 100);
        $total_ht = $sous_total - $remise_globale_amount;
        $tva_amount = $total_ht * (($this->tva ?? 0) / 100);
        $total_ttc = $total_ht + $tva_amount;

        $this->totalsCache = [
            'sous_total' => $sous_total,
            'remise_globale_amount' => $remise_globale_amount,
            'total_ht' => $total_ht,
            'tva_amount' => $tva_amount,
            'total_ttc' => $total_ttc,
        ];
    }
}
