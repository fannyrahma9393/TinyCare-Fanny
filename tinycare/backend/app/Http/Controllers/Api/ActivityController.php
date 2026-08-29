<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Activity;
use App\Models\Child;
use App\Models\ChildActivity;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class ActivityController extends Controller
{
    /**
     * Admin: list master activities.
     */
    public function index(Request $request): JsonResponse
    {
        $activities = Activity::when($request->search, function ($query, $search) {
            $query->where('name', 'like', "%{$search}%")
                ->orWhere('category', 'like', "%{$search}%");
        })
            ->when($request->category, function ($query, $category) {
                $query->where('category', $category);
            })
            ->orderBy('name')
            ->paginate($request->per_page ?? 50);

        return response()->json([
            'success' => true,
            'data' => $activities,
        ]);
    }

    /**
     * Admin: create master activity.
     */
    public function store(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'name' => 'required|string|max:255',
            'description' => 'nullable|string|max:500',
            'category' => 'nullable|string|max:100',
        ]);

        $activity = Activity::create($validated);

        return response()->json([
            'success' => true,
            'message' => 'Aktivitas berhasil ditambahkan.',
            'data' => $activity,
        ], 201);
    }

    /**
     * Admin: update master activity.
     */
    public function update(Request $request, Activity $activity): JsonResponse
    {
        $validated = $request->validate([
            'name' => 'sometimes|string|max:255',
            'description' => 'nullable|string|max:500',
            'category' => 'nullable|string|max:100',
            'status' => 'sometimes|in:active,inactive',
        ]);

        $activity->update($validated);

        return response()->json([
            'success' => true,
            'message' => 'Aktivitas berhasil diperbarui.',
            'data' => $activity,
        ]);
    }

    /**
     * Admin: delete master activity.
     */
    public function destroy(Activity $activity): JsonResponse
    {
        // Check if activity has been used
        if ($activity->childActivities()->count() > 0) {
            return response()->json([
                'success' => false,
                'message' => 'Tidak dapat menghapus aktivitas yang sudah digunakan.',
            ], 400);
        }

        $activity->delete();

        return response()->json([
            'success' => true,
            'message' => 'Aktivitas berhasil dihapus.',
        ]);
    }

    /**
     * Admin: record child activity.
     */
    public function storeChildActivity(Request $request, Child $child): JsonResponse
    {
        $validated = $request->validate([
            'activity_id' => 'required|exists:activities,id',
            'date' => 'required|date',
            'time' => 'nullable|date_format:H:i',
            'status' => 'nullable|in:selesai,sedang_berlangsung,tidak_hadir',
            'notes' => 'nullable|string|max:500',
        ]);

        $childActivity = ChildActivity::create([
            'child_id' => $child->id,
            'activity_id' => $validated['activity_id'],
            'date' => $validated['date'],
            'time' => $validated['time'] ?? null,
            'status' => $validated['status'] ?? 'selesai',
            'notes' => $validated['notes'] ?? null,
        ]);

        $childActivity->load(['child', 'activity']);

        return response()->json([
            'success' => true,
            'message' => 'Aktivitas anak berhasil dicatat.',
            'data' => $childActivity,
        ], 201);
    }

    /**
     * Parent: view child activities.
     */
    public function parentChildActivities(Request $request, Child $child): JsonResponse
    {
        // Verify ownership
        if (! $request->user()->parent->children->contains('id', $child->id)) {
            return response()->json([
                'success' => false,
                'message' => 'Tidak memiliki akses ke data anak ini.',
            ], 403);
        }

        $query = $child->childActivities()
            ->with('activity');

        // Filter by date
        if ($request->date) {
            $query->whereDate('date', $request->date);
        }

        // Filter by month/year
        if ($request->month && $request->year) {
            $query->whereMonth('date', $request->month)
                ->whereYear('date', $request->year);
        }

        $activities = $query->orderBy('date', 'desc')
            ->orderBy('time')
            ->paginate($request->per_page ?? 30);

        return response()->json([
            'success' => true,
            'data' => $activities,
        ]);
    }
}
