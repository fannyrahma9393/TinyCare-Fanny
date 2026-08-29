<?php

namespace App\Policies;

use App\Models\Media;
use App\Models\User;

class MediaPolicy
{
    /**
     * Admin can view all media.
     */
    public function viewAny(User $user): bool
    {
        return $user->isAdmin();
    }

    /**
     * Admin can view any. Parent can view media related to their children.
     */
    public function view(User $user, Media $media): bool
    {
        if ($user->isAdmin()) {
            return true;
        }

        // Parent can view media attached to their children
        if ($media->mediable_type === 'App\\Models\\Child') {
            return $user->parent?->children()->where('children.id', $media->mediable_id)->exists();
        }

        // Parent can view media attached to their children's daily stories
        if ($media->mediable_type === 'App\\Models\\DailyStory') {
            return $user->parent?->children()
                ->whereHas('dailyStories', function ($q) use ($media) {
                    $q->where('id', $media->mediable_id);
                })->exists();
        }

        return false;
    }

    /**
     * Only admin can upload media.
     */
    public function create(User $user): bool
    {
        return $user->isAdmin();
    }

    /**
     * Only admin can update media.
     */
    public function update(User $user, Media $media): bool
    {
        return $user->isAdmin();
    }

    /**
     * Only admin can delete media.
     */
    public function delete(User $user, Media $media): bool
    {
        return $user->isAdmin();
    }

    public function restore(User $user, Media $media): bool
    {
        return false;
    }

    public function forceDelete(User $user, Media $media): bool
    {
        return false;
    }
}
