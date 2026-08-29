<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsToMany;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\Relations\MorphMany;

class Child extends Model
{
    protected $fillable = [
        'name',
        'birth_date',
        'gender',
        'photo',
        'address',
        'health_info',
        'emergency_contact_name',
        'emergency_contact_phone',
        'emergency_contact_relationship',
        'status',
    ];

    protected $casts = [
        'birth_date' => 'date',
    ];

    public function parents(): BelongsToMany
    {
        return $this->belongsToMany(ParentModel::class, 'parent_child', 'child_id', 'parent_id')
            ->withTimestamps();
    }

    public function childPackages(): HasMany
    {
        return $this->hasMany(ChildPackage::class);
    }

    public function attendance(): HasMany
    {
        return $this->hasMany(Attendance::class);
    }

    public function dailyStories(): HasMany
    {
        return $this->hasMany(DailyStory::class);
    }

    public function childActivities(): HasMany
    {
        return $this->hasMany(ChildActivity::class);
    }

    public function media(): MorphMany
    {
        return $this->morphMany(Media::class, 'mediable');
    }

    public function invoices(): HasMany
    {
        return $this->hasMany(Invoice::class);
    }

    public function developmentAssessments(): HasMany
    {
        return $this->hasMany(DevelopmentAssessment::class);
    }

    public function isActive(): bool
    {
        return $this->status === 'active';
    }

    /**
     * Get active package.
     */
    public function getActivePackage()
    {
        return $this->childPackages()
            ->with('package')
            ->where('status', 'active')
            ->first();
    }

    /**
     * Get today's daily story.
     */
    public function getTodayStory()
    {
        return $this->dailyStories()
            ->whereDate('date', now()->toDateString())
            ->first();
    }

    /**
     * Get today's attendance.
     */
    public function getTodayAttendance()
    {
        return $this->attendance()
            ->whereDate('date', now()->toDateString())
            ->first();
    }
}
