<?php

namespace App\Policies;

use App\Models\Facture;
use App\Models\User;

class FacturePolicy
{
    /**
     * Liste / compteurs / stats : tous les rôles internes sauf portail client.
     */
    public function viewAny(User $user): bool
    {
        return ! $user->isClient();
    }

    public function view(User $user, Facture $facture): bool
    {
        if (! $this->viewAny($user)) {
            return false;
        }
        if ($user->isCommercial()) {
            return (int) $facture->user_id === (int) $user->id;
        }

        return true;
    }

    /**
     * Création : comptable, admin, patron (routes role:1,3,6).
     */
    public function create(User $user): bool
    {
        return $user->isAdmin() || $user->isPatron() || $user->isComptable();
    }

    /**
     * Mise à jour : comptable, admin, patron ; pas si payée.
     */
    public function update(User $user, Facture $facture): bool
    {
        if (! ($user->isAdmin() || $user->isPatron() || $user->isComptable())) {
            return false;
        }

        return $facture->status !== 'payee';
    }

    /**
     * Suppression réservée à l’admin (contrôleur) ; pas si payée.
     */
    public function delete(User $user, Facture $facture): bool
    {
        return $user->isAdmin() && $facture->status !== 'payee';
    }

    public function validate(User $user, Facture $facture): bool
    {
        return $user->isAdmin() || $user->isPatron();
    }

    public function reject(User $user, Facture $facture): bool
    {
        return $this->validate($user, $facture);
    }

    /**
     * Marquer payé : commercial sur sa facture, sinon admin / patron / comptable.
     */
    public function markAsPaid(User $user, Facture $facture): bool
    {
        if ($user->isAdmin() || $user->isPatron() || $user->isComptable()) {
            return true;
        }

        return $user->isCommercial() && (int) $facture->user_id === (int) $user->id;
    }

    /**
     * Annuler un rejet : comptable, admin, patron (routes role:1,3,6).
     */
    public function cancelRejection(User $user, Facture $facture): bool
    {
        return $user->isAdmin() || $user->isPatron() || $user->isComptable();
    }

    public function validationHistory(User $user, Facture $facture): bool
    {
        return $user->isAdmin() || $user->isPatron() || $user->isComptable();
    }

    /**
     * Rapports financiers : patron / admin (routes role:1,6).
     */
    public function reports(User $user): bool
    {
        return $user->isAdmin() || $user->isPatron();
    }
}
