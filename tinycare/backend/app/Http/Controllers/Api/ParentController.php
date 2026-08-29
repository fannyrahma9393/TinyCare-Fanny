<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\ParentModel;
use App\Models\Role;
use App\Models\User;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;

class ParentController extends Controller
{
    /**
     * Admin: list all parents with children.
     */
    public function index(Request $request): JsonResponse
    {
        $parents = ParentModel::with(['user', 'children'])
            ->when($request->search, function ($query, $search) {
                $query->whereHas('user', function ($q) use ($search) {
                    $q->where('name', 'like', "%{$search}%")
                        ->orWhere('email', 'like', "%{$search}%");
                });
            })
            ->orderBy('created_at', 'desc')
            ->paginate($request->per_page ?? 15);

        return response()->json([
            'success' => true,
            'data' => $parents,
        ]);
    }

    /**
     * Admin: create new parent (user + parent profile).
     */
    public function store(Request $request): JsonResponse
    {
        $this->authorize('create', ParentModel::class);

        $validated = $request->validate([
            'name' => 'required|string|max:255',
            'email' => 'required|email|unique:users,email',
            'password' => 'required|string|min:8',
            'phone' => 'nullable|string|max:20',
            'address' => 'nullable|string|max:500',
            'emergency_contact_name' => 'nullable|string|max:255',
            'emergency_contact_phone' => 'nullable|string|max:20',
            'emergency_contact_relationship' => 'nullable|string|max:100',
        ]);

        $parent = DB::transaction(function () use ($validated) {
            $role = Role::where('name', 'parent')->first();

            $user = User::create([
                'name' => $validated['name'],
                'email' => $validated['email'],
                'password' => Hash::make($validated['password']),
                'role_id' => $role->id,
                'status' => 'active',
            ]);

            $parent = ParentModel::create([
                'user_id' => $user->id,
                'phone' => $validated['phone'] ?? null,
                'address' => $validated['address'] ?? null,
                'emergency_contact_name' => $validated['emergency_contact_name'] ?? null,
                'emergency_contact_phone' => $validated['emergency_contact_phone'] ?? null,
                'emergency_contact_relationship' => $validated['emergency_contact_relationship'] ?? null,
            ]);

            return $parent->load(['user', 'children']);
        });

        return response()->json([
            'success' => true,
            'message' => 'Orang tua berhasil ditambahkan.',
            'data' => $parent,
        ], 201);
    }

    /**
     * Admin: show parent detail.
     */
    public function show(ParentModel $parent): JsonResponse
    {
        $this->authorize('view', $parent);
        $parent->load(['user', 'children']);

        return response()->json([
            'success' => true,
            'data' => $parent,
        ]);
    }

    /**
     * Admin: update parent.
     */
    public function update(Request $request, ParentModel $parent): JsonResponse
    {
        $this->authorize('update', $parent);

        $validated = $request->validate([
            'name' => 'sometimes|string|max:255',
            'email' => 'sometimes|email|unique:users,email,'.$parent->user_id,
            'phone' => 'nullable|string|max:20',
            'address' => 'nullable|string|max:500',
            'emergency_contact_name' => 'nullable|string|max:255',
            'emergency_contact_phone' => 'nullable|string|max:20',
            'emergency_contact_relationship' => 'nullable|string|max:100',
        ]);

        DB::transaction(function () use ($validated, $parent) {
            if (isset($validated['name']) || isset($validated['email'])) {
                $parent->user->update(collect($validated)->only(['name', 'email'])->toArray());
            }
            $parent->update(collect($validated)->except(['name', 'email'])->toArray());
        });

        return response()->json([
            'success' => true,
            'message' => 'Data orang tua berhasil diperbarui.',
            'data' => $parent->load(['user', 'children']),
        ]);
    }

    /**
     * Admin: delete parent (cascades to user).
     */
    public function destroy(ParentModel $parent): JsonResponse
    {
        $this->authorize('delete', $parent);

        DB::transaction(function () use ($parent) {
            $parent->children()->detach();
            $parent->user->delete();
            $parent->delete();
        });

        return response()->json([
            'success' => true,
            'message' => 'Orang tua berhasil dihapus.',
        ]);
    }
}
