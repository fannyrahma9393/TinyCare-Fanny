<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\BelongsToMany;

class ParentModel extends Model
{
    protected $table = 'parents';

    protected $fillable = [
        'user_id',
        'phone',
        'address',
        'photo',
        'emergency_contact_name',
        'emergency_contact_phone',
        'emergency_contact_relationship',
        'notes',
    ];

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function children(): BelongsToMany
    {
        return $this->belongsToMany(Child::class, 'parent_child', 'parent_id', 'child_id')
            ->withTimestamps();
    }

    /**
     * Whether the parent has at least one active child.
     */
    public function hasActiveChild(): bool
    {
        if ($this->relationLoaded('children')) {
            return $this->children->contains(fn ($child) => $child->status === 'active');
        }

        return $this->children()->where('status', 'active')->exists();
    }

    /**
     * Sync the linked user's status so the parent is inactive only
     * when none of their children are active.
     */
    public function syncUserStatusFromChildren(): void
    {
        if (! $this->user) {
            return;
        }

        $target = $this->hasActiveChild() ? 'active' : 'inactive';

        if (in_array($this->user->status, ['active', 'inactive'], true) && $this->user->status !== $target) {
            $this->user->update(['status' => $target]);
        }
    }
}
