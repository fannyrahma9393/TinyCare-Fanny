<?php

namespace App\Policies;

use App\Models\DailyStory;
use App\Models\User;

class DailyStoryPolicy
{
    /**
     * Admin can view all.
     */
    public function viewAny(User $user): bool
    {
        return true;
    }

    /**
     * Admin can view any. Parent can only view own child's stories.
     */
    public function view(User $user, DailyStory $dailyStory): bool
    {
        if ($user->isAdmin()) {
            return true;
        }

        return $user->parent?->children()->where('children.id', $dailyStory->child_id)->exists();
    }

    /**
     * Only admin can create daily stories.
     */
    public function create(User $user): bool
    {
        return $user->isAdmin();
    }

    /**
     * Only admin can update daily stories.
     */
    public function update(User $user, DailyStory $dailyStory): bool
    {
        return $user->isAdmin();
    }

    /**
     * Only admin can delete daily stories.
     */
    public function delete(User $user, DailyStory $dailyStory): bool
    {
        return $user->isAdmin();
    }

    public function restore(User $user, DailyStory $dailyStory): bool
    {
        return false;
    }

    public function forceDelete(User $user, DailyStory $dailyStory): bool
    {
        return false;
    }
}
