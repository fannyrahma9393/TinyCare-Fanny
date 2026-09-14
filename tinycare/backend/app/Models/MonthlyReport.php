<?php

namespace App\Models;

use Carbon\Carbon;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class MonthlyReport extends Model
{
    protected $fillable = [
        'child_id',
        'month',
        'year',
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
        'month' => 'integer',
        'year' => 'integer',
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
     * Generate monthly report for a child.
     */
    public static function generateForChild(Child $child, int $month, int $year): self
    {
        $startDate = Carbon::createFromDate($year, $month, 1)->startOfMonth();
        $endDate = $startDate->copy()->endOfMonth();

        // Get attendance count
        $attendance = $child->attendance()
            ->whereBetween('date', [$startDate, $endDate])
            ->selectRaw('status, COUNT(*) as count')
            ->groupBy('status')
            ->get()
            ->pluck('count', 'status');

        // Get activities count
        $activitiesCount = $child->childActivities()
            ->whereBetween('date', [$startDate, $endDate])
            ->count();

        // Get daily stories count
        $dailyStoriesCount = $child->dailyStories()
            ->whereBetween('date', [$startDate, $endDate])
            ->count();

        // Get development assessments
        $developments = $child->developmentAssessments()
            ->with('category:id,name')
            ->whereBetween('observation_date', [$startDate, $endDate])
            ->get()
            ->groupBy(fn ($a) => $a->category->name);

        $monthName = Carbon::createFromDate($year, $month, 1)->locale('id')->isoFormat('MMMM YYYY');

        // Development-focused summary. Attendance is no longer part of the
        // development report, so no "hadir X dari Y hari" text is generated.
        $developmentSummary = $developments->isEmpty()
            ? 'Belum ada penilaian perkembangan bulan ini.'
            : $developments
                ->map(fn ($items, $category) => '- '.$category.': '.$items->pluck('progress_label')->implode(', '))
                ->values()
                ->implode("\n");

        $overallSummary = $developments->isEmpty()
            ? "Perkembangan $child->name — $monthName\nBelum ada penilaian perkembangan bulan ini."
            : "Perkembangan $child->name — $monthName\n".$developmentSummary;

        return static::updateOrCreate(
            ['child_id' => $child->id, 'month' => $month, 'year' => $year],
            [
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
     * Get month label.
     */
    public function getMonthLabelAttribute(): string
    {
        return Carbon::createFromDate($this->year, $this->month, 1)
            ->locale('id')
            ->isoFormat('MMMM YYYY');
    }
}
