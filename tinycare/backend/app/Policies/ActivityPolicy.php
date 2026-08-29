<?php

namespace App\Policies;

use App\Models\Activity;
use App\Models\User;

class ActivityPolicy
{
    /**
     * Both admin and parent can view activities.
     */
    public function viewAny(User $user): bool
    {
        return true;
    }

    /**
     * Both can view activity details.
     */
    public function view(User $user, Activity $activity): bool
    {
        return true;
    }

    /**
     * Only admin can create activities.
     */
    public function create(User $user): bool
    {
        return $user->isAdmin();
    }

    /**
     * Only admin can update activities.
     */
    public function update(User $user, Activity $activity): bool
    {
        return $user->isAdmin();
    }

    /**
     * Only admin can delete activities.
     */
    public function delete(User $user, Activity $activity): bool
    {
        return $user->isAdmin();
    }

    public function restore(User $user, Activity $activity): bool
    {
        return false;
    }

    public function forceDelete(User $user, Activity $activity): bool
    {
        return false;
    }
}
