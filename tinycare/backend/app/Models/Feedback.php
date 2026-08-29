<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class Feedback extends Model
{
    protected $fillable = [
        'parent_id',
        'child_id',
        'subject',
        'message',
        'rating',
        'status',
        'admin_response',
        'responded_by',
        'responded_at',
    ];

    protected $casts = [
        'rating' => 'integer',
        'responded_at' => 'datetime',
    ];

    public function parent(): BelongsTo
    {
        return $this->belongsTo(ParentModel::class);
    }

    public function child(): BelongsTo
    {
        return $this->belongsTo(Child::class);
    }

    public function responder(): BelongsTo
    {
        return $this->belongsTo(User::class, 'responded_by');
    }

    /**
     * Get status label.
     */
    public function getStatusLabelAttribute(): string
    {
        return match ($this->status) {
            'pending' => 'Menunggu',
            'reviewed' => 'Ditinjau',
            'responded' => 'Dijawab',
            default => $this->status,
        };
    }

    /**
     * Get rating stars.
     */
    public function getRatingStarsAttribute(): string
    {
        if (! $this->rating) {
            return '-';
        }

        return str_repeat('⭐', $this->rating).str_repeat('☆', 5 - $this->rating);
    }
}
