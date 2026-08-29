<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\User;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class UserManagementController extends Controller
{
    /**
     * List all users with optional filter.
     * GET /api/v1/admin/users?filter=all|parent|pending|admin
     */
    public function index(Request $request): JsonResponse
    {
        $filter = $request->input('filter', 'all');

        $query = User::with(['role', 'parent', 'admin']);

        switch ($filter) {
            case 'parent':
                $query->whereHas('role', fn ($q) => $q->where('name', 'parent'))
                    ->where('status', 'active');
                break;
            case 'pending':
                $query->whereHas('role', fn ($q) => $q->where('name', 'parent'))
                    ->where('status', 'pending');
                break;
            case 'admin':
                $query->whereHas('role', fn ($q) => $q->whereIn('name', ['admin', 'admin_master']));
                break;
        }

        // Search by name or email
        if ($request->search) {
            $search = $request->search;
            $query->where(function ($q) use ($search) {
                $q->where('name', 'like', "%{$search}%")
                    ->orWhere('email', 'like', "%{$search}%");
            });
        }

        $users = $query->orderBy('created_at', 'desc')
            ->paginate($request->per_page ?? 15);

        // Summary counts
        $summary = [
            'total' => User::count(),
            'active_parents' => User::whereHas('role', fn ($q) => $q->where('name', 'parent'))
                ->where('status', 'active')
                ->count(),
            'pending_parents' => User::whereHas('role', fn ($q) => $q->where('name', 'parent'))
                ->where('status', 'pending')
                ->count(),
            'admins' => User::whereHas('role', fn ($q) => $q->whereIn('name', ['admin', 'admin_master']))
                ->count(),
        ];

        return response()->json([
            'success' => true,
            'data' => $users,
            'summary' => $summary,
        ]);
    }

    /**
     * List pending parents specifically.
     * GET /api/v1/admin/users/pending
     */
    public function pending(Request $request): JsonResponse
    {
        $users = User::with(['role', 'parent'])
            ->whereHas('role', fn ($q) => $q->where('name', 'parent'))
            ->where('status', 'pending')
            ->orderBy('created_at', 'desc')
            ->paginate($request->per_page ?? 15);

        return response()->json([
            'success' => true,
            'data' => $users,
        ]);
    }

    /**
     * Approve a pending parent.
     * POST /api/v1/admin/users/{id}/approve
     */
    public function approve(User $user): JsonResponse
    {
        if ($user->status !== 'pending') {
            return response()->json([
                'success' => false,
                'message' => 'Akun ini tidak dalam status menunggu persetujuan.',
            ], 422);
        }

        if ($user->role?->name !== 'parent') {
            return response()->json([
                'success' => false,
                'message' => 'Hanya akun parent yang dapat disetujui.',
            ], 422);
        }

        $user->update(['status' => 'active']);

        return response()->json([
            'success' => true,
            'message' => 'Akun parent berhasil disetujui.',
            'data' => $user->load(['role', 'parent']),
        ]);
    }

    /**
     * Reject a pending parent.
     * POST /api/v1/admin/users/{id}/reject
     */
    public function reject(Request $request, User $user): JsonResponse
    {
        $validated = $request->validate([
            'reason' => 'nullable|string|max:500',
        ]);

        if ($user->status !== 'pending') {
            return response()->json([
                'success' => false,
                'message' => 'Akun ini tidak dalam status menunggu persetujuan.',
            ], 422);
        }

        if ($user->role?->name !== 'parent') {
            return response()->json([
                'success' => false,
                'message' => 'Hanya akun parent yang dapat ditolak.',
            ], 422);
        }

        $user->update(['status' => 'rejected']);

        // Store rejection reason in parent profile if available
        if ($user->parent) {
            $user->parent->update([
                'notes' => $validated['reason'] ?? null,
            ]);
        }

        return response()->json([
            'success' => true,
            'message' => 'Akun parent berhasil ditolak.',
            'data' => $user->load(['role', 'parent']),
        ]);
    }
}
