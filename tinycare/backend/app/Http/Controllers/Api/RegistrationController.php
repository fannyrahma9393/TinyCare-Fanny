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

class RegistrationController extends Controller
{
    /**
     * Public registration for parents.
     * Creates user + parent profile with status 'pending'.
     */
    public function registerParent(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'name' => 'required|string|max:255',
            'email' => 'required|email|unique:users,email',
            'phone' => 'nullable|string|max:20',
            'password' => 'required|string|min:8|confirmed',
            'address' => 'nullable|string|max:500',
        ]);

        $result = DB::transaction(function () use ($validated) {
            $role = Role::where('name', 'parent')->first();

            if (! $role) {
                throw \Illuminate\Validation\ValidationException::withMessages([
                    'email' => ['Konfigurasi sistem tidak ditemukan. Silakan hubungi admin.'],
                ]);
            }

            $user = User::create([
                'name' => $validated['name'],
                'email' => $validated['email'],
                'phone' => $validated['phone'] ?? null,
                'password' => Hash::make($validated['password']),
                'role_id' => $role->id,
                'status' => 'pending',
            ]);

            $parent = ParentModel::create([
                'user_id' => $user->id,
                'phone' => $validated['phone'] ?? null,
                'address' => $validated['address'] ?? null,
            ]);

            return [
                'user' => $user,
                'parent' => $parent,
            ];
        });

        return response()->json([
            'success' => true,
            'message' => 'Registrasi berhasil. Akun Anda akan segera diverifikasi oleh admin.',
            'data' => [
                'id' => $result['user']->id,
                'name' => $result['user']->name,
                'email' => $result['user']->email,
                'status' => $result['user']->status,
            ],
        ], 201);
    }
}
