<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\Relations\MorphMany;

class DailyStory extends Model
{
    protected $fillable = [
        'child_id',
        'date',
        'summary',
        'mood',
        'meal_notes',
        'sleep_notes',
        'admin_notes',
        'meal_rating',
        'sleep_hours',
        'created_by',
    ];

    protected $casts = [
        'date' => 'date',
        'meal_rating' => 'decimal:1',
        'sleep_hours' => 'decimal:1',
    ];

    public function child(): BelongsTo
    {
        return $this->belongsTo(Child::class);
    }

    public function creator(): BelongsTo
    {
        return $this->belongsTo(User::class, 'created_by');
    }

    public function activities(): HasMany
    {
        return $this->hasMany(ChildActivity::class, 'child_id', 'child_id')
            ->whereDate('date', $this->date);
    }

    public function media(): MorphMany
    {
        return $this->morphMany(Media::class, 'mediable');
    }

    /**
     * Get mood label in Indonesian.
     */
    public function getMoodLabelAttribute(): string
    {
        return match ($this->mood) {
            'bahagia' => 'Bahagia',
            'biasa' => 'Biasa',
            'sedih' => 'Sedih',
            'sakit' => 'Sakit',
            'rewel' => 'Rewel',
            default => $this->mood ?? '-',
        };
    }

    /**
     * Get mood icon.
     */
    public function getMoodIconAttribute(): string
    {
        return match ($this->mood) {
            'bahagia' => '😊',
            'biasa' => '😐',
            'sedih' => '😢',
            'sakit' => '🤒',
            'rewel' => '😫',
            default => '😐',
        };
    }

    /**
     * Get meal rating stars.
     */
    public function getMealRatingStarsAttribute(): string
    {
        if (! $this->meal_rating) {
            return '-';
        }

        $fullStars = (int) $this->meal_rating;
        $halfStar = ($this->meal_rating - $fullStars) >= 0.5;

        $stars = str_repeat('⭐', $fullStars);
        if ($halfStar) {
            $stars .= '✨';
        }

        return $stars;
    }
}
