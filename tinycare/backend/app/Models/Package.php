<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Package extends Model
{
    protected $fillable = [
        'name',
        'description',
        'price',
        'duration_days',
        'facilities',
        'quota',
        'status',
        'start_date',
        'end_date',
    ];

    protected $casts = [
        'price' => 'decimal:2',
        'duration_days' => 'integer',
        'quota' => 'integer',
        'start_date' => 'date',
        'end_date' => 'date',
    ];

    public function childPackages(): HasMany
    {
        return $this->hasMany(ChildPackage::class);
    }

    public function children()
    {
        return $this->belongsToMany(Child::class, 'child_packages')
            ->withPivot(['start_date', 'end_date', 'status'])
            ->withTimestamps();
    }

    public function isActive(): bool
    {
        return $this->status === 'active';
    }

    public function hasAvailableQuota(): bool
    {
        if ($this->quota === null) {
            return true; // unlimited
        }

        $activeEnrollments = $this->childPackages()
            ->where('status', 'active')
            ->count();

        return $activeEnrollments < $this->quota;
    }
}
