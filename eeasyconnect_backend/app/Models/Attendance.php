<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class Attendance extends Model
{
    use HasFactory;

    protected $fillable = [
        'user_id',
        'check_in_time',
        'check_out_time',
        'status',
        'location',
        'photo_path',
        'notes',
        'validated_by',
        'validated_at',
        'validation_comment',
        'rejected_by',
        'rejected_at',
        'rejection_reason',
        'rejection_comment',
    ];

    protected $casts = [
        'check_in_time' => 'datetime',
        'check_out_time' => 'datetime',
        'validated_at' => 'datetime',
        'rejected_at' => 'datetime',
        'location' => 'array',
    ];

    // Relations
    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function approver(): BelongsTo
    {
        return $this->belongsTo(User::class, 'validated_by');
    }

    public function validator(): BelongsTo
    {
        return $this->belongsTo(User::class, 'validated_by');
    }

    public function rejector(): BelongsTo
    {
        return $this->belongsTo(User::class, 'rejected_by');
    }

    // Scopes
    public function scopePending($query)
    {
        return $query->where('status', 'en_attente');
    }

    public function scopeApproved($query)
    {
        return $query->where('status', 'valide');
    }

    public function scopeRejected($query)
    {
        return $query->where('status', 'rejete');
    }

    // Accessors
    public function getPhotoUrlAttribute()
    {
        if ($this->photo_path) {
            return asset('storage/' . $this->photo_path);
        }
        return null;
    }

    public function getStatusLabelAttribute()
    {
        return match($this->status) {
            'en_attente' => 'En attente',
            'valide' => 'Validé',
            'rejete' => 'Rejeté',
            default => 'Inconnu'
        };
    }

    // Méthodes
    public function canBeApproved(): bool
    {
        return $this->status === 'en_attente';
    }

    public function canBeRejected(): bool
    {
        return $this->status === 'en_attente';
    }

    public function approve(User $approver, string $comment = null): bool
    {
        if (!$this->canBeApproved()) {
            return false;
        }

        $this->update([
            'status' => 'valide',
            'validated_by' => $approver->id,
            'validated_at' => now(),
            'validation_comment' => $comment,
        ]);

        return true;
    }

    public function reject(User $approver, string $reason, string $comment = null): bool
    {
        if (!$this->canBeRejected()) {
            return false;
        }

        $this->update([
            'status' => 'rejete',
            'rejected_by' => $approver->id,
            'rejected_at' => now(),
            'rejection_reason' => $reason,
            'rejection_comment' => $comment,
        ]);

        return true;
    }
}