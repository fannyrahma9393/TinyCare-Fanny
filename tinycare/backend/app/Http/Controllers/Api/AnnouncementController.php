<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Announcement;
use App\Models\Child;
use App\Models\User;
use App\Services\FcmNotificationService;
use App\Support\TransKey;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Collection;

class AnnouncementController extends Controller
{
    /**
     * Admin: list all announcements.
     */
    public function index(Request $request): JsonResponse
    {
        $query = Announcement::with(['creator:id,name', 'children:id,name', 'parents:id,user_id,phone', 'parents.user:id,name']);

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
            'child_ids' => 'nullable|array',
            'child_ids.*' => 'exists:children,id',
            'parent_ids' => 'nullable|array',
            'parent_ids.*' => 'exists:parents,id',
        ]);

        $validated['created_by'] = $request->user()->id;

        $announcement = Announcement::create($validated);

        if (! empty($validated['child_ids'])) {
            $announcement->children()->sync($validated['child_ids']);
        }

        if (! empty($validated['parent_ids'])) {
            $announcement->parents()->sync($validated['parent_ids']);
        }

        // If published immediately, notify the targeted parents via FCM + DB
        // notification (all active parents when no children are targeted).
        $notifyResult = null;
        if (! empty($validated['is_published'])) {
            $notifyResult = $this->notifyTargetedParents($announcement);
        }

        return response()->json([
            'success' => true,
            'message' => 'Pengumuman berhasil dibuat.',
            'data' => $announcement->load(['children:id,name', 'parents:id,user_id,phone', 'parents.user:id,name']),
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
            'child_ids' => 'nullable|array',
            'child_ids.*' => 'exists:children,id',
            'parent_ids' => 'nullable|array',
            'parent_ids.*' => 'exists:parents,id',
        ]);

        $wasPublished = $announcement->is_published;
        $announcement->update($validated);

        // Update targeting: empty array clears targets (becomes broadcast).
        if ($request->exists('child_ids')) {
            $announcement->children()->sync($validated['child_ids'] ?? []);
        }

        if ($request->exists('parent_ids')) {
            $announcement->parents()->sync($validated['parent_ids'] ?? []);
        }

        // If newly published (was draft, now published), notify targets.
        $notifyResult = null;
        if (! $wasPublished && ! empty($validated['is_published'])) {
            $notifyResult = $this->notifyTargetedParents($announcement);
        }

        return response()->json([
            'success' => true,
            'message' => 'Pengumuman berhasil diperbarui.',
            'data' => $announcement->load(['children:id,name', 'parents:id,user_id,phone', 'parents.user:id,name']),
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
     * Send FCM push + DB notification for a published announcement.
     *
     * Targets are resolved as:
     *  - direct parent targets (announcement_parent pivot) — the listed
     *    parents themselves, plus
     *  - child targets (announcement_child pivot) — the parents of the listed
     *    children.
     * Parents are de-duplicated (one notification per parent even when a
     * parent appears through several targets). When neither pivot has rows,
     * every active parent is notified (existing broadcast).
     *
     * @return array{targeted_parents: int, fcm_sent: int, fcm_failed: int, fcm_configured: bool}
     */
    private function notifyTargetedParents(Announcement $announcement): array
    {
        $announcement->load(['children.parents.user', 'parents.user']);

        $hasTargets = $announcement->children->isNotEmpty() || $announcement->parents->isNotEmpty();

        if ($hasTargets) {
            $parentUsers = $announcement->children
                ->flatMap(fn (Child $child) => $child->parents)
                ->concat($announcement->parents)
                ->unique('id')
                ->map->user
                ->filter(fn ($user) => $user && $user->status === 'active')
                ->values();
        } else {
            $parentUsers = User::whereHas('role', fn ($q) => $q->where('name', 'parent'))
                ->where('status', 'active')
                ->get();
        }

        return $this->notifyParentUsers($parentUsers, $announcement);
    }

    /**
     * Create in-app DB notification + FCM push for a set of parent users.
     *
     * @param  Collection<int, User>  $parentUsers
     * @return array{targeted_parents: int, fcm_sent: int, fcm_failed: int, fcm_configured: bool}
     */
    private function notifyParentUsers(Collection $parentUsers, Announcement $announcement): array
    {
        $fcm = app(FcmNotificationService::class);

        $targeted = 0;
        $fcmSent = 0;
        $fcmFailed = 0;

        foreach ($parentUsers as $user) {
            // Create in-app database notification
            \App\Models\Notification::create([
                'user_id' => $user->id,
                'type' => 'announcement',
                'title' => TransKey::t('notif.announcement.title', [], 'Pengumuman Baru'),
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
                TransKey::t('notif.announcement.title', [], 'Pengumuman Baru'),
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
     * Parent: view published announcements visible to the requesting parent.
     * Visibility is enforced on the backend (broadcast, direct parent target
     * or parent of a targeted child).
     */
    public function parentIndex(Request $request): JsonResponse
    {
        [$parentId, $childIds] = $this->parentTargetContext($request);

        $announcements = Announcement::visibleToParent($parentId, $childIds)
            ->orderBy('created_at', 'desc')
            ->paginate($request->per_page ?? 15);

        return response()->json([
            'success' => true,
            'data' => $announcements,
        ]);
    }

    /**
     * Parent: view a single announcement. Returns 404 when the announcement is
     * not visible to the requesting parent (never leaks existence).
     */
    public function parentShow(Request $request, Announcement $announcement): JsonResponse
    {
        [$parentId, $childIds] = $this->parentTargetContext($request);

        $visible = Announcement::whereKey($announcement->id)
            ->visibleToParent($parentId, $childIds)
            ->exists();

        if (! $visible) {
            return response()->json([
                'success' => false,
                'message' => 'Pengumuman tidak ditemukan.',
            ], 404);
        }

        return response()->json([
            'success' => true,
            'data' => $announcement,
        ]);
    }

    /**
     * Resolve the parent model id + child ids used for visibility checks.
     *
     * @return array{0: int|null, 1: array<int, int>}
     */
    private function parentTargetContext(Request $request): array
    {
        $parent = $request->user()->parent;

        if (! $parent) {
            return [null, []];
        }

        $childIds = $parent->children()->pluck('children.id')->map(fn ($id) => (int) $id)->all();

        return [$parent->id, $childIds];
    }
}
