<?php

namespace App\Policies;

use App\Models\Devis;
use App\Models\User;

class DevisPolicy
{
    /**
     * Admin, commercial, comptable, patron : accès aux listes / agrégats devis.
     */
    public function viewAny(User $user): bool
    {
        return $user->isAdmin()
            || $user->isCommercial()
            || $user->isComptable()
            || $user->isPatron();
    }

    /**
     * Endpoint debug : agrégats globaux — réservé patron / admin.
     */
    public function debug(User $user): bool
    {
        return $user->isAdmin() || $user->isPatron();
    }

    public function view(User $user, Devis $devis): bool
    {
        if ($this->isCommercialScoped($user, $devis)) {
            return true;
        }

        return $user->isCommercial() && (int) $devis->user_id === (int) $user->id;
    }

    public function create(User $user): bool
    {
        return $this->viewAny($user);
    }

    public function update(User $user, Devis $devis): bool
    {
        return $this->view($user, $devis);
    }

    /**
     * Suppression : uniquement brouillon (status 0), commercial sur les siens, sinon rôles privilégiés.
     */
    public function delete(User $user, Devis $devis): bool
    {
        if ((int) $devis->status !== 0) {
            return false;
        }

        if ($this->isCommercialScoped($user, $devis)) {
            return true;
        }

        return $user->isCommercial() && (int) $devis->user_id === (int) $user->id;
    }

    /**
     * Acceptation / validation par patron ou admin (routes role:1,6).
     */
    public function validate(User $user, Devis $devis): bool
    {
        return $user->isAdmin() || $user->isPatron();
    }

    public function reject(User $user, Devis $devis): bool
    {
        return $this->validate($user, $devis);
    }

    /**
     * Marquer payé : commercial sur son devis, sinon comptable / admin / patron.
     */
    public function markAsPaid(User $user, Devis $devis): bool
    {
        if ($user->isAdmin() || $user->isPatron() || $user->isComptable()) {
            return true;
        }

        return $user->isCommercial() && (int) $devis->user_id === (int) $user->id;
    }

    private function isCommercialScoped(User $user, Devis $devis): bool
    {
        return $user->isAdmin() || $user->isPatron() || $user->isComptable();
    }
}
