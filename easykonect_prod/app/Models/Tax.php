<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Carbon\Carbon;

class Tax extends Model
{
    use HasFactory;

    protected $fillable = [
        'tax_category_id',
        'comptable_id',
        'reference',
        'period',
        'period_start',
        'period_end',
        'due_date',
        'base_amount',
        'tax_rate',
        'tax_amount',
        'total_amount',
        'status',
        'description',
        'notes',
        'calculation_details',
        'declared_at',
        'paid_at',
        'validated_by',
        'validated_at',
        'validation_comment',
        'rejected_by',
        'rejected_at',
        'rejection_reason',
        'rejection_comment'
    ];

    protected $casts = [
        'period_start' => 'date',
        'period_end' => 'date',
        'due_date' => 'date',
        'base_amount' => 'decimal:2',
        'tax_rate' => 'decimal:2',
        'tax_amount' => 'decimal:2',
        'total_amount' => 'decimal:2',
        'calculation_details' => 'array',
        'declared_at' => 'datetime',
        'paid_at' => 'datetime',
        'validated_at' => 'datetime',
        'rejected_at' => 'datetime'
    ];

    // Relations
    public function taxCategory()
    {
        return $this->belongsTo(TaxCategory::class);
    }

    public function comptable()
    {
        return $this->belongsTo(User::class, 'comptable_id');
    }

    public function payments()
    {
        return $this->hasMany(TaxPayment::class);
    }

    public function validatedBy()
    {
        return $this->belongsTo(User::class, 'validated_by');
    }

    public function rejectedBy()
    {
        return $this->belongsTo(User::class, 'rejected_by');
    }

    // Scopes
    public function scopeDraft($query)
    {
        return $query->where('status', 'draft');
    }

    public function scopeCalculated($query)
    {
        return $query->where('status', 'calculated');
    }

    public function scopeDeclared($query)
    {
        return $query->where('status', 'declared');
    }

    public function scopePaid($query)
    {
        return $query->where('status', 'paid');
    }

    public function scopeOverdue($query)
    {
        return $query->where('status', 'overdue');
    }

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

    public function scopeByPeriod($query, $period)
    {
        return $query->where('period', $period);
    }

    public function scopeByCategory($query, $categoryId)
    {
        return $query->where('tax_category_id', $categoryId);
    }

    public function scopeByComptable($query, $comptableId)
    {
        return $query->where('comptable_id', $comptableId);
    }

