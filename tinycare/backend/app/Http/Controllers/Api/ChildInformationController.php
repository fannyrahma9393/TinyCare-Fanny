<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Child;
use App\Models\ChildInformation;
use App\Services\FcmNotificationService;
use App\Support\TransKey;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class ChildInformationController extends Controller
{
    /**
     * Admin: List all child information, optionally filtered by child_id.
     */
    public function index(Request $request): JsonResponse
    {
        $query = ChildInformation::with(['child', 'parent.user', 'creator'])
            ->orderBy('created_at', 'desc');

        if ($request->child_id) {
            $query->where('child_id', $request->child_id);
        }

        if ($request->priority) {
            $query->where('priority', $request->priority);
        }

        $informations = $query->paginate($request->per_page ?? 15);

        return response()->json([
            'success' => true,
            'data' => $informations,
        ]);
    }

    /**
     * Admin: Store new child information and notify parent(s).
     */
    public function store(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'child_id' => 'required|exists:children,id',
            'parent_id' => 'nullable|exists:parents,id',
            'title' => 'required|string|max:255',
            'content' => 'required|string',
            'priority' => 'sometimes|in:normal,important,urgent',
        ]);

        $information = ChildInformation::create([
            'child_id' => $validated['child_id'],
            'parent_id' => $validated['parent_id'] ?? null,
            'created_by' => $request->user()->id,
            'title' => $validated['title'],
            'content' => $validated['content'],
            'priority' => $validated['priority'] ?? 'normal',
        ]);

        // Send notification (DB + FCM push) to the parent(s) of this child.
        // FCM failure must NEVER abort the information save.
        $child = Child::find($validated['child_id']);
        $fcm = app(FcmNotificationService::class);

        $onlyParentId = (! empty($validated['parent_id'])) ? (int) $validated['parent_id'] : null;

        $notify = $fcm->notifyChildParents(
            $child,
            [
                'type' => 'child_information',
                'title' => TransKey::t('notif.child_information.db_title', ['child_name' => $child->name ?? ''], 'Informasi untuk '.($child->name ?? '')),
                'message' => $validated['title'],
                'link' => '/parent/children/'.$child->id.'/information',
                'data' => [
                    'type' => 'child_information',
                    'child_id' => $child->id,
                    'information_id' => $information->id,
                ],
            ],
            TransKey::t('notif.child_information.title', [], 'Informasi Anak'),
            TransKey::t('notif.child_information.body', ['child_name' => $child->name ?? 'anak Anda'], 'Informasi baru tentang '.($child->name ?? 'anak Anda').' telah ditambahkan.'),
            '/parent/information',
            [
                'type' => 'child_information',
                'child_id' => (string) $child->id,
                'information_id' => (string) $information->id,
            ],
            $onlyParentId
        );

        return response()->json([
            'success' => true,
            'message' => 'Informasi anak berhasil dibuat.',
            'notify' => $notify,
            'data' => $information->load(['child', 'parent.user', 'creator']),
        ], 201);
    }

    /**
     * Admin: Show single information detail.
     */
    public function show(ChildInformation $childInformation): JsonResponse
    {
        return response()->json([
            'success' => true,
            'data' => $childInformation->load(['child', 'parent.user', 'creator']),
        ]);
    }

    /**
     * Admin: Update child information.
     */
    public function update(Request $request, ChildInformation $childInformation): JsonResponse
    {
        $validated = $request->validate([
            'title' => 'sometimes|string|max:255',
            'content' => 'sometimes|string',
            'priority' => 'sometimes|in:normal,important,urgent',
            'status' => 'sometimes|in:active,archived',
        ]);

        $childInformation->update($validated);

        return response()->json([
            'success' => true,
            'message' => 'Informasi anak berhasil diperbarui.',
            'data' => $childInformation->load(['child', 'parent.user', 'creator']),
        ]);
    }

    /**
     * Admin: Delete child information.
     */
    public function destroy(ChildInformation $childInformation): JsonResponse
    {
        $childInformation->delete();

        return response()->json([
            'success' => true,
            'message' => 'Informasi anak berhasil dihapus.',
        ]);
    }

    /**
     * Parent: List information for own children.
     */
    public function parentIndex(Request $request): JsonResponse
    {
        $parent = $request->user()->parent;
        $childIds = $parent->children()->pluck('children.id');

        $query = ChildInformation::with(['child', 'creator'])
            ->whereIn('child_id', $childIds)
            ->orderBy('created_at', 'desc');

        if ($request->child_id) {
            $query->where('child_id', $request->child_id);
        }

        $informations = $query->paginate($request->per_page ?? 15);

        return response()->json([
            'success' => true,
            'data' => $informations,
        ]);
    }

    /**
     * Parent: Show single child information (only if owned by parent's child).
     */
    public function parentShow(Request $request, ChildInformation $childInformation): JsonResponse
    {
        $parent = $request->user()->parent;
        $childIds = $parent->children()->pluck('children.id');

        if (! $childIds->contains($childInformation->child_id)) {
            return response()->json([
                'success' => false,
                'message' => 'Tidak memiliki akses ke informasi ini.',
            ], 403);
        }

        return response()->json([
            'success' => true,
            'data' => $childInformation->load(['child', 'creator']),
        ]);
    }
}
