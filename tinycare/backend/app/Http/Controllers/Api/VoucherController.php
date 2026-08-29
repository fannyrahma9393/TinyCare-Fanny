<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Voucher;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class VoucherController extends Controller
{
    /**
     * List all vouchers (admin).
     */
    public function index(Request $request): JsonResponse
    {
        $vouchers = Voucher::when($request->search, function ($query, $search) {
            $query->where('code', 'like', "%{$search}%")
                ->orWhere('description', 'like', "%{$search}%");
        })
            ->when($request->status, function ($query, $status) {
                $query->where('status', $status);
            })
            ->orderBy('created_at', 'desc')
            ->paginate($request->per_page ?? 15);

        return response()->json([
            'success' => true,
            'data' => $vouchers,
        ]);
    }

    /**
     * Store new voucher (admin only).
     */
    public function store(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'code' => 'required|string|max:50|unique:vouchers,code',
            'description' => 'nullable|string|max:500',
            'discount_type' => 'required|in:nominal,percentage',
            'discount_value' => 'required|numeric|min:0',
            'min_transaction' => 'nullable|numeric|min:0',
            'max_usage' => 'required|integer|min:1',
            'start_date' => 'required|date',
            'end_date' => 'required|date|after:start_date',
            'status' => 'sometimes|in:active,inactive',
        ]);

        // Validate percentage max 100
        if ($validated['discount_type'] === 'percentage' && $validated['discount_value'] > 100) {
            return response()->json([
                'success' => false,
                'message' => 'Persentase diskon maksimal 100%.',
            ], 422);
        }

        $validated['code'] = strtoupper($validated['code']);
        $validated['min_transaction'] = $validated['min_transaction'] ?? 0;

        $voucher = Voucher::create($validated);

        return response()->json([
            'success' => true,
            'message' => 'Voucher berhasil ditambahkan.',
            'data' => $voucher,
        ], 201);
    }

    /**
     * Show voucher detail.
     */
    public function show(Voucher $voucher): JsonResponse
    {
        return response()->json([
            'success' => true,
            'data' => $voucher,
        ]);
    }

    /**
     * Update voucher (admin only).
     */
    public function update(Request $request, Voucher $voucher): JsonResponse
    {
        $validated = $request->validate([
            'code' => 'sometimes|string|max:50|unique:vouchers,code,'.$voucher->id,
            'description' => 'nullable|string|max:500',
            'discount_type' => 'sometimes|in:nominal,percentage',
            'discount_value' => 'sometimes|numeric|min:0',
            'min_transaction' => 'nullable|numeric|min:0',
            'max_usage' => 'sometimes|integer|min:1',
            'start_date' => 'sometimes|date',
            'end_date' => 'sometimes|date|after:start_date',
            'status' => 'sometimes|in:active,inactive,expired',
        ]);

        if (isset($validated['code'])) {
            $validated['code'] = strtoupper($validated['code']);
        }

        // Validate percentage max 100
        if (isset($validated['discount_type']) && $validated['discount_type'] === 'percentage'
            && isset($validated['discount_value']) && $validated['discount_value'] > 100) {
            return response()->json([
                'success' => false,
                'message' => 'Persentase diskon maksimal 100%.',
            ], 422);
        }

        $voucher->update($validated);

        return response()->json([
            'success' => true,
            'message' => 'Voucher berhasil diperbarui.',
            'data' => $voucher,
        ]);
    }

    /**
     * Delete voucher (admin only).
     */
    public function destroy(Voucher $voucher): JsonResponse
    {
        // Check if voucher has been used
        if ($voucher->current_usage > 0) {
            return response()->json([
                'success' => false,
                'message' => 'Tidak dapat menghapus voucher yang sudah digunakan.',
            ], 400);
        }

        $voucher->delete();

        return response()->json([
            'success' => true,
            'message' => 'Voucher berhasil dihapus.',
        ]);
    }

    /**
     * Parent: list available vouchers.
     */
    public function parentIndex(Request $request): JsonResponse
    {
        $now = now();

        $vouchers = Voucher::where('status', 'active')
            ->where('start_date', '<=', $now)
            ->where('end_date', '>=', $now)
            ->whereColumn('current_usage', '<', 'max_usage')
            ->orderBy('created_at', 'desc')
            ->get();

        return response()->json([
            'success' => true,
            'data' => $vouchers,
        ]);
    }

    /**
     * Parent: apply voucher (validate and return discount info).
     */
    public function applyVoucher(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'code' => 'required|string',
            'amount' => 'required|numeric|min:0',
        ]);

        $voucher = Voucher::where('code', strtoupper($validated['code']))->first();

        if (! $voucher) {
            return response()->json([
                'success' => false,
                'message' => 'Voucher tidak ditemukan.',
            ], 404);
        }

        if (! $voucher->canBeUsed($validated['amount'])) {
            $reason = match (true) {
                $voucher->status !== 'active' => 'Voucher tidak aktif.',
                $voucher->isExpired() => 'Voucher sudah kadaluarsa.',
                $voucher->current_usage >= $voucher->max_usage => 'Batas penggunaan voucher sudah tercapai.',
                $validated['amount'] < $voucher->min_transaction => 'Transaksi minimum belum terpenuhi.',
                default => 'Voucher tidak dapat digunakan.',
            };

            return response()->json([
                'success' => false,
                'message' => $reason,
            ], 400);
        }

        $discount = $voucher->calculateDiscount($validated['amount']);
        $finalAmount = $validated['amount'] - $discount;

        return response()->json([
            'success' => true,
            'message' => 'Voucher berhasil diterapkan.',
            'data' => [
                'voucher_code' => $voucher->code,
                'discount_type' => $voucher->discount_type,
                'discount_value' => $voucher->discount_value,
                'discount_amount' => $discount,
                'original_amount' => $validated['amount'],
                'final_amount' => max(0, $finalAmount),
            ],
        ]);
    }
}
