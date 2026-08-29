<?php

namespace App\Policies;

use App\Models\DevelopmentAssessment;
use App\Models\User;

class DevelopmentPolicy
{
    /**
     * Admin can view all assessments.
     */
    public function viewAny(User $user): bool
    {
        return $user->isAdmin();
    }

    /**
     * Admin can view any. Parent can view own child's assessments.
     */
    public function view(User $user, DevelopmentAssessment $assessment): bool
    {
        if ($user->isAdmin()) {
            return true;
        }

        return $user->parent?->children()->where('children.id', $assessment->child_id)->exists();
    }

    /**
     * Only admin can create assessments.
     */
    public function create(User $user): bool
    {
        return $user->isAdmin();
    }

    /**
     * Only admin can update assessments.
     */
    public function update(User $user, DevelopmentAssessment $assessment): bool
    {
        return $user->isAdmin();
    }

    /**
     * Only admin can delete assessments.
     */
    public function delete(User $user, DevelopmentAssessment $assessment): bool
    {
        return $user->isAdmin();
    }

    public function restore(User $user, DevelopmentAssessment $assessment): bool
    {
        return false;
    }

    public function forceDelete(User $user, DevelopmentAssessment $assessment): bool
    {
        return false;
    }
}
