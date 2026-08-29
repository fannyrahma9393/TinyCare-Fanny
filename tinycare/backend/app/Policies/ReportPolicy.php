<?php

namespace App\Policies;

use App\Models\User;
use App\Models\WeeklyReport;

class ReportPolicy
{
    public function viewAny(User $user): bool
    {
        return true;
    }

    public function view(User $user, WeeklyReport $report): bool
    {
        if ($user->isAdmin()) {
            return true;
        }

        return $user->parent?->children()->where('children.id', $report->child_id)->exists();
    }

    public function create(User $user): bool
    {
        return $user->isAdmin();
    }

    public function update(User $user, WeeklyReport $report): bool
    {
        return $user->isAdmin();
    }

    public function delete(User $user, WeeklyReport $report): bool
    {
        return false;
    }

    public function restore(User $user, WeeklyReport $report): bool
    {
        return false;
    }

    public function forceDelete(User $user, WeeklyReport $report): bool
    {
        return false;
    }
}
