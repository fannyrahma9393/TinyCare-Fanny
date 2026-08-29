<?php

namespace App\Policies;

use App\Models\Package;
use App\Models\User;

class PackagePolicy
{
    /**
     * Both admin and parent can view packages.
     */
    public function viewAny(User $user): bool
    {
        return true;
    }

    /**
     * Both admin and parent can view package details.
     */
    public function view(User $user, Package $package): bool
    {
        return true;
    }

    /**
     * Only admin can create packages.
     */
    public function create(User $user): bool
    {
        return $user->isAdmin();
    }

    /**
     * Only admin can update packages.
     */
    public function update(User $user, Package $package): bool
    {
        return $user->isAdmin();
    }

    /**
     * Only admin can delete packages.
     */
    public function delete(User $user, Package $package): bool
    {
        return $user->isAdmin();
    }

    public function restore(User $user, Package $package): bool
    {
        return false;
    }

    public function forceDelete(User $user, Package $package): bool
    {
        return false;
    }
}
