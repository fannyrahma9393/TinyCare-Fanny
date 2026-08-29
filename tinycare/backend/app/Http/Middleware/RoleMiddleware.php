<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

class RoleMiddleware
{
    public function handle(Request $request, Closure $next, string ...$roles): Response
    {
        $user = $request->user();

        if (! $user) {
            return response()->json([
                'success' => false,
                'message' => 'Tidak terautentikasi.',
            ], 401);
        }

        if (! $user->role) {
            return response()->json([
                'success' => false,
                'message' => 'Akun tidak memiliki role.',
            ], 403);
        }

        if (! in_array($user->role->name, $roles)) {
            return response()->json([
                'success' => false,
                'message' => 'Tidak memiliki akses.',
            ], 403);
        }

        return $next($request);
    }
}
