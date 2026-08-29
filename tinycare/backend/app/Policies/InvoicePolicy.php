<?php

namespace App\Policies;

use App\Models\Invoice;
use App\Models\User;

class InvoicePolicy
{
    /**
     * Admin can view all, parent cannot list (uses custom endpoint).
     */
    public function viewAny(User $user): bool
    {
        return $user->isAdmin();
    }

    /**
     * Admin can view any. Parent can only view own invoices.
     */
    public function view(User $user, Invoice $invoice): bool
    {
        if ($user->isAdmin()) {
            return true;
        }

        return $user->parent?->id === $invoice->parent_id;
    }

    /**
     * Only admin can create invoices.
     */
    public function create(User $user): bool
    {
        return $user->isAdmin();
    }

    /**
     * Only admin can update invoices.
     */
    public function update(User $user, Invoice $invoice): bool
    {
        return $user->isAdmin();
    }

    /**
     * Only admin can delete invoices.
     */
    public function delete(User $user, Invoice $invoice): bool
    {
        return $user->isAdmin();
    }

    public function restore(User $user, Invoice $invoice): bool
    {
        return false;
    }

    public function forceDelete(User $user, Invoice $invoice): bool
    {
        return false;
    }
}
