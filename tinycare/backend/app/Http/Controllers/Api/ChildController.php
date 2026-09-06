<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Child;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;

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
            'photo' => 'nullable|file|mimes:jpg,jpeg,png,gif|max:5120',
            'address' => 'nullable|string|max:500',
            'health_info' => 'nullable|string|max:1000',
            'emergency_contact_name' => 'nullable|string|max:255',
            'emergency_contact_phone' => 'nullable|string|max:20',
            'emergency_contact_relationship' => 'nullable|string|max:100',
            'status' => 'sometimes|in:active,inactive',
            'parent_ids' => 'required|array|min:1',
            'parent_ids.*' => 'exists:parents,id',
        ]);

        // Handle file upload
        $photoPath = null;
        if ($request->hasFile('photo')) {
            $photoPath = $request->file('photo')->store('child-photos', 'local');
        }

        $child = Child::create([
            'name' => $validated['name'],
            'birth_date' => $validated['birth_date'],
            'gender' => $validated['gender'],
            'photo' => $photoPath,
            'address' => $validated['address'] ?? null,
            'health_info' => $validated['health_info'] ?? null,
            'emergency_contact_name' => $validated['emergency_contact_name'] ?? null,
            'emergency_contact_phone' => $validated['emergency_contact_phone'] ?? null,
            'emergency_contact_relationship' => $validated['emergency_contact_relationship'] ?? null,
            'status' => $validated['status'] ?? 'active',
        ]);

        $child->parents()->attach($validated['parent_ids']);

        $child->parents()->get()->each->syncUserStatusFromChildren();

        return response()->json([
            'success' => true,
            'message' => 'Anak berhasil ditambahkan.',
            'data' => $child->load('parents.user'),
        ], 201);
    }

    /**
     * Parent: register/create their own child. The child is automatically
     * linked to the authenticated parent.
     */
    public function storeOwn(Request $request): JsonResponse
    {
        $user = $request->user();

        if (! $user->isParent()) {
            abort(403, 'Hanya orang tua yang dapat menambahkan anak sendiri.');
        }

        $validated = $request->validate([
            'name' => 'required|string|max:255',
            'birth_date' => 'required|date|before:today',
            'gender' => 'required|in:male,female',
            'photo' => 'nullable|file|mimes:jpg,jpeg,png,gif|max:5120',
            'address' => 'nullable|string|max:500',
            'health_info' => 'nullable|string|max:1000',
            'emergency_contact_name' => 'nullable|string|max:255',
            'emergency_contact_phone' => 'nullable|string|max:20',
            'emergency_contact_relationship' => 'nullable|string|max:100',
        ]);

        // Handle file upload
        $photoPath = null;
        if ($request->hasFile('photo')) {
            $photoPath = $request->file('photo')->store('child-photos', 'local');
        }

        $child = Child::create([
            'name' => $validated['name'],
            'birth_date' => $validated['birth_date'],
            'gender' => $validated['gender'],
            'photo' => $photoPath,
            'address' => $validated['address'] ?? null,
            'health_info' => $validated['health_info'] ?? null,
            'emergency_contact_name' => $validated['emergency_contact_name'] ?? null,
            'emergency_contact_phone' => $validated['emergency_contact_phone'] ?? null,
            'emergency_contact_relationship' => $validated['emergency_contact_relationship'] ?? null,
            'status' => 'active',
        ]);

        $child->parents()->attach($user->parent->id);

        $child->parents()->get()->each->syncUserStatusFromChildren();

        return response()->json([
            'success' => true,
            'message' => 'Anak berhasil ditambahkan.',
            'data' => $child->load('parents.user'),
        ], 201);
    }
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
            'photo' => 'nullable|file|mimes:jpg,jpeg,png,gif|max:5120',
            'address' => 'nullable|string|max:500',
            'health_info' => 'nullable|string|max:1000',
            'emergency_contact_name' => 'nullable|string|max:255',
            'emergency_contact_phone' => 'nullable|string|max:20',
            'emergency_contact_relationship' => 'nullable|string|max:100',
            'status' => 'sometimes|in:active,inactive',
            'parent_ids' => 'sometimes|array|min:1',
            'parent_ids.*' => 'exists:parents,id',
        ]);

        $data = collect($validated)->except(['parent_ids'])->toArray();

        // Handle file upload — only save new file after validation passes
        if ($request->hasFile('photo')) {
            // Store new file first
            $photoPath = $request->file('photo')->store('child-photos', 'local');

            // Delete old file safely
            if ($child->photo && Storage::disk('local')->exists($child->photo)) {
                Storage::disk('local')->delete($child->photo);
            }

            $data['photo'] = $photoPath;
        }

        $child->update($data);

        if (isset($validated['parent_ids'])) {
            $child->parents()->sync($validated['parent_ids']);
        }

        $child->parents()->get()->each->syncUserStatusFromChildren();

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

        $parents = $child->parents()->get();

        $child->parents()->detach();
        $child->childPackages()->delete();
        $child->delete();

        $parents->each->syncUserStatusFromChildren();

        return response()->json([
            'success' => true,
            'message' => 'Anak berhasil dihapus.',
        ]);
    }
}
