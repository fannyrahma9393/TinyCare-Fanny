<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Child;
use App\Models\MonthlyReport;
use App\Models\WeeklyReport;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class ReportController extends Controller
{
    /**
     * Admin: generate weekly report for a child.
     */
    public function generateWeekly(Request $request, Child $child): JsonResponse
    {
        $validated = $request->validate([
            'week_start' => 'required|date',
        ]);

        $report = WeeklyReport::generateForChild($child, $validated['week_start']);
        $report->load('child:id,name');

        return response()->json([
            'success' => true,
            'message' => 'Laporan mingguan berhasil dibuat.',
            'data' => $report,
        ]);
    }

    /**
     * Admin: generate monthly report for a child.
     */
    public function generateMonthly(Request $request, Child $child): JsonResponse
    {
        $validated = $request->validate([
            'month' => 'required|integer|min:1|max:12',
            'year' => 'required|integer|min:2020|max:2030',
        ]);

        $report = MonthlyReport::generateForChild($child, $validated['month'], $validated['year']);
        $report->load('child:id,name');

        return response()->json([
            'success' => true,
            'message' => 'Laporan bulanan berhasil dibuat.',
            'data' => $report,
        ]);
    }

    /**
     * Admin: list weekly reports.
     */
    public function weeklyIndex(Request $request): JsonResponse
    {
        $query = WeeklyReport::with('child:id,name');

        if ($request->child_id) {
            $query->where('child_id', $request->child_id);
        }

        $reports = $query->orderBy('week_start', 'desc')
            ->paginate($request->per_page ?? 15);

        return response()->json([
            'success' => true,
            'data' => $reports,
        ]);
    }

    /**
     * Admin: list monthly reports.
     */
    public function monthlyIndex(Request $request): JsonResponse
    {
        $query = MonthlyReport::with('child:id,name');

        if ($request->child_id) {
            $query->where('child_id', $request->child_id);
        }

        if ($request->month) {
            $query->where('month', $request->month);
        }

        if ($request->year) {
            $query->where('year', $request->year);
        }

        $reports = $query->orderBy('year', 'desc')
            ->orderBy('month', 'desc')
            ->paginate($request->per_page ?? 15);

        return response()->json([
            'success' => true,
            'data' => $reports,
        ]);
    }

    /**
     * Parent: view child's weekly reports.
     */
    public function parentWeekly(Request $request, Child $child): JsonResponse
    {
        // Verify ownership
        if (! $request->user()->parent->children->contains('id', $child->id)) {
            return response()->json([
                'success' => false,
                'message' => 'Tidak memiliki akses ke data anak ini.',
            ], 403);
        }

        $reports = WeeklyReport::where('child_id', $child->id)
            ->orderBy('week_start', 'desc')
            ->paginate($request->per_page ?? 10);

        return response()->json([
            'success' => true,
            'data' => $reports,
        ]);
    }

    /**
     * Parent: view child's monthly reports.
     */
    public function parentMonthly(Request $request, Child $child): JsonResponse
    {
        // Verify ownership
        if (! $request->user()->parent->children->contains('id', $child->id)) {
            return response()->json([
                'success' => false,
                'message' => 'Tidak memiliki akses ke data anak ini.',
            ], 403);
        }

        $reports = MonthlyReport::where('child_id', $child->id)
            ->orderBy('year', 'desc')
            ->orderBy('month', 'desc')
            ->paginate($request->per_page ?? 12);

        return response()->json([
            'success' => true,
            'data' => $reports,
        ]);
    }
}
