<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\FcmToken;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class FcmTokenController extends Controller
{
    /**
     * Register (or update) an FCM token for the authenticated user.
     * Supports multiple devices: each user may register several tokens.
     * Duplicate token + user is upserted (no duplicate row), refreshing last_used_at.
     */
    public function store(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'token' => 'required|string|max:1024',
            'platform' => 'sometimes|string|max:32',
            'device' => 'nullable|string|max:255',
        ]);

        $userId = $request->user()->id;

        $fcmToken = FcmToken::updateOrCreate(
            [
                'user_id' => $userId,
                'token' => $validated['token'],
            ],
            [
                'platform' => $validated['platform'] ?? 'web',
                'device' => $validated['device'] ?? null,
                'last_used_at' => now(),
            ]
        );

        return response()->json([
            'success' => true,
            'message' => 'Token notifikasi berhasil didaftarkan.',
            'data' => [
                'id' => $fcmToken->id,
                'token' => $fcmToken->token,
            ],
        ], 201);
    }

    /**
     * Remove (unregister) an FCM token for the authenticated user.
     * Used on logout or when the device token becomes invalid.
     */
    public function destroy(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'token' => 'required|string|max:1024',
        ]);

        FcmToken::where('user_id', $request->user()->id)
            ->where('token', $validated['token'])
            ->delete();

        return response()->json([
            'success' => true,
            'message' => 'Token notifikasi dihapus.',
        ]);
    }
}
