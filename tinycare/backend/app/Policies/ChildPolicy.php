<?php

namespace App\Policies;

use App\Models\Child;
use App\Models\User;

class ChildPolicy
{
    /**
     * Both admin and parent can view children.
     * Admin sees all, parent sees only own (filtered in controller).
     */
    public function viewAny(User $user): bool
    {
        return $user->isAdmin() || $user->isParent();
    }

    /**
     * Admin can view any child. Parent can only view their own children.
     */
    public function view(User $user, Child $child): bool
    {
        if ($user->isAdmin()) {
            return true;
        }

        return $user->parent?->children()->where('children.id', $child->id)->exists();
    }

    /**
     * Only admin can create children.
     */
    public function create(User $user): bool
    {
        return $user->isAdmin();
    }

    /**
     * Only admin can update children.
     */
    public function update(User $user, Child $child): bool
    {
        return $user->isAdmin();
    }

    /**
     * Only admin can delete children.
     */
    public function delete(User $user, Child $child): bool
    {
        return $user->isAdmin();
    }

    /**
     * Restore and forceDelete are not used in V1.
     */
    public function restore(User $user, Child $child): bool
    {
        return false;
    }

    public function forceDelete(User $user, Child $child): bool
    {
        return false;
    }
}
