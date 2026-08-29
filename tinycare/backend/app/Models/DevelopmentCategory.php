<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;

class DevelopmentCategory extends Model
{
    protected $fillable = [
        'name',
        'description',
        'icon',
        'sort_order',
        'status',
    ];

    public function assessments(): HasMany
    {
        return $this->hasMany(DevelopmentAssessment::class);
    }

    public function notes(): HasMany
    {
        return $this->hasMany(DevelopmentNote::class);
    }

    public function isActive(): bool
    {
        return $this->status === 'active';
    }

    /**
     * Get icon for category.
     */
    public function getIconAttribute(): string
    {
        return match ($this->attributes['icon'] ?? $this->name) {
            'motorik' => '🏃',
            'bahasa' => '💬',
            'sosial' => '👫',
            'kognitif' => '🧠',
            'kemandirian' => 'Independence',
            default => $this->attributes['icon'] ?? '📊',
        };
    }
}
