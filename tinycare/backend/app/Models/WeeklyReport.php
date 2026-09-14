<?php

namespace App\Models;

use Carbon\Carbon;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class WeeklyReport extends Model
{
    protected $fillable = [
        'child_id',
        'week_start',
        'week_end',
        'total_attendance',
        'total_activities',
        'total_daily_stories',
        'attendance_summary',
        'activity_summary',
        'development_summary',
        'overall_summary',
        'is_generated',
    ];

    protected $casts = [
        'week_start' => 'date',
        'week_end' => 'date',
        'total_attendance' => 'integer',
        'total_activities' => 'integer',
        'total_daily_stories' => 'integer',
        'is_generated' => 'boolean',
    ];

    public function child(): BelongsTo
    {
        return $this->belongsTo(Child::class);
    }

    /**
     * Generate weekly report for a child.
     */
    public static function generateForChild(Child $child, string $weekStart): self
    {
        $weekEnd = Carbon::parse($weekStart)->endOfWeek();

        // Get attendance count
        $attendance = $child->attendance()
            ->whereBetween('date', [$weekStart, $weekEnd])
            ->selectRaw('status, COUNT(*) as count')
            ->groupBy('status')
            ->get()
            ->pluck('count', 'status');

        // Get activities count
        $activitiesCount = $child->childActivities()
            ->whereBetween('date', [$weekStart, $weekEnd])
            ->count();

        // Get daily stories count
        $dailyStoriesCount = $child->dailyStories()
            ->whereBetween('date', [$weekStart, $weekEnd])
            ->count();

        // Get latest development assessments
        $developments = $child->developmentAssessments()
            ->with('category:id,name')
            ->whereBetween('observation_date', [$weekStart, $weekEnd])
            ->get()
            ->groupBy(fn ($a) => $a->category->name);

        // Development-focused summary. Attendance is no longer part of the
        // development report, so no "hadir X dari Y hari" text is generated.
        $developmentSummary = $developments->isEmpty()
            ? 'Belum ada penilaian perkembangan minggu ini.'
            : $developments
                ->map(fn ($items, $category) => '- '.$category.': '.$items->pluck('progress_label')->implode(', '))
                ->values()
                ->implode("\n");

        $overallSummary = $developments->isEmpty()
            ? "Perkembangan $child->name Minggu Ini\nBelum ada penilaian perkembangan minggu ini."
            : "Perkembangan $child->name Minggu Ini\n".$developmentSummary;

        return static::updateOrCreate(
            ['child_id' => $child->id, 'week_start' => $weekStart],
            [
                'week_end' => $weekEnd,
                'total_attendance' => $attendance->get('hadir', 0),
                'total_activities' => $activitiesCount,
                'total_daily_stories' => $dailyStoriesCount,
                'attendance_summary' => null,
                'activity_summary' => null,
                'development_summary' => $developmentSummary,
                'overall_summary' => $overallSummary,
                'is_generated' => true,
            ]
        );
    }

    /**
     * Get week label.
     */
    public function getWeekLabelAttribute(): string
    {
        return $this->week_start->locale('id')->isoFormat('D MMMM YYYY').
            ' - '.
            $this->week_end->locale('id')->isoFormat('D MMMM YYYY');
    }
}
