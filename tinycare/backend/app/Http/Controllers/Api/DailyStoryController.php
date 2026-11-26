<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Child;
use App\Models\DailyStory;
use App\Services\FcmNotificationService;
use App\Support\TransKey;
use Carbon\Carbon;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class DailyStoryController extends Controller
{
    /**
     * Admin: list daily stories with filters.
     */
    public function index(Request $request): JsonResponse
    {
        $query = DailyStory::with(['child', 'creator', 'media']);

        // Filter by date (default: today)
        $date = $request->date ?? Carbon::today()->toDateString();
        $query->whereDate('date', $date);

        // Filter by child
        if ($request->child_id) {
            $query->where('child_id', $request->child_id);
        }

        // Search by child name
        if ($request->search) {
            $query->whereHas('child', function ($q) use ($request) {
                $q->where('name', 'like', "%{$request->search}%");
            });
        }

        $stories = $query->orderBy('created_at', 'desc')
            ->paginate($request->per_page ?? 15);

        return response()->json([
            'success' => true,
            'data' => $stories,
        ]);
    }

    /**
     * Admin: create daily story for a child.
     */
    public function store(Request $request, Child $child): JsonResponse
    {
        $validated = $request->validate([
            'date' => 'required|date',
            'summary' => 'nullable|string|max:2000',
            'mood' => 'nullable|in:bahagia,biasa,sedih,sakit,rewel',
            'meal_notes' => 'nullable|string|max:1000',
            'sleep_notes' => 'nullable|string|max:1000',
            'admin_notes' => 'nullable|string|max:1000',
            'meal_rating' => 'nullable|numeric|min:1|max:5',
            'sleep_hours' => 'nullable|numeric|min:0|max:24',
        ]);

        // Check if daily story already exists for this child on this date
        $existing = DailyStory::where('child_id', $child->id)
            ->whereDate('date', $validated['date'])
            ->first();

        if ($existing) {
            return response()->json([
                'success' => false,
                'message' => 'Daily Story untuk anak ini pada tanggal tersebut sudah ada. Gunakan update.',
            ], 400);
        }

        $validated['child_id'] = $child->id;
        $validated['created_by'] = $request->user()->id;

        $story = DailyStory::create($validated);
        $story->load(['child', 'creator', 'media']);

        // Notify parent(s) of this child (DB + FCM push). FCM failure must NOT
        // abort the story save.
        $notify = app(FcmNotificationService::class)->notifyChildParents(
            $child,
            [
                'type' => 'daily_story',
                'title' => TransKey::t('notif.daily_story.db_title', ['child_name' => $child->name ?? ''], 'Daily Story '.($child->name ?? 'Anak')),
                'message' => $validated['summary']
                    ?: TransKey::t('notif.daily_story.db_body', ['child_name' => $child->name ?? 'anak Anda'], 'Daily Story untuk '.($child->name ?? 'anak Anda').' telah dibuat.'),
                'link' => '/parent/children/'.$child->id.'/daily-stories',
                'data' => [
                    'type' => 'daily_story',
                    'child_id' => $child->id,
                ],
            ],
            TransKey::t('notif.daily_story.title', [], 'Daily Story'),
            TransKey::t('notif.daily_story.body', ['child_name' => $child->name ?? 'anak Anda'], 'Daily Story baru untuk '.($child->name ?? 'anak Anda').'.'),
            '/parent/children/'.$child->id.'/daily-stories',
            [
                'type' => 'daily_story',
                'child_id' => (string) $child->id,
            ]
        );

        return response()->json([
            'success' => true,
            'message' => 'Daily Story berhasil dibuat.',
            'notify' => $notify,
            'data' => $story,
        ], 201);
    }

    /**
     * Admin: update daily story.
     */
    public function update(Request $request, DailyStory $dailyStory): JsonResponse
    {
        $validated = $request->validate([
            'summary' => 'nullable|string|max:2000',
            'mood' => 'nullable|in:bahagia,biasa,sedih,sakit,rewel',
            'meal_notes' => 'nullable|string|max:1000',
            'sleep_notes' => 'nullable|string|max:1000',
            'admin_notes' => 'nullable|string|max:1000',
            'meal_rating' => 'nullable|numeric|min:1|max:5',
            'sleep_hours' => 'nullable|numeric|min:0|max:24',
        ]);

        $dailyStory->update($validated);
        $dailyStory->load(['child', 'creator', 'media']);

        return response()->json([
            'success' => true,
            'message' => 'Daily Story berhasil diperbarui.',
            'data' => $dailyStory,
        ]);
    }

    /**
     * Parent: view daily stories for a child.
     */
    public function parentIndex(Request $request, Child $child): JsonResponse
    {
        // Verify ownership
        if (! $request->user()->parent->children->contains('id', $child->id)) {
            return response()->json([
                'success' => false,
                'message' => 'Tidak memiliki akses ke data anak ini.',
            ], 403);
        }

        $query = $child->dailyStories()
            ->with(['media', 'creator:id,name']);

        // Filter by month/year
        if ($request->month && $request->year) {
            $query->whereMonth('date', $request->month)
                ->whereYear('date', $request->year);
        }

        $stories = $query->orderBy('date', 'desc')
            ->paginate($request->per_page ?? 15);

        return response()->json([
            'success' => true,
            'data' => $stories,
        ]);
    }

    /**
     * Parent: view specific daily story by date.
     */
    public function parentShowByDate(Request $request, Child $child, string $date): JsonResponse
    {
        // Verify ownership
        if (! $request->user()->parent->children->contains('id', $child->id)) {
            return response()->json([
                'success' => false,
                'message' => 'Tidak memiliki akses ke data anak ini.',
            ], 403);
        }

        $story = $child->dailyStories()
            ->with(['media', 'creator:id,name'])
            ->whereDate('date', $date)
            ->first();

        if (! $story) {
            return response()->json([
                'success' => false,
                'message' => 'Daily Story tidak ditemukan untuk tanggal ini.',
            ], 404);
        }

        // Get activities for this day
        $activities = $child->childActivities()
            ->with('activity')
            ->whereDate('date', $date)
            ->orderBy('time')
            ->get();

        return response()->json([
            'success' => true,
            'data' => [
                'story' => $story,
                'activities' => $activities,
            ],
        ]);
    }
}
