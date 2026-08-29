<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\AuthorizedPickup;
use App\Models\Child;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class PickupController extends Controller
{
    /**
     * Parent: list authorized pickups for a child.
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

        $pickups = AuthorizedPickup::where('parent_id', $request->user()->parent->id)
            ->where('child_id', $child->id)
            ->orderBy('created_at', 'desc')
            ->get();

        return response()->json([
            'success' => true,
            'data' => $pickups,
        ]);
    }

    /**
     * Parent: add authorized pickup.
     */
    public function parentStore(Request $request, Child $child): JsonResponse
    {
        // Verify ownership
        if (! $request->user()->parent->children->contains('id', $child->id)) {
            return response()->json([
                'success' => false,
                'message' => 'Tidak memiliki akses ke data anak ini.',
            ], 403);
        }

        $validated = $request->validate([
            'name' => 'required|string|max:255',
            'phone' => 'required|string|max:20',
            'relationship' => 'required|string|in:ayah,ibu,paman,bibi,kakek,nenek,lainnya',
            'id_number' => 'nullable|string|max:50',
            'photo' => 'nullable|string|max:500',
            'notes' => 'nullable|string|max:500',
        ]);

        $pickup = AuthorizedPickup::create([
            'parent_id' => $request->user()->parent->id,
            'child_id' => $child->id,
            'name' => $validated['name'],
            'phone' => $validated['phone'],
            'relationship' => $validated['relationship'],
            'id_number' => $validated['id_number'] ?? null,
            'photo' => $validated['photo'] ?? null,
            'notes' => $validated['notes'] ?? null,
            'status' => 'active',
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Penjemput berhasil ditambahkan.',
            'data' => $pickup,
        ], 201);
    }

    /**
     * Parent: update authorized pickup.
     */
    public function parentUpdate(Request $request, AuthorizedPickup $pickup): JsonResponse
    {
        // Verify ownership
        if ($pickup->parent_id !== $request->user()->parent->id) {
            return response()->json([
                'success' => false,
                'message' => 'Tidak memiliki akses ke penjemput ini.',
            ], 403);
        }

        $validated = $request->validate([
            'name' => 'sometimes|string|max:255',
            'phone' => 'sometimes|string|max:20',
            'relationship' => 'sometimes|string|in:ayah,ibu,paman,bibi,kakek,nenek,lainnya',
            'id_number' => 'nullable|string|max:50',
            'photo' => 'nullable|string|max:500',
            'status' => 'sometimes|in:active,inactive',
            'notes' => 'nullable|string|max:500',
        ]);

        $pickup->update($validated);

        return response()->json([
            'success' => true,
            'message' => 'Penjemput berhasil diperbarui.',
            'data' => $pickup,
        ]);
    }

    /**
     * Parent: delete authorized pickup.
     */
    public function parentDestroy(Request $request, AuthorizedPickup $pickup): JsonResponse
    {
        // Verify ownership
        if ($pickup->parent_id !== $request->user()->parent->id) {
            return response()->json([
                'success' => false,
                'message' => 'Tidak memiliki akses ke penjemput ini.',
            ], 403);
        }

        $pickup->delete();

        return response()->json([
            'success' => true,
            'message' => 'Penjemput berhasil dihapus.',
        ]);
    }

    /**
     * Admin: view authorized pickups for a child.
     */
    public function adminIndex(Child $child): JsonResponse
    {
        $pickups = AuthorizedPickup::where('child_id', $child->id)
            ->with(['parent.user:id,name'])
            ->orderBy('created_at', 'desc')
            ->get();

        return response()->json([
            'success' => true,
            'data' => $pickups,
        ]);
    }
}
