<?php

namespace App\Policies;

use App\Models\ChildInformation;
use App\Models\User;

class ChildInformationPolicy
{
    public function viewAny(User $user): bool
    {
        return $user->isAdmin() || $user->isAdminMaster() || $user->isParent();
    }

    public function view(User $user, ChildInformation $childInformation): bool
    {
        if ($user->isAdmin() || $user->isAdminMaster()) {
            return true;
        }

        if ($user->isParent()) {
            return $user->parent->children()->where('children.id', $childInformation->child_id)->exists();
        }

        return false;
    }

    public function create(User $user): bool
    {
        return $user->isAdmin() || $user->isAdminMaster();
    }

    public function update(User $user, ChildInformation $childInformation): bool
    {
        return $user->isAdmin() || $user->isAdminMaster();
    }

    public function delete(User $user, ChildInformation $childInformation): bool
    {
        return $user->isAdmin() || $user->isAdminMaster();
    }
}
