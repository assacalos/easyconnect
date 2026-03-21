<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class TechnicianReminder extends Model
{
    use HasFactory;

    protected $table = 'technician_reminders';

    protected $fillable = [
        'user_id',
        'title',
        'notes',
        'client_id',
        'company_name',
        'due_date',
        'remind_days_before',
        'status',
        'reminder_sent_at',
    ];

    protected $casts = [
        'due_date' => 'date',
        'reminder_sent_at' => 'datetime',
    ];

    public function user()
    {
        return $this->belongsTo(User::class);
    }

    public function client()
    {
        return $this->belongsTo(Client::class);
    }

    public function scopePending($query)
    {
        return $query->where('status', 'pending');
    }

    public function scopeDone($query)
    {
        return $query->where('status', 'done');
    }

    /** Nom affiché de l'entreprise (client ou company_name). */
    public function getCompanyDisplayAttribute(): string
    {
        if ($this->client_id && $this->relationLoaded('client') && $this->client) {
            return $this->client->nom_entreprise ?? $this->client->nom ?? 'Client #' . $this->client_id;
        }
        return $this->company_name ?? '—';
    }

    /**
     * Vérifie si le rappel doit être envoyé aujourd'hui (date du jour = due_date - remind_days_before).
     */
    public function shouldSendReminderToday(): bool
    {
        if ($this->status !== 'pending') {
            return false;
        }
        $reminderDate = $this->due_date->copy()->subDays((int) $this->remind_days_before);
        return $reminderDate->isToday();
    }
}
