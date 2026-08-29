<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Child;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class ChildController extends Controller
{
    /**
     * Admin: list all children. Parent: list own children.
     */
    public function index(Request $request): JsonResponse
    {
        $user = $request->user();

        if ($user->isParent()) {
            $children = $user->parent->children()
                ->with(['parents.user', 'childPackages.package'])
                ->orderBy('created_at', 'desc')
                ->paginate($request->per_page ?? 15);
        } else {
            $children = Child::with(['parents.user', 'childPackages.package'])
                ->when($request->search, fn ($q, $s) => $q->where('name', 'like', "%{$s}%"))
                ->when($request->status, fn ($q, $s) => $q->where('status', $s))
                ->orderBy('created_at', 'desc')
                ->paginate($request->per_page ?? 15);
        }

        return response()->json([
            'success' => true,
            'data' => $children,
        ]);
    }

    /**
     * Admin: create child.
     */
    public function store(Request $request): JsonResponse
    {
        $this->authorize('create', Child::class);

        $validated = $request->validate([
            'name' => 'required|string|max:255',
            'birth_date' => 'required|date|before:today',
            'gender' => 'required|in:male,female',
            'photo' => 'nullable|string|max:500',
            'address' => 'nullable|string|max:500',
            'health_info' => 'nullable|string|max:1000',
            'emergency_contact_name' => 'nullable|string|max:255',
            'emergency_contact_phone' => 'nullable|string|max:20',
            'emergency_contact_relationship' => 'nullable|string|max:100',
            'parent_ids' => 'required|array|min:1',
            'parent_ids.*' => 'exists:parents,id',
        ]);

        $child = Child::create([
            'name' => $validated['name'],
            'birth_date' => $validated['birth_date'],
            'gender' => $validated['gender'],
            'photo' => $validated['photo'] ?? null,
            'address' => $validated['address'] ?? null,
            'health_info' => $validated['health_info'] ?? null,
            'emergency_contact_name' => $validated['emergency_contact_name'] ?? null,
            'emergency_contact_phone' => $validated['emergency_contact_phone'] ?? null,
            'emergency_contact_relationship' => $validated['emergency_contact_relationship'] ?? null,
            'status' => 'active',
        ]);

        $child->parents()->attach($validated['parent_ids']);

        return response()->json([
            'success' => true,
            'message' => 'Anak berhasil ditambahkan.',
            'data' => $child->load('parents.user'),
        ], 201);
    }

    /**
     * Show child detail.
     */
    public function show(Child $child): JsonResponse
    {
        $this->authorize('view', $child);
        $child->load(['parents.user', 'childPackages.package']);

        return response()->json([
            'success' => true,
            'data' => $child,
        ]);
    }

    /**
     * Admin: update child.
     */
    public function update(Request $request, Child $child): JsonResponse
    {
        $this->authorize('update', $child);

        $validated = $request->validate([
            'name' => 'sometimes|string|max:255',
            'birth_date' => 'sometimes|date|before:today',
            'gender' => 'sometimes|in:male,female',
            'photo' => 'nullable|string|max:500',
            'address' => 'nullable|string|max:500',
            'health_info' => 'nullable|string|max:1000',
            'emergency_contact_name' => 'nullable|string|max:255',
            'emergency_contact_phone' => 'nullable|string|max:20',
            'emergency_contact_relationship' => 'nullable|string|max:100',
            'status' => 'sometimes|in:active,inactive',
            'parent_ids' => 'sometimes|array|min:1',
            'parent_ids.*' => 'exists:parents,id',
        ]);

        $child->update(collect($validated)->except(['parent_ids'])->toArray());

        if (isset($validated['parent_ids'])) {
            $child->parents()->sync($validated['parent_ids']);
        }

        return response()->json([
            'success' => true,
            'message' => 'Data anak berhasil diperbarui.',
            'data' => $child->load('parents.user'),
        ]);
    }

    /**
     * Admin: delete child.
     */
    public function destroy(Child $child): JsonResponse
    {
        $this->authorize('delete', $child);

        $child->parents()->detach();
        $child->childPackages()->delete();
        $child->delete();

        return response()->json([
            'success' => true,
            'message' => 'Anak berhasil dihapus.',
        ]);
    }
}
