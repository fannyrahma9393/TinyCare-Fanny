<?php

namespace App\Policies;

use App\Models\User;
use App\Models\Voucher;

class VoucherPolicy
{
    /**
     * Admin can view all, parent can view available.
     */
    public function viewAny(User $user): bool
    {
        return true;
    }

    /**
     * Both admin and parent can view voucher details.
     */
    public function view(User $user, Voucher $voucher): bool
    {
        return true;
    }

    /**
     * Only admin can create vouchers.
     */
    public function create(User $user): bool
    {
        return $user->isAdmin();
    }

    /**
     * Only admin can update vouchers.
     */
    public function update(User $user, Voucher $voucher): bool
    {
        return $user->isAdmin();
    }

    /**
     * Only admin can delete vouchers.
     */
    public function delete(User $user, Voucher $voucher): bool
    {
        return $user->isAdmin();
    }

    public function restore(User $user, Voucher $voucher): bool
    {
        return false;
    }

    public function forceDelete(User $user, Voucher $voucher): bool
    {
        return false;
    }
}
