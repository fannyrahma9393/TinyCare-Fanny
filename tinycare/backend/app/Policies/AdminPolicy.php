<?php

namespace App\Policies;

use App\Models\Admin;
use App\Models\User;

class AdminPolicy
{
    /**
     * Admin (including admin_master) can list admins.
     */
    public function viewAny(User $user): bool
    {
        return $user->isAdmin();
    }

    /**
     * Admin can view any admin profile.
     */
    public function view(User $user, Admin $admin): bool
    {
        return $user->isAdmin();
    }

    /**
     * Only admin_master can create other admins.
     */
    public function create(User $user): bool
    {
        return $user->isAdminMaster();
    }

    /**
     * Admin can update any admin profile (including own).
     */
    public function update(User $user, Admin $admin): bool
    {
        return $user->isAdmin();
    }

    /**
     * Admin_master can delete other admins, but NOT themselves.
     * Regular admin cannot delete admins.
     */
    public function delete(User $user, Admin $admin): bool
    {
        if (! $user->isAdminMaster()) {
            return false;
        }

        return $user->id !== $admin->user_id;
    }

    /**
     * Restore and forceDelete are not used in V1.
     */
    public function restore(User $user, Admin $admin): bool
    {
        return false;
    }

    public function forceDelete(User $user, Admin $admin): bool
    {
        return false;
    }
}
