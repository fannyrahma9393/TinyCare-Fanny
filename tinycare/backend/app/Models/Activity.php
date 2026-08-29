<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Activity extends Model
{
    protected $fillable = [
        'name',
        'description',
        'category',
        'status',
    ];

    public function childActivities(): HasMany
    {
        return $this->hasMany(ChildActivity::class);
    }

    public function isActive(): bool
    {
        return $this->status === 'active';
    }

    /**
     * Get category label.
     */
    public function getCategoryLabelAttribute(): string
    {
        return match ($this->category) {
            'edukasi' => 'Edukasi',
            'bermain' => 'Bermain',
            'olahraga' => 'Olahraga',
            'seni' => 'Seni',
            'makan' => 'Makan',
            'istirahat' => 'Istirahat',
            default => $this->category ?? '-',
        };
    }
}
