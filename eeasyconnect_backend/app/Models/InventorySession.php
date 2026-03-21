<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class InventorySession extends Model
{
    use HasFactory;

    protected $fillable = [
        'date',
        'depot',
        'status',
        'created_by',
        'closed_by',
        'closed_at',
    ];

    protected $casts = [
        'date' => 'date',
        'closed_at' => 'datetime',
    ];

    public const STATUS_IN_PROGRESS = 'en_cours';
    public const STATUS_CLOSED = 'cloture';

    public function items()
    {
        return $this->hasMany(InventorySessionItem::class, 'inventory_session_id');
    }

    public function creator()
    {
        return $this->belongsTo(User::class, 'created_by');
    }

    public function closedByUser()
    {
        return $this->belongsTo(User::class, 'closed_by');
    }

    public function isInProgress(): bool
    {
        return $this->status === self::STATUS_IN_PROGRESS;
    }

    public function isClosed(): bool
    {
        return $this->status === self::STATUS_CLOSED;
    }
}