    public function scopeDueBefore($query, $date)
    {
        return $query->where('due_date', '<=', $date);
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

    public function getComptableNameAttribute()
    {
        return $this->comptable ? $this->comptable->prenom . ' ' . $this->comptable->nom : 'N/A';
    }

    public function getCategoryNameAttribute()
    {
        return $this->taxCategory ? $this->taxCategory->name : 'N/A';
    }

    public function getDaysUntilDueAttribute()
    {
        if (!$this->due_date || $this->status === 'paid') {
            return null;
        }

        $dueDate = Carbon::parse($this->due_date);
        $now = Carbon::now();
        
        if ($dueDate->isPast()) {
            return -$dueDate->diffInDays($now);
        }
        
        return $dueDate->diffInDays($now);
    }

    public function getIsOverdueAttribute()
    {
        return $this->status !== 'paid' && $this->due_date && $this->due_date < now()->toDateString();
    }

    public function getTotalPaidAttribute()
    {
        return $this->payments()->where('status', 'validated')->sum('amount_paid');
    }

    public function getRemainingAmountAttribute()
    {
        return $this->total_amount - $this->total_paid;
    }

    // Méthodes utilitaires
    public function canBeEdited()
    {
        return in_array($this->status, ['draft']);
    }

    public function canBeCalculated()
    {
        return in_array($this->status, ['draft']);
    }

    public function canBeDeclared()
    {
        return in_array($this->status, ['calculated']);
    }

    public function canBePaid()
    {
        return in_array($this->status, ['declared']);
    }

    public function canBeValidated()
    {
        return $this->status === 'en_attente';
    }

    public function canBeRejected()
    {
        return $this->status === 'en_attente';
    }

    public function markAsCalculated()
    {
        if ($this->canBeCalculated()) {
            $this->update(['status' => 'calculated']);
            return true;
        }
        return false;
    }

    public function markAsDeclared()
    {
        if ($this->canBeDeclared()) {
            $this->update([
                'status' => 'declared',
                'declared_at' => now()
            ]);
            return true;
        }
        return false;
    }

    public function markAsPaid()
    {
        if ($this->canBePaid() || $this->remaining_amount <= 0) {
            $this->update([
                'status' => 'paid',
                'paid_at' => now()
            ]);
            return true;
        }
        return false;
    }

    public function validate($comment = null, $userId = null)
    {
        if ($this->canBeValidated()) {
            $this->update([
                'status' => 'valide',
                'validated_by' => $userId ?? auth()->id(),
                'validated_at' => now(),
                'validation_comment' => $comment
            ]);
            return true;
        }
        return false;
    }

    public function reject($reason, $comment, $userId = null)
    {
        if ($this->canBeRejected()) {
            $this->update([
                'status' => 'rejete',
                'rejected_by' => $userId ?? auth()->id(),
                'rejected_at' => now(),
                'rejection_reason' => $reason,
                'rejection_comment' => $comment
            ]);
            return true;
        }
        return false;
    }

    public function calculateTax($baseAmount = null)
    {
        $baseAmount = $baseAmount ?? $this->base_amount;
        
        if ($this->taxCategory) {
            $taxAmount = $this->taxCategory->calculateTax($baseAmount);
            
            $this->update([
                'base_amount' => $baseAmount,
                'tax_rate' => $this->taxCategory->default_rate,
                'tax_amount' => $taxAmount,
                'total_amount' => $baseAmount + $taxAmount,
                'calculation_details' => [
                    'base_amount' => $baseAmount,
                    'tax_rate' => $this->taxCategory->default_rate,
                    'tax_amount' => $taxAmount,
                    'calculation_date' => now()->toIso8601String()
                ]
            ]);
            
            return $taxAmount;
        }
        
        return 0;
    }

    // Méthodes statiques
    public static function generateReference($categoryCode, $period)
    {
        $count = self::whereHas('taxCategory', function ($query) use ($categoryCode) {
            $query->where('code', $categoryCode);
        })->where('period', $period)->count() + 1;
        
        return strtoupper($categoryCode) . '-' . $period . '-' . str_pad($count, 3, '0', STR_PAD_LEFT);
    }

    public static function updateOverdueTaxes()
    {
        return self::whereIn('status', ['calculated', 'declared'])
            ->where('due_date', '<', now()->toDateString())
            ->update(['status' => 'overdue']);
    }

    public static function getTaxesByPeriod($period)
    {
        return self::with(['taxCategory', 'comptable', 'payments'])
            ->where('period', $period)
            ->orderBy('due_date')
            ->get();
    }

    public static function getTaxStats($startDate = null, $endDate = null)
    {
        $query = self::query();
        
        if ($startDate && $endDate) {
            $query->whereBetween('period_start', [$startDate, $endDate]);
        }

        $taxes = $query->get();
        
        return [
            'total_taxes' => $taxes->count(),
            'draft_taxes' => $taxes->where('status', 'draft')->count(),
            'calculated_taxes' => $taxes->where('status', 'calculated')->count(),
            'declared_taxes' => $taxes->where('status', 'declared')->count(),
            'paid_taxes' => $taxes->where('status', 'paid')->count(),
            'overdue_taxes' => $taxes->where('status', 'overdue')->count(),
            'total_amount' => $taxes->sum('total_amount'),
            'total_paid' => $taxes->sum('total_paid'),
            'remaining_amount' => $taxes->sum('remaining_amount')
        ];
    }
}