<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Child;
use App\Models\ChildPackage;
use App\Models\Package;
use Carbon\Carbon;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class PackageController extends Controller
{
    /**
     * List all packages (admin) or available packages (parent).
     */
    public function index(Request $request): JsonResponse
    {
        $query = Package::query();

        if ($request->search) {
            $query->where(function ($q) use ($request) {
                $q->where('name', 'like', "%{$request->search}%")
                    ->orWhere('description', 'like', "%{$request->search}%");
            });
        }

        if ($request->status) {
            $query->where('status', $request->status);
        }

        $packages = $query->orderBy('created_at', 'desc')
            ->paginate($request->per_page ?? 15);

        return response()->json([
            'success' => true,
            'data' => $packages,
        ]);
    }

    /**
     * Store new package (admin only).
     */
    public function store(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'name' => 'required|string|max:255',
            'description' => 'nullable|string|max:1000',
            'price' => 'required|numeric|min:0',
            'duration_days' => 'required|integer|min:1',
            'facilities' => 'nullable|string|max:1000',
            'quota' => 'nullable|integer|min:0',
            'status' => 'sometimes|in:active,inactive',
            'start_date' => 'nullable|date',
            'end_date' => 'nullable|date|after_or_equal:start_date',
        ]);

        $validated['status'] = $validated['status'] ?? 'active';

        $package = Package::create($validated);

        return response()->json([
            'success' => true,
            'message' => 'Paket berhasil ditambahkan.',
            'data' => $package,
        ], 201);
    }

    /**
     * Show package detail.
     */
    public function show(Package $package): JsonResponse
    {
        $package->loadCount('childPackages');

        return response()->json([
            'success' => true,
            'data' => $package,
        ]);
    }

    /**
     * Update package (admin only).
     */
    public function update(Request $request, Package $package): JsonResponse
    {
        $validated = $request->validate([
            'name' => 'sometimes|string|max:255',
            'description' => 'nullable|string|max:1000',
            'price' => 'sometimes|numeric|min:0',
            'duration_days' => 'sometimes|integer|min:1',
            'facilities' => 'nullable|string|max:1000',
            'quota' => 'nullable|integer|min:0',
            'status' => 'sometimes|in:active,inactive',
            'start_date' => 'nullable|date',
            'end_date' => 'nullable|date|after_or_equal:start_date',
        ]);

        $package->update($validated);

        return response()->json([
            'success' => true,
            'message' => 'Paket berhasil diperbarui.',
            'data' => $package,
        ]);
    }

    /**
     * Delete package (admin only).
     */
    public function destroy(Package $package): JsonResponse
    {
        $activeEnrollments = $package->childPackages()
            ->where('status', 'active')
            ->count();

        if ($activeEnrollments > 0) {
            return response()->json([
                'success' => false,
                'message' => 'Tidak dapat menghapus paket yang masih memiliki pendaftaran aktif.',
            ], 400);
        }

        $package->delete();

        return response()->json([
            'success' => true,
            'message' => 'Paket berhasil dihapus.',
        ]);
    }

    /**
     * Assign package to child (admin only).
     */
    public function assignToChild(Request $request, Child $child): JsonResponse
    {
        $validated = $request->validate([
            'package_id' => 'required|exists:packages,id',
            'start_date' => 'required|date',
        ]);

        $package = Package::findOrFail($validated['package_id']);

        if (! $package->isActive()) {
            return response()->json([
                'success' => false,
                'message' => 'Paket tidak aktif.',
            ], 400);
        }

        // Check if child already has active package
        $existingActive = $child->childPackages()
            ->where('status', 'active')
            ->first();

        if ($existingActive) {
            return response()->json([
                'success' => false,
                'message' => 'Anak sudah memiliki paket aktif. Nonaktifkan paket lama terlebih dahulu.',
            ], 400);
        }

        if (! $package->hasAvailableQuota()) {
            return response()->json([
                'success' => false,
                'message' => 'Kuota paket sudah penuh.',
            ], 400);
        }

        $startDate = Carbon::parse($validated['start_date']);
        $endDate = $startDate->copy()->addDays($package->duration_days);

        $childPackage = ChildPackage::create([
            'child_id' => $child->id,
            'package_id' => $package->id,
            'start_date' => $startDate,
            'end_date' => $endDate,
            'status' => 'active',
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Paket berhasil ditugaskan ke anak.',
            'data' => $childPackage->load(['child', 'package']),
        ], 201);
    }

    /**
     * List child's packages (admin view).
     */
    public function childPackages(Child $child): JsonResponse
    {
        $packages = $child->childPackages()
            ->with('package')
            ->orderBy('created_at', 'desc')
            ->get();

        return response()->json([
            'success' => true,
            'data' => $packages,
        ]);
    }

    /**
     * Parent view: show active package for specific child.
     */
    public function parentChildPackage(Request $request, Child $child): JsonResponse
    {
        if (! $request->user()->parent?->children->contains('id', $child->id)) {
            return response()->json([
                'success' => false,
                'message' => 'Tidak memiliki akses ke data anak ini.',
            ], 403);
        }

        $activePackage = $child->childPackages()
            ->with('package')
            ->where('status', 'active')
            ->first();

        return response()->json([
            'success' => true,
            'data' => $activePackage,
        ]);
    }

    /**
     * Parent view: show package history for specific child.
     */
    public function parentChildPackageHistory(Request $request, Child $child): JsonResponse
    {
        if (! $request->user()->parent?->children->contains('id', $child->id)) {
            return response()->json([
                'success' => false,
                'message' => 'Tidak memiliki akses ke data anak ini.',
            ], 403);
        }

        $packages = $child->childPackages()
            ->with('package')
            ->orderBy('created_at', 'desc')
            ->get();

        return response()->json([
            'success' => true,
            'data' => $packages,
        ]);
    }
}
