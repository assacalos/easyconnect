<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Carbon\Carbon;

class PaymentInstallment extends Model
{
    use HasFactory;

    protected $fillable = [
        'payment_schedule_id',
        'installment_number',
        'due_date',
        'amount',
        'status',
        'paid_date',
        'notes'
    ];

    protected $casts = [
        'due_date' => 'date',
        'amount' => 'decimal:2',
        'paid_date' => 'date'
    ];

    // Relations
    public function paymentSchedule()
    {
        return $this->belongsTo(PaymentSchedule::class);
    }

    // Scopes
    public function scopePending($query)
    {
        return $query->where('status', 'pending');
    }

    public function scopePaid($query)
    {
        return $query->where('status', 'paid');
    }

    public function scopeOverdue($query)
    {
        return $query->where('status', 'overdue');
    }

    public function scopeBySchedule($query, $scheduleId)
    {
        return $query->where('payment_schedule_id', $scheduleId);
    }

    public function scopeByDateRange($query, $startDate, $endDate)
    {
        return $query->whereBetween('due_date', [$startDate, $endDate]);
    }

    // Méthodes utilitaires
    public function isOverdue()
    {
        return $this->status === 'pending' && $this->due_date < now()->toDateString();
    }

    public function canBePaid()
    {
        return $this->status === 'pending';
    }

    public function markAsPaid($notes = null)
    {
        if ($this->canBePaid()) {
            $this->update([
                'status' => 'paid',
                'paid_date' => now(),
                'notes' => $notes ?? $this->notes
            ]);

            // Mettre à jour l'échéancier
            $this->paymentSchedule->markInstallmentAsPaid($this->installment_number);

            return true;
        }
        return false;
    }

    public function markAsOverdue()
    {
        if ($this->status === 'pending' && $this->isOverdue()) {
            $this->update(['status' => 'overdue']);
            return true;
        }
        return false;
    }

    // Accesseurs
    public function getStatusLibelleAttribute()
    {
        $statuses = [
            'pending' => 'En attente',
            'paid' => 'Payé',
            'overdue' => 'En retard'
        ];

        return $statuses[$this->status] ?? $this->status;
    }

    public function getDaysUntilDueAttribute()
    {
        if ($this->status === 'paid') {
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
        return $this->isOverdue();
    }

    public function getFormattedAmountAttribute()
    {
        return number_format($this->amount, 2, ',', ' ') . ' €';
    }

    // Méthodes statiques
    public static function updateOverdueInstallments()
    {
        return self::where('status', 'pending')
            ->where('due_date', '<', now()->toDateString())
            ->update(['status' => 'overdue']);
    }

    public static function getUpcomingInstallments($days = 7)
    {
        return self::where('status', 'pending')
            ->whereBetween('due_date', [now()->toDateString(), now()->addDays($days)->toDateString()])
            ->with('paymentSchedule.client')
            ->orderBy('due_date')
            ->get();
    }

    public static function getOverdueInstallments()
    {
        return self::where('status', 'overdue')
            ->with('paymentSchedule.client')
            ->orderBy('due_date')
            ->get();
    }
}