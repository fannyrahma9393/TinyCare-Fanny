<?php

namespace App\Policies;

use App\Models\Feedback;
use App\Models\User;

class FeedbackPolicy
{
    public function viewAny(User $user): bool
    {
        return $user->isAdmin();
    }

    public function view(User $user, Feedback $feedback): bool
    {
        if ($user->isAdmin()) {
            return true;
        }

        return $user->parent?->id === $feedback->parent_id;
    }

    public function create(User $user): bool
    {
        return $user->isParent();
    }

    public function update(User $user, Feedback $feedback): bool
    {
        return $user->isAdmin();
    }

    public function delete(User $user, Feedback $feedback): bool
    {
        return $user->isAdmin();
    }

    public function restore(User $user, Feedback $feedback): bool
    {
        return false;
    }

    public function forceDelete(User $user, Feedback $feedback): bool
    {
        return false;
    }
}
