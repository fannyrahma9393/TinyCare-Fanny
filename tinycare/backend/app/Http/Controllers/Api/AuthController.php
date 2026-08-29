<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\User;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Log;
use Illuminate\Validation\ValidationException;

class AuthController extends Controller
{
    public function login(Request $request): JsonResponse
    {
        $request->validate([
            'email' => 'required|email',
            'password' => 'required|string',
        ]);

        $user = User::where('email', $request->email)->first();

        if (! $user || ! Hash::check($request->password, $user->password)) {
            throw ValidationException::withMessages([
                'email' => ['Email atau password tidak benar.'],
            ]);
        }

        // Block inactive users
        if ($user->status !== 'active') {
            $message = match ($user->status) {
                'pending' => 'Akun Anda masih menunggu persetujuan admin.',
                'rejected' => 'Akun Anda telah ditolak. Silakan hubungi admin.',
                'inactive' => 'Akun tidak aktif. Silakan hubungi admin.',
                default => 'Akun tidak aktif.',
            };
            throw ValidationException::withMessages([
                'email' => [$message],
            ]);
        }

        // Role comes from database, never from frontend
        $roleName = $user->role?->name;

        if (! $roleName) {
            throw ValidationException::withMessages([
                'email' => ['Akun tidak memiliki role.'],
            ]);
        }

        // Admin and admin_master require access code
        if (in_array($roleName, ['admin', 'admin_master'])) {
            $adminAccessCode = trim((string) $request->input('admin_access_code', ''));

            if ($adminAccessCode === '') {
                throw ValidationException::withMessages([
                    'admin_access_code' => ['Kode akses admin diperlukan.'],
                ]);
            }

            $expectedCode = (string) config('services.tinycare.admin_access_code');

            if (! hash_equals($expectedCode, $adminAccessCode)) {
                throw ValidationException::withMessages([
                    'admin_access_code' => ['Kode akses admin tidak valid.'],
                ]);
            }
        }

        // Safe logging — never log password or access code
        Log::info('TinyCare login success', [
            'email' => $user->email,
            'role' => $roleName,
        ]);

        $token = $user->createToken('auth-token')->plainTextToken;

        return response()->json([
            'success' => true,
            'message' => 'Login berhasil.',
            'data' => [
                'user' => [
                    'id' => $user->id,
                    'name' => $user->name,
                    'email' => $user->email,
                    'role' => $roleName,
                    'status' => $user->status,
                ],
                'token' => $token,
            ],
        ]);
    }

    public function logout(Request $request): JsonResponse
    {
        $request->user()->currentAccessToken()->delete();

        return response()->json([
            'success' => true,
            'message' => 'Logout berhasil.',
        ]);
    }

    public function me(Request $request): JsonResponse
    {
        $user = $request->user()->load(['role', 'parent', 'admin']);

        return response()->json([
            'success' => true,
            'data' => [
                'id' => $user->id,
                'name' => $user->name,
                'email' => $user->email,
                'role' => $user->role?->name,
                'status' => $user->status,
                'phone' => $user->phone,
                'profile' => $user->parent ?? $user->admin,
            ],
        ]);
    }

    public function changePassword(Request $request): JsonResponse
    {
        $request->validate([
            'current_password' => 'required|string',
            'password' => 'required|string|min:8|confirmed',
        ]);

        $user = $request->user();

        if (! Hash::check($request->current_password, $user->password)) {
            throw ValidationException::withMessages([
                'current_password' => ['Password lama salah.'],
            ]);
        }

        $user->update([
            'password' => Hash::make($request->password),
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Password berhasil diubah.',
        ]);
    }

    public function forgotPassword(Request $request): JsonResponse
    {
        $request->validate([
            'email' => 'required|email|exists:users,email',
        ]);

        // TODO: Implement email sending for password reset
        return response()->json([
            'success' => true,
            'message' => 'Link reset password telah dikirim ke email Anda.',
        ]);
    }

    public function resetPassword(Request $request): JsonResponse
    {
        $request->validate([
            'token' => 'required|string',
            'email' => 'required|email|exists:users,email',
            'password' => 'required|string|min:8|confirmed',
        ]);

        // TODO: Implement token validation and password reset
        return response()->json([
            'success' => true,
            'message' => 'Password berhasil direset.',
        ]);
    }
}
