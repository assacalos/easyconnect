<?php

namespace App\Models;

use App\Enums\UserRole;

// use Illuminate\Contracts\Auth\MustVerifyEmail;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Laravel\Sanctum\HasApiTokens;

class User extends Authenticatable
{
    use HasApiTokens, HasFactory, Notifiable;

    /**
     * The attributes that are mass assignable.
     *
     * @var array<int, string>
     */
    protected $fillable = [
        'nom',
        'prenom',
        'email',
        'password',
        'avatar',
        'role',
        'is_active',
    ];

    /**
     * The attributes that should be hidden for serialization.
     *
     * @var array<int, string>
     */
    protected $hidden = [
        'password',
        'remember_token',
    ];

    /**
     * The attributes that should be cast.
     *
     * @var array<string, string>
     */
    protected $casts = [
        'email_verified_at' => 'datetime',
        'is_active' => 'boolean',
    ];

    /**
     * Rôle typé (aligné sur users.role).
     */
    public function roleEnum(): ?UserRole
    {
        return UserRole::tryFromColumn($this->role);
    }

    public function hasRole(UserRole $role): bool
    {
        return $role->matchesColumn($this->role);
    }

    public function hasAnyRole(UserRole ...$roles): bool
    {
        foreach ($roles as $role) {
            if ($this->hasRole($role)) {
                return true;
            }
        }

        return false;
    }

    /**
     * Vérifier si l'utilisateur est admin
     */
    public function isAdmin(): bool
    {
        return $this->hasRole(UserRole::Admin);
    }

    /**
     * Vérifier si l'utilisateur est commercial
     */
    public function isCommercial(): bool
    {
        return $this->hasRole(UserRole::Commercial);
    }

    /**
     * Vérifier si l'utilisateur est comptable
     */
    public function isComptable(): bool
    {
        return $this->hasRole(UserRole::Comptable);
    }

    /**
     * Vérifier si l'utilisateur est RH
     */
    public function isRH(): bool
    {
        return $this->hasRole(UserRole::RH);
    }

    /**
     * Vérifier si l'utilisateur est technicien
     */
    public function isTechnicien(): bool
    {
        return $this->hasRole(UserRole::Technicien);
    }

    /**
     * Vérifier si l'utilisateur est patron
     */
    public function isPatron(): bool
    {
        return $this->hasRole(UserRole::Patron);
    }

    /**
     * Vérifier si l'utilisateur est client (portail client)
     */
    public function isClient(): bool
    {
        return $this->hasRole(UserRole::Client);
    }

    /**
     * Obtenir le nom du rôle (avec cache)
     */
    public function getRoleName(): string
    {
        return \Illuminate\Support\Facades\Cache::remember("role_name:{$this->role}", 86400, function () {
            return $this->roleEnum()?->label() ?? 'Inconnu';
        });
    }

    /**
     * Tâches assignées à cet utilisateur
     */
    public function assignedTasks()
    {
        return $this->hasMany(Task::class, 'assigned_to');
    }

    /**
     * Tâches créées par cet utilisateur (patron/admin)
     */
    public function createdTasks()
    {
        return $this->hasMany(Task::class, 'assigned_by');
    }

    /**
     * Relation avec les tokens d'appareil
     */
    public function deviceTokens()
    {
        return $this->hasMany(DeviceToken::class);
    }

    /**
     * Obtenir les tokens actifs de l'utilisateur
     */
    public function activeDeviceTokens()
    {
        return $this->deviceTokens()->where('is_active', true);
    }
}
