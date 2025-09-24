<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Carbon\Carbon;

class PaymentSchedule extends Model
{
    use HasFactory;

    protected $fillable = [
        'client_id',
        'comptable_id',
        'start_date',
        'end_date',
        'frequency',
        'total_installments',
        'paid_installments',
        'installment_amount',
        'status',
        'next_payment_date',
        'description'
    ];

    protected $casts = [
        'start_date' => 'date',
        'end_date' => 'date',
        'installment_amount' => 'decimal:2',
        'next_payment_date' => 'date'
    ];

    // Relations
    public function client()
    {
        return $this->belongsTo(Client::class);
    }

    public function comptable()
    {
        return $this->belongsTo(User::class, 'comptable_id');
    }

    public function payments()
    {
        return $this->hasMany(Payment::class);
    }

    public function installments()
    {
        return $this->hasMany(PaymentInstallment::class);
    }

    // Scopes
    public function scopeActive($query)
    {
        return $query->where('status', 'active');
    }

    public function scopePaused($query)
    {
        return $query->where('status', 'paused');
    }

    public function scopeCompleted($query)
    {
        return $query->where('status', 'completed');
    }

    public function scopeCancelled($query)
    {
        return $query->where('status', 'cancelled');
    }

    public function scopeByClient($query, $clientId)
    {
        return $query->where('client_id', $clientId);
    }

    public function scopeByComptable($query, $comptableId)
    {
        return $query->where('comptable_id', $comptableId);
    }

    // Méthodes utilitaires
    public function isCompleted()
    {
        return $this->paid_installments >= $this->total_installments;
    }

    public function isOverdue()
    {
        return $this->next_payment_date && $this->next_payment_date < now()->toDateString();
    }

    public function canBePaused()
    {
        return $this->status === 'active';
    }

    public function canBeResumed()
    {
        return $this->status === 'paused';
    }

    public function canBeCancelled()
    {
        return in_array($this->status, ['active', 'paused']);
    }

    public function pause()
    {
        if ($this->canBePaused()) {
            $this->update(['status' => 'paused']);
            return true;
        }
        return false;
    }

    public function resume()
    {
        if ($this->canBeResumed()) {
            $this->update(['status' => 'active']);
            return true;
        }
        return false;
    }

    public function cancel()
    {
        if ($this->canBeCancelled()) {
            $this->update(['status' => 'cancelled']);
            return true;
        }
        return false;
    }

    public function markAsCompleted()
    {
        if ($this->isCompleted()) {
            $this->update(['status' => 'completed']);
            return true;
        }
        return false;
    }

    public function updateNextPaymentDate()
    {
        if ($this->status === 'active' && !$this->isCompleted()) {
            $nextDate = Carbon::parse($this->start_date)
                ->addDays($this->frequency * ($this->paid_installments + 1));
            
            $this->update(['next_payment_date' => $nextDate]);
        }
    }

    // Accesseurs
    public function getClientNameAttribute()
    {
        return $this->client ? $this->client->nom : 'Client inconnu';
    }

    public function getComptableNameAttribute()
    {
        return $this->comptable ? $this->comptable->nom . ' ' . $this->comptable->prenom : 'Comptable inconnu';
    }

    public function getStatusLibelleAttribute()
    {
        $statuses = [
            'active' => 'Actif',
            'paused' => 'En pause',
            'completed' => 'Terminé',
            'cancelled' => 'Annulé'
        ];

        return $statuses[$this->status] ?? $this->status;
    }

    public function getProgressPercentageAttribute()
    {
        if ($this->total_installments == 0) return 0;
        return round(($this->paid_installments / $this->total_installments) * 100, 2);
    }

    public function getRemainingInstallmentsAttribute()
    {
        return $this->total_installments - $this->paid_installments;
    }

    public function getTotalAmountAttribute()
    {
        return $this->total_installments * $this->installment_amount;
    }

    public function getPaidAmountAttribute()
    {
        return $this->paid_installments * $this->installment_amount;
    }

    public function getRemainingAmountAttribute()
    {
        return $this->remaining_installments * $this->installment_amount;
    }

    // Méthodes statiques
    public static function createSchedule($clientId, $comptableId, $startDate, $endDate, $frequency, $installmentAmount, $description = null)
    {
        $start = Carbon::parse($startDate);
        $end = Carbon::parse($endDate);
        $totalDays = $start->diffInDays($end);
        $totalInstallments = ceil($totalDays / $frequency);

        $schedule = self::create([
            'client_id' => $clientId,
            'comptable_id' => $comptableId,
            'start_date' => $startDate,
            'end_date' => $endDate,
            'frequency' => $frequency,
            'total_installments' => $totalInstallments,
            'installment_amount' => $installmentAmount,
            'status' => 'active',
            'next_payment_date' => $startDate,
            'description' => $description
        ]);

        // Créer les échéances
        $schedule->createInstallments();

        return $schedule;
    }

    public function createInstallments()
    {
        $installments = [];
        $currentDate = Carbon::parse($this->start_date);

        for ($i = 1; $i <= $this->total_installments; $i++) {
            $installments[] = [
                'payment_schedule_id' => $this->id,
                'installment_number' => $i,
                'due_date' => $currentDate->copy()->addDays(($i - 1) * $this->frequency),
                'amount' => $this->installment_amount,
                'status' => 'pending',
                'created_at' => now(),
                'updated_at' => now()
            ];
        }

        PaymentInstallment::insert($installments);
    }

    public function markInstallmentAsPaid($installmentNumber)
    {
        $installment = $this->installments()
            ->where('installment_number', $installmentNumber)
            ->first();

        if ($installment && $installment->status === 'pending') {
            $installment->update([
                'status' => 'paid',
                'paid_date' => now()
            ]);

            $this->increment('paid_installments');
            $this->updateNextPaymentDate();

            if ($this->isCompleted()) {
                $this->markAsCompleted();
            }

            return true;
        }

        return false;
    }
}