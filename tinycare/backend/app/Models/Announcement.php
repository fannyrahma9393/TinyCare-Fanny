<?php

namespace App\Models;

use Carbon\Carbon;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\BelongsToMany;

class Announcement extends Model
{
    protected $fillable = [
        'title',
        'content',
        'priority',
        'publish_date',
        'expire_date',
        'is_published',
        'created_by',
    ];

    protected $casts = [
        'publish_date' => 'date',
        'expire_date' => 'date',
        'is_published' => 'boolean',
    ];

    public function creator(): BelongsTo
    {
        return $this->belongsTo(User::class, 'created_by');
    }

    /**
     * Targeted children. When empty, the announcement is broadcast to all
     * active parents; when present, only the parents of these children are
     * notified upon publish.
     */
    public function children(): BelongsToMany
    {
        return $this->belongsToMany(Child::class);
    }

    /**
     * Targeted parents (direct). When empty alongside children, the
     * announcement is broadcast to all active parents.
     */
    public function parents(): BelongsToMany
    {
        return $this->belongsToMany(ParentModel::class, 'announcement_parent', 'announcement_id', 'parent_id');
    }

    /**
     * Scope: announcement is currently within its publish/expire window.
     *
     * publish_date and expire_date are DATE columns. Comparing the DATE
     * against now() makes an announcement expire at 00:00 on its expiry day;
     * comparing against today's date keeps it visible for the whole of that
     * day (and it only becomes invisible from the following day onward).
     */
    public function scopeWithinActiveWindow(Builder $query): Builder
    {
        return $query
            ->where(function (Builder $q) {
                $q->whereNull('publish_date')
                    ->orWhere('publish_date', '<=', now());
            })
            ->where(function (Builder $q) {
                $q->whereNull('expire_date')
                    ->orWhere('expire_date', '>=', Carbon::today()->toDateString());
            });
    }

    /**
     * Scope: announcements visible to a given parent.
     *
     * A published, in-window announcement is visible when:
     *  - it targets nobody (broadcast to all active parents), or
     *  - the parent is a direct target (announcement_parent pivot), or
     *  - the parent is linked to one of the targeted children.
     * Drafts, expired/not-yet-published announcements and announcements
     * targeted at other parents/children are never visible.
     *
     * @param  int|null  $parentId  parent model id (parents.id)
     * @param  array<int, int>  $childIds  ids of the parent's children
     */
    public function scopeVisibleToParent(Builder $query, ?int $parentId, array $childIds = []): Builder
    {
        return $query
            ->where('is_published', true)
            ->withinActiveWindow()
            ->where(function (Builder $q) use ($parentId, $childIds) {
                // Broadcast: no child and no parent targets at all.
                $q->whereDoesntHave('children')
                    ->whereDoesntHave('parents');

                // Directly targeted parent (announcement_parent pivot).
                if ($parentId !== null) {
                    $q->orWhereHas('parents', fn (Builder $p) => $p->whereKey($parentId));
                }

                // Parent of a targeted child (announcement_child pivot).
                if (! empty($childIds)) {
                    $q->orWhereHas('children', fn (Builder $c) => $c->whereIn('children.id', $childIds));
                }
            });
    }

    /**
     * Check if announcement is currently active.
     *
     * expire_date is a DATE: an announcement expiring today stays active for
     * the whole of that day and only becomes inactive from the next day on.
     */
    public function isActive(): bool
    {
        if (! $this->is_published) {
            return false;
        }

        $now = Carbon::now();

        if ($this->publish_date && $now->lt($this->publish_date)) {
            return false;
        }

        if ($this->expire_date && $now->gt($this->expire_date->copy()->endOfDay())) {
            return false;
        }

        return true;
    }

    /**
     * Get priority label.
     */
    public function getPriorityLabelAttribute(): string
    {
        return match ($this->priority) {
            'low' => 'Rendah',
            'normal' => 'Normal',
            'high' => 'Tinggi',
            'urgent' => 'Mendesak',
            default => $this->priority,
        };
    }

    /**
     * Get priority color.
     */
    public function getPriorityColorAttribute(): string
    {
        return match ($this->priority) {
            'low' => 'gray',
            'normal' => 'blue',
            'high' => 'orange',
            'urgent' => 'red',
            default => 'gray',
        };
    }
}
