<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class AuthorizedPickup extends Model
{
    protected $fillable = [
        'parent_id',
        'child_id',
        'name',
        'phone',
        'relationship',
        'id_number',
        'photo',
        'status',
        'notes',
    ];

    public function parent(): BelongsTo
    {
        return $this->belongsTo(ParentModel::class);
    }

    public function child(): BelongsTo
    {
        return $this->belongsTo(Child::class);
    }

    /**
     * Check if pickup is active.
     */
    public function isActive(): bool
    {
        return $this->status === 'active';
    }

    /**
     * Get relationship label.
     */
    public function getRelationshipLabelAttribute(): string
    {
        return match ($this->relationship) {
            'ayah' => 'Ayah',
            'ibu' => 'Ibu',
            'paman' => 'Paman',
            'bibi' => 'Bibi',
            'kakek' => 'Kakek',
            'nenek' => 'Nenek',
            'lainnya' => 'Lainnya',
            default => $this->relationship,
        };
    }
}
