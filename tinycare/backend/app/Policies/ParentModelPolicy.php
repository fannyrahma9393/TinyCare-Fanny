<?php

namespace App\Policies;

use App\Models\ParentModel;
use App\Models\User;

class ParentModelPolicy
{
    /**
     * Admin (including admin_master) can list all parents.
     */
    public function viewAny(User $user): bool
    {
        return $user->isAdmin();
    }

    /**
     * Admin can view any parent. Parent can only view own profile.
     */
    public function view(User $user, ParentModel $parent): bool
    {
        if ($user->isAdmin()) {
            return true;
        }

        return $user->id === $parent->user_id;
    }

    /**
     * Only admin can create parents.
     */
    public function create(User $user): bool
    {
        return $user->isAdmin();
    }

    /**
     * Admin can update any parent. Parent can update own profile.
     */
    public function update(User $user, ParentModel $parent): bool
    {
        if ($user->isAdmin()) {
            return true;
        }

        return $user->id === $parent->user_id;
    }

    /**
     * Only admin can delete parents.
     */
    public function delete(User $user, ParentModel $parent): bool
    {
        return $user->isAdmin();
    }

    public function restore(User $user, ParentModel $parent): bool
    {
        return false;
    }

    public function forceDelete(User $user, ParentModel $parent): bool
    {
        return false;
    }
}
