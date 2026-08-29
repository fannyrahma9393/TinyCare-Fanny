<?php

namespace App\Policies;

use App\Models\Attendance;
use App\Models\User;

class AttendancePolicy
{
    /**
     * Admin can view all, parent can view own.
     */
    public function viewAny(User $user): bool
    {
        return true;
    }

    /**
     * Admin can view any, parent can view own child's.
     */
    public function view(User $user, Attendance $attendance): bool
    {
        if ($user->isAdmin()) {
            return true;
        }

        // Parent can only view their child's attendance
        return $user->parent?->children()->where('children.id', $attendance->child_id)->exists();
    }

    /**
     * Only admin can create attendance.
     */
    public function create(User $user): bool
    {
        return $user->isAdmin();
    }

    /**
     * Only admin can update attendance.
     */
    public function update(User $user, Attendance $attendance): bool
    {
        return $user->isAdmin();
    }

    /**
     * Only admin can delete attendance.
     */
    public function delete(User $user, Attendance $attendance): bool
    {
        return $user->isAdmin();
    }

    public function restore(User $user, Attendance $attendance): bool
    {
        return false;
    }

    public function forceDelete(User $user, Attendance $attendance): bool
    {
        return false;
    }
}
