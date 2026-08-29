<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class DevelopmentAssessment extends Model
{
    protected $fillable = [
        'child_id',
        'development_category_id',
        'indicator',
        'notes',
        'progress',
        'observation_date',
        'assessed_by',
    ];

    protected $casts = [
        'observation_date' => 'date',
    ];

    public function child(): BelongsTo
    {
        return $this->belongsTo(Child::class);
    }

    public function category(): BelongsTo
    {
        return $this->belongsTo(DevelopmentCategory::class, 'development_category_id');
    }

    public function assessor(): BelongsTo
    {
        return $this->belongsTo(User::class, 'assessed_by');
    }

    /**
     * Get progress label in Indonesian.
     */
    public function getProgressLabelAttribute(): string
    {
        return match ($this->progress) {
            'belum' => 'Belum',
            'mulai' => 'Mulai',
            'berkembang' => 'Berkembang',
            'baik' => 'Baik',
            'sangat_baik' => 'Sangat Baik',
            default => $this->progress,
        };
    }

    /**
     * Get progress percentage (for visualization).
     */
    public function getProgressPercentageAttribute(): int
    {
        return match ($this->progress) {
            'belum' => 0,
            'mulai' => 25,
            'berkembang' => 50,
            'baik' => 75,
            'sangat_baik' => 100,
            default => 0,
        };
    }

    /**
     * Get progress color (for UI).
     */
    public function getProgressColorAttribute(): string
    {
        return match ($this->progress) {
            'belum' => 'gray',
            'mulai' => 'orange',
            'berkembang' => 'yellow',
            'baik' => 'green',
            'sangat_baik' => 'emerald',
            default => 'gray',
        };
    }
}
