<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Attendance;
use App\Models\Child;
use Carbon\Carbon;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class AttendanceController extends Controller
{
    /**
     * Admin: list attendance records.
     */
    public function index(Request $request): JsonResponse
    {
        $query = Attendance::with(['child', 'recorder']);

        // Filter by date
        if ($request->date) {
            $query->whereDate('date', $request->date);
        } else {
            // Default to today
            $query->whereDate('date', Carbon::today());
        }

        // Filter by status
        if ($request->status) {
            $query->where('status', $request->status);
        }

        // Search by child name
        if ($request->search) {
            $query->whereHas('child', function ($q) use ($request) {
                $q->where('name', 'like', "%{$request->search}%");
            });
        }

        $attendance = $query->orderBy('date', 'desc')
            ->orderBy('check_in_time', 'desc')
            ->paginate($request->per_page ?? 15);

        return response()->json([
            'success' => true,
            'data' => $attendance,
        ]);
    }

    /**
     * Admin: record attendance (create or update).
     */
    public function store(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'child_id' => 'required|exists:children,id',
            'date' => 'required|date',
            'status' => 'required|in:hadir,izin,sakit,tidak_hadir',
            'check_in_time' => 'nullable|date_format:H:i',
            'check_out_time' => 'nullable|date_format:H:i',
            'notes' => 'nullable|string|max:500',
        ]);

        // Check if attendance already exists for this child on this date
        $existing = Attendance::where('child_id', $validated['child_id'])
            ->whereDate('date', $validated['date'])
            ->first();

        if ($existing) {
            // Update existing attendance
            $existing->update([
                'status' => $validated['status'],
                'check_in_time' => $validated['check_in_time'] ?? $existing->check_in_time,
                'check_out_time' => $validated['check_out_time'] ?? $existing->check_out_time,
                'recorded_by' => $request->user()->id,
                'notes' => $validated['notes'] ?? $existing->notes,
            ]);

            $existing->load(['child', 'recorder']);

            return response()->json([
                'success' => true,
                'message' => 'Kehadiran berhasil diperbarui.',
                'data' => $existing,
            ]);
        }

        // Create new attendance
        $attendance = Attendance::create([
            'child_id' => $validated['child_id'],
            'date' => $validated['date'],
            'status' => $validated['status'],
            'check_in_time' => $validated['check_in_time'] ?? null,
            'check_out_time' => $validated['check_out_time'] ?? null,
            'recorded_by' => $request->user()->id,
            'notes' => $validated['notes'] ?? null,
        ]);

        $attendance->load(['child', 'recorder']);

        return response()->json([
            'success' => true,
            'message' => 'Kehadiran berhasil dicatat.',
            'data' => $attendance,
        ], 201);
    }

    /**
     * Admin: update attendance.
     */
    public function update(Request $request, Attendance $attendance): JsonResponse
    {
        $validated = $request->validate([
            'status' => 'sometimes|in:hadir,izin,sakit,tidak_hadir',
            'check_in_time' => 'nullable|date_format:H:i',
            'check_out_time' => 'nullable|date_format:H:i',
            'notes' => 'nullable|string|max:500',
        ]);

        $validated['recorded_by'] = $request->user()->id;

        $attendance->update($validated);
        $attendance->load(['child', 'recorder']);

        return response()->json([
            'success' => true,
            'message' => 'Kehadiran berhasil diperbarui.',
            'data' => $attendance,
        ]);
    }

    /**
     * Parent: view child's attendance.
     */
    public function parentChildAttendance(Request $request, Child $child): JsonResponse
    {
        // Verify ownership
        if (! $request->user()->parent->children->contains('id', $child->id)) {
            return response()->json([
                'success' => false,
                'message' => 'Tidak memiliki akses ke data anak ini.',
            ], 403);
        }

        $query = $child->attendance()
            ->with('recorder:id,name');

        // Filter by month/year
        if ($request->month && $request->year) {
            $query->whereMonth('date', $request->month)
                ->whereYear('date', $request->year);
        }

        $attendance = $query->orderBy('date', 'desc')
            ->paginate($request->per_page ?? 30);

        // Calculate summary
        $summary = $child->attendance()
            ->when($request->month && $request->year, function ($q) use ($request) {
                $q->whereMonth('date', $request->month)
                    ->whereYear('date', $request->year);
            })
            ->selectRaw('status, COUNT(*) as count')
            ->groupBy('status')
            ->get()
            ->pluck('count', 'status');

        return response()->json([
            'success' => true,
            'data' => [
                'attendance' => $attendance,
                'summary' => [
                    'hadir' => $summary->get('hadir', 0),
                    'izin' => $summary->get('izin', 0),
                    'sakit' => $summary->get('sakit', 0),
                    'tidak_hadir' => $summary->get('tidak_hadir', 0),
                ],
            ],
        ]);
    }
}
