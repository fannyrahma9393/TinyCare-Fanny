<?php

namespace App\Policies;

use App\Models\Payment;
use App\Models\User;

class PaymentPolicy
{
    /**
     * Admin can view all payments.
     */
    public function viewAny(User $user): bool
    {
        return $user->isAdmin();
    }

    /**
     * Admin can view any payment. Parent can only view own payments.
     */
    public function view(User $user, Payment $payment): bool
    {
        if ($user->isAdmin()) {
            return true;
        }

        // Parent can only view payments for their invoices
        return $user->parent?->id === $payment->invoice?->parent_id;
    }

    /**
     * Parent can create payments (submit proof).
     */
    public function create(User $user): bool
    {
        return $user->isParent();
    }

    /**
     * Only admin can update (verify/reject) payments.
     */
    public function update(User $user, Payment $payment): bool
    {
        return $user->isAdmin();
    }

    /**
     * No one can delete payments.
     */
    public function delete(User $user, Payment $payment): bool
    {
        return false;
    }

    public function restore(User $user, Payment $payment): bool
    {
        return false;
    }

    public function forceDelete(User $user, Payment $payment): bool
    {
        return false;
    }
}
