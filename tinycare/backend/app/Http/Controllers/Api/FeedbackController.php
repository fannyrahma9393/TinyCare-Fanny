<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Support\TransKey;
use App\Models\Feedback;
use App\Services\FcmNotificationService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class FeedbackController extends Controller
{
    /**
     * Admin: list all feedback.
     */
    public function index(Request $request): JsonResponse
    {
        $query = Feedback::with(['parent.user', 'child', 'responder:id,name']);

        // Filter by status
        if ($request->status) {
            $query->where('status', $request->status);
        }

        $feedback = $query->orderBy('created_at', 'desc')
            ->paginate($request->per_page ?? 15);

        return response()->json([
            'success' => true,
            'data' => $feedback,
        ]);
    }

    /**
     * Parent: submit feedback.
     */
    public function store(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'child_id' => 'nullable|exists:children,id',
            'subject' => 'required|string|max:255',
            'message' => 'required|string|max:2000',
            'rating' => 'nullable|integer|min:1|max:5',
        ]);

        // Verify child ownership if provided
        if (isset($validated['child_id'])) {
            if (! $request->user()->parent->children->contains('id', $validated['child_id'])) {
                return response()->json([
                    'success' => false,
                    'message' => 'Tidak memiliki akses ke data anak ini.',
                ], 403);
            }
        }

        $feedback = Feedback::create([
            'parent_id' => $request->user()->parent->id,
            'child_id' => $validated['child_id'] ?? null,
            'subject' => $validated['subject'],
            'message' => $validated['message'],
            'rating' => $validated['rating'] ?? null,
            'status' => 'pending',
        ]);

        // Notify all active admins/admin_masters about new feedback (DB + FCM)
        $this->notifyAdminsFeedbackCreated($feedback, $request->user()->name);

        return response()->json([
            'success' => true,
            'message' => 'Feedback berhasil dikirim.',
            'data' => $feedback,
        ], 201);
    }

    /**
     * Admin: respond to feedback.
     */
    public function respond(Request $request, Feedback $feedback): JsonResponse
    {
        $validated = $request->validate([
            'admin_response' => 'required|string|max:2000',
        ]);

        $feedback->update([
            'admin_response' => $validated['admin_response'],
            'status' => 'responded',
            'responded_by' => $request->user()->id,
            'responded_at' => now(),
        ]);

        // Notify the parent that their feedback was replied to (DB + FCM)
        $this->notifyParentFeedbackReplied($feedback);

        return response()->json([
            'success' => true,
            'message' => 'Feedback berhasil dijawab.',
            'data' => $feedback->load(['parent.user', 'child', 'responder:id,name']),
        ]);
    }

    /**
     * Admin: update feedback status.
     */
    public function updateStatus(Request $request, Feedback $feedback): JsonResponse
    {
        $validated = $request->validate([
            'status' => 'required|in:pending,reviewed,responded',
        ]);

        $feedback->update(['status' => $validated['status']]);

        return response()->json([
            'success' => true,
            'message' => 'Status feedback diperbarui.',
        ]);
    }

    /**
     * Parent: view own feedback.
     */
    public function parentIndex(Request $request): JsonResponse
    {
        $feedback = Feedback::where('parent_id', $request->user()->parent->id)
            ->with('child:id,name')
            ->orderBy('created_at', 'desc')
            ->paginate($request->per_page ?? 15);

        return response()->json([
            'success' => true,
            'data' => $feedback,
        ]);
    }

    /**
     * Notify all active admins/admin_masters about a new feedback.
     */
    private function notifyAdminsFeedbackCreated(Feedback $feedback, string $parentName): void
    {
        $fcm = app(FcmNotificationService::class);
        $fcm->notifyAdmins(
            [
                'type' => 'feedback_created',
                'title' => TransKey::t('notif.feedback.created.title', [], 'Feedback Baru'),
                'message' => TransKey::t('notif.feedback.created', ['parent_name' => $parentName, 'subject' => $feedback->subject], "{$parentName} mengirim feedback: {$feedback->subject}"),
                'link' => '/feedback',
                'data' => [
                    'type' => 'feedback_created',
                    'feedback_id' => (string) $feedback->id,
                ],
            ],
            TransKey::t('notif.feedback.created.title', [], 'Feedback Baru'),
            TransKey::t('notif.feedback.created', ['parent_name' => $parentName, 'subject' => $feedback->subject], "{$parentName} mengirim feedback: {$feedback->subject}"),
            '/feedback',
            [
                'type' => 'feedback_created',
                'feedback_id' => (string) $feedback->id,
            ]
        );
    }

    /**
     * Notify the parent that their feedback was replied to.
     */
    private function notifyParentFeedbackReplied(Feedback $feedback): void
    {
        $parent = $feedback->parent;
        $user = $parent?->user;
        if (! $user || $user->status !== 'active') {
            return;
        }

        $fcm = app(FcmNotificationService::class);
        $fcm->notifyUser(
            $user,
            [
                'type' => 'feedback_replied',
                'title' => TransKey::t('notif.feedback.replied.title', [], 'Feedback Dibalas'),
                'message' => TransKey::t('notif.feedback.replied', ['subject' => $feedback->subject], "Admin menjawab feedback Anda: {$feedback->subject}"),
                'link' => '/feedback',
                'data' => [
                    'type' => 'feedback_replied',
                    'feedback_id' => (string) $feedback->id,
                ],
            ],
            TransKey::t('notif.feedback.replied.title', [], 'Feedback Dibalas'),
            TransKey::t('notif.feedback.replied', ['subject' => $feedback->subject], "Admin menjawab feedback Anda: {$feedback->subject}"),
            '/feedback',
            [
                'type' => 'feedback_replied',
                'feedback_id' => (string) $feedback->id,
            ]
        );
    }
}
