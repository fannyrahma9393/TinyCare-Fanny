<?php

namespace App\Policies;

use App\Models\AuthorizedPickup;
use App\Models\User;

class AuthorizedPickupPolicy
{
    public function viewAny(User $user): bool
    {
        return true;
    }

    public function view(User $user, AuthorizedPickup $pickup): bool
    {
        if ($user->isAdmin()) {
            return true;
        }

        return $user->parent?->id === $pickup->parent_id;
    }

    public function create(User $user): bool
    {
        return $user->isParent();
    }

    public function update(User $user, AuthorizedPickup $pickup): bool
    {
        return $user->parent?->id === $pickup->parent_id;
    }

    public function delete(User $user, AuthorizedPickup $pickup): bool
    {
        return $user->parent?->id === $pickup->parent_id;
    }

    public function restore(User $user, AuthorizedPickup $pickup): bool
    {
        return false;
    }

    public function forceDelete(User $user, AuthorizedPickup $pickup): bool
    {
        return false;
    }
}
