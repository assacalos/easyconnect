<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Carbon\Carbon;

class Intervention extends Model
{
    use HasFactory;

    protected $fillable = [
        'type_id',
        'client_id',
        'user_id',
        'title',
        'description',
        'scheduled_date',
        'completed_date',
        'status',
        'cost'
    ];

    protected $casts = [
        'scheduled_date' => 'date',
        'completed_date' => 'date',
        'cost' => 'decimal:2'
    ];

    // Relations
    public function type()
    {
        return $this->belongsTo(InterventionType::class, 'type_id');
    }

    public function client()
    {
        return $this->belongsTo(Client::class);
    }

    public function user()
    {
        return $this->belongsTo(User::class);
    }

    public function reports()
    {
        return $this->hasMany(InterventionReport::class);
    }

    // Scopes
    public function scopeEnAttente($query)
    {
        return $query->where('status', 'en_attente');
    }

    public function scopeValide($query)
    {
        return $query->where('status', 'valide');
    }

    public function scopeRejete($query)
    {
        return $query->where('status', 'rejete');
    }

    public function scopeByType($query, $typeId)
    {
        return $query->where('type_id', $typeId);
    }

    public function scopeByClient($query, $clientId)
    {
        return $query->where('client_id', $clientId);
    }

    public function scopeByUser($query, $userId)
    {
        return $query->where('user_id', $userId);
    }

    // Accesseurs
    public function getStatusLibelleAttribute()
    {
        $statuses = [
            'en_attente' => 'En attente',
            'valide' => 'Validé',
            'rejete' => 'Rejeté'
        ];

        return $statuses[$this->status] ?? $this->status;
    }

    public function getFormattedCostAttribute()
    {
        return $this->cost ? number_format($this->cost, 2, ',', ' ') . ' €' : 'N/A';
    }

    // Méthodes utilitaires
    public function canBeValidated()
    {
        return $this->status === 'en_attente';
    }

    public function canBeRejected()
    {
        return $this->status === 'en_attente';
    }

    public function validate($comment = null, $userId = null)
    {
        if ($this->canBeValidated()) {
            $this->update([
                'status' => 'valide',
                'completed_date' => now()->toDateString()
            ]);
            return true;
        }
        return false;
    }

    public function reject($reason, $comment = null, $userId = null)
    {
        if ($this->canBeRejected()) {
            $this->update([
                'status' => 'rejete'
            ]);
            return true;
        }
        return false;
    }

    // Méthodes statiques
    public static function getInterventionStats($startDate = null, $endDate = null)
    {
        $query = self::query();
        
        if ($startDate && $endDate) {
            $query->whereBetween('created_at', [$startDate, $endDate]);
        }

        $interventions = $query->get();
        
        return [
            'total_interventions' => $interventions->count(),
            'en_attente_interventions' => $interventions->where('status', 'en_attente')->count(),
            'valide_interventions' => $interventions->where('status', 'valide')->count(),
            'rejete_interventions' => $interventions->where('status', 'rejete')->count(),
            'total_cost' => $interventions->sum('cost'),
            'interventions_by_month' => $interventions->groupBy(function ($intervention) {
                return $intervention->created_at->format('Y-m');
            })->map->count()
        ];
    }

    public static function getInterventionsByStatus($status)
    {
        return self::where('status', $status)->with(['type', 'client', 'user'])->get();
    }

    public static function getInterventionsByType($typeId)
    {
        return self::where('type_id', $typeId)->with(['type', 'client', 'user'])->get();
    }
}
