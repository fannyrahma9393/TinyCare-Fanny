<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Announcement;
use App\Models\User;
use App\Services\FcmNotificationService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class AnnouncementController extends Controller
{
    /**
     * Admin: list all announcements.
     */
    public function index(Request $request): JsonResponse
    {
        $query = Announcement::with('creator:id,name');

        // Filter by status
        if ($request->has('is_published')) {
            $query->where('is_published', $request->boolean('is_published'));
        }

        // Search
        if ($request->search) {
            $query->where('title', 'like', "%{$request->search}%")
                ->orWhere('content', 'like', "%{$request->search}%");
        }

        $announcements = $query->orderBy('created_at', 'desc')
            ->paginate($request->per_page ?? 15);

        return response()->json([
            'success' => true,
            'data' => $announcements,
        ]);
    }

    /**
     * Admin: create announcement.
     */
    public function store(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'title' => 'required|string|max:255',
            'content' => 'required|string|max:2000',
            'priority' => 'sometimes|in:low,normal,high,urgent',
            'publish_date' => 'nullable|date',
            'expire_date' => 'nullable|date|after_or_equal:publish_date',
            'is_published' => 'sometimes|boolean',
        ]);

        $validated['created_by'] = $request->user()->id;

        $announcement = Announcement::create($validated);

        // If published immediately, notify all active parents via FCM + DB notification.
        $notifyResult = null;
        if (! empty($validated['is_published'])) {
            $notifyResult = $this->notifyAllParents($announcement);
        }

        return response()->json([
            'success' => true,
            'message' => 'Pengumuman berhasil dibuat.',
            'data' => $announcement,
            'notify' => $notifyResult,
        ], 201);
    }

    /**
     * Admin: update announcement.
     */
    public function update(Request $request, Announcement $announcement): JsonResponse
    {
        $validated = $request->validate([
            'title' => 'sometimes|string|max:255',
            'content' => 'sometimes|string|max:2000',
            'priority' => 'sometimes|in:low,normal,high,urgent',
            'publish_date' => 'nullable|date',
            'expire_date' => 'nullable|date|after_or_equal:publish_date',
            'is_published' => 'sometimes|boolean',
        ]);

        $wasPublished = $announcement->is_published;
        $announcement->update($validated);

        // If newly published (was draft, now published), notify all parents.
        $notifyResult = null;
        if (! $wasPublished && ! empty($validated['is_published'])) {
            $notifyResult = $this->notifyAllParents($announcement);
        }

        return response()->json([
            'success' => true,
            'message' => 'Pengumuman berhasil diperbarui.',
            'data' => $announcement,
            'notify' => $notifyResult,
        ]);
    }

    /**
     * Admin: delete announcement.
     */
    public function destroy(Announcement $announcement): JsonResponse
    {
        $announcement->delete();

        return response()->json([
            'success' => true,
            'message' => 'Pengumuman berhasil dihapus.',
        ]);
    }

    /**
     * Send FCM push + DB notification to every active parent user.
     *
     * @return array{targeted_parents: int, fcm_sent: int, fcm_failed: int, fcm_configured: bool}
     */
    private function notifyAllParents(Announcement $announcement): array
    {
        $fcm = app(FcmNotificationService::class);
        $parentUsers = User::where('role', 'parent')
            ->where('status', 'active')
            ->get();

        $targeted = 0;
        $fcmSent = 0;
        $fcmFailed = 0;

        foreach ($parentUsers as $user) {
            // Create in-app database notification
            \App\Models\Notification::create([
                'user_id' => $user->id,
                'type' => 'announcement',
                'title' => 'Pengumuman Baru',
                'message' => $announcement->title,
                'link' => '/announcements',
                'data' => [
                    'type' => 'announcement',
                    'announcement_id' => $announcement->id,
                ],
            ]);

            $targeted++;

            // Send FCM push
            $result = $fcm->sendToUser(
                $user->id,
                'Pengumuman Baru',
                $announcement->title,
                '/announcements',
                [
                    'type' => 'announcement',
                    'announcement_id' => (string) $announcement->id,
                ]
            );

            $fcmSent += $result['success'];
            $fcmFailed += $result['failed'];
        }

        return [
            'targeted_parents' => $targeted,
            'fcm_sent' => $fcmSent,
            'fcm_failed' => $fcmFailed,
            'fcm_configured' => $fcm->isConfigured(),
        ];
    }

    /**
     * Parent: view published announcements.
     */
    public function parentIndex(Request $request): JsonResponse
    {
        $announcements = Announcement::where('is_published', true)
            ->where(function ($query) {
                $query->whereNull('publish_date')
                    ->orWhere('publish_date', '<=', now());
            })
            ->where(function ($query) {
                $query->whereNull('expire_date')
                    ->orWhere('expire_date', '>=', now());
            })
            ->orderBy('created_at', 'desc')
            ->paginate($request->per_page ?? 15);

        return response()->json([
            'success' => true,
            'data' => $announcements,
        ]);
    }
}
