<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Admin;
use App\Models\Role;
use App\Models\User;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;

class AdminController extends Controller
{
    public function __construct()
    {
        $this->authorizeResource(Admin::class, 'admin');
    }

    public function index(Request $request): JsonResponse
    {
        $admins = Admin::with(['user', 'user.role'])
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
            'data' => $admins,
        ]);
    }

    /**
     * Create a new admin. Only admin_master can do this.
     */
    public function store(Request $request): JsonResponse
    {
        // Only admin_master can create admins
        if (! $request->user()->isAdminMaster()) {
            return response()->json([
                'success' => false,
                'message' => 'Hanya admin_master yang dapat membuat admin baru.',
            ], 403);
        }

        $validated = $request->validate([
            'name' => 'required|string|max:255',
            'email' => 'required|email|unique:users,email',
            'password' => 'required|string|min:8',
            'phone' => 'nullable|string|max:20',
            'position' => 'nullable|string|max:100',
            'admin_role' => 'nullable|string|in:admin,admin_master',
        ]);

        // Determine the role - default to 'admin'
        $roleName = $validated['admin_role'] ?? 'admin';
        $role = Role::where('name', $roleName)->first();

        if (! $role) {
            return response()->json([
                'success' => false,
                'message' => 'Role tidak valid.',
            ], 422);
        }

        $admin = DB::transaction(function () use ($validated, $role) {
            $user = User::create([
                'name' => $validated['name'],
                'email' => $validated['email'],
                'password' => Hash::make($validated['password']),
                'role_id' => $role->id,
                'status' => 'active',
            ]);

            $admin = Admin::create([
                'user_id' => $user->id,
                'phone' => $validated['phone'] ?? null,
                'position' => $validated['position'] ?? null,
            ]);

            return $admin->load('user', 'user.role');
        });

        return response()->json([
            'success' => true,
            'message' => 'Admin berhasil ditambahkan.',
            'data' => $admin,
        ], 201);
    }

    public function show(Admin $admin): JsonResponse
    {
        $admin->load('user', 'user.role');

        return response()->json([
            'success' => true,
            'data' => $admin,
        ]);
    }

    public function update(Request $request, Admin $admin): JsonResponse
    {
        $validated = $request->validate([
            'name' => 'sometimes|string|max:255',
            'email' => 'sometimes|email|unique:users,email,'.$admin->user_id,
            'phone' => 'nullable|string|max:20',
            'position' => 'nullable|string|max:100',
        ]);

        DB::transaction(function () use ($validated, $admin) {
            if (isset($validated['name']) || isset($validated['email'])) {
                $admin->user->update(collect($validated)->only(['name', 'email'])->toArray());
            }
            $admin->update(collect($validated)->except(['name', 'email'])->toArray());
        });

        return response()->json([
            'success' => true,
            'message' => 'Data admin berhasil diperbarui.',
            'data' => $admin->load('user', 'user.role'),
        ]);
    }

    public function destroy(Admin $admin): JsonResponse
    {
        // Policy handles self-delete prevention, but double check
        if ($admin->user_id === auth()->id()) {
            return response()->json([
                'success' => false,
                'message' => 'Tidak dapat menghapus akun sendiri.',
            ], 400);
        }

        DB::transaction(function () use ($admin) {
            $admin->user->delete();
            $admin->delete();
        });

        return response()->json([
            'success' => true,
            'message' => 'Admin berhasil dihapus.',
        ]);
    }

    /**
     * Activate an admin. Only admin_master.
     */
    public function activate(Request $request, Admin $admin): JsonResponse
    {
        if (! $request->user()->isAdminMaster()) {
            return response()->json([
                'success' => false,
                'message' => 'Hanya admin_master yang dapat mengaktifkan admin.',
            ], 403);
        }

        $admin->user->update(['status' => 'active']);

        return response()->json([
            'success' => true,
            'message' => 'Admin berhasil diaktifkan.',
            'data' => $admin->load('user', 'user.role'),
        ]);
    }

    /**
     * Deactivate an admin. Only admin_master. Cannot deactivate self.
     */
    public function deactivate(Request $request, Admin $admin): JsonResponse
    {
        if (! $request->user()->isAdminMaster()) {
            return response()->json([
                'success' => false,
                'message' => 'Hanya admin_master yang dapat menonaktifkan admin.',
            ], 403);
        }

        // Cannot deactivate self
        if ($admin->user_id === $request->user()->id) {
            return response()->json([
                'success' => false,
                'message' => 'Tidak dapat menonaktifkan akun sendiri.',
            ], 400);
        }

        $admin->user->update(['status' => 'inactive']);

        return response()->json([
            'success' => true,
            'message' => 'Admin berhasil dinonaktifkan.',
            'data' => $admin->load('user', 'user.role'),
        ]);
    }
}
