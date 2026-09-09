<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Child;
use App\Models\Invoice;
use App\Models\Package;
use App\Models\Voucher;
use App\Models\VoucherUsage;
use App\Services\FcmNotificationService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class InvoiceController extends Controller
{
    /**
     * Admin: list all invoices.
     */
    public function index(Request $request): JsonResponse
    {
        $query = Invoice::with(['child', 'package', 'parent.user', 'latestPayment']);

        // Filter by status
        if ($request->status) {
            $query->where('status', $request->status);
        }

        // Filter by parent
        if ($request->parent_id) {
            $query->where('parent_id', $request->parent_id);
        }

        // Filter by child
        if ($request->child_id) {
            $query->where('child_id', $request->child_id);
        }

        // Search by invoice number
        if ($request->search) {
            $query->where('invoice_number', 'like', "%{$request->search}%");
        }

        $invoices = $query->orderBy('created_at', 'desc')
            ->paginate($request->per_page ?? 15);

        return response()->json([
            'success' => true,
            'data' => $invoices,
        ]);
    }

    /**
     * Admin: create invoice.
     */
    public function store(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'child_id' => 'required|exists:children,id',
            'package_id' => 'required|exists:packages,id',
            'due_date' => 'required|date|after:today',
            'voucher_code' => 'nullable|string',
            'notes' => 'nullable|string|max:500',
        ]);

        $child = Child::findOrFail($validated['child_id']);
        $package = Package::findOrFail($validated['package_id']);

        // Check if child has active package
        $activePackage = $child->childPackages()
            ->where('status', 'active')
            ->where('package_id', $package->id)
            ->first();

        if (! $activePackage) {
            return response()->json([
                'success' => false,
                'message' => 'Anak tidak terdaftar pada paket ini.',
            ], 400);
        }

        // Check if there's already a pending invoice for this child + package
        $existingPending = Invoice::where('child_id', $child->id)
            ->where('package_id', $package->id)
            ->where('status', 'pending')
            ->first();

        if ($existingPending) {
            return response()->json([
                'success' => false,
                'message' => 'Sudah ada invoice pending untuk anak ini pada paket ini.',
            ], 400);
        }

        // Get parent_id from child
        $parentId = $child->parents->first()?->id;
        if (! $parentId) {
            return response()->json([
                'success' => false,
                'message' => 'Anak tidak memiliki orang tua yang terdaftar.',
            ], 400);
        }

        // Apply voucher if provided
        $voucher = null;
        if (! empty($validated['voucher_code'])) {
            $voucher = Voucher::where('code', strtoupper($validated['voucher_code']))->first();
            if (! $voucher || ! $voucher->canBeUsed($package->price)) {
                return response()->json([
                    'success' => false,
                    'message' => 'Voucher tidak valid atau tidak dapat digunakan.',
                ], 400);
            }
        }

        // Calculate total
        $calculation = Invoice::calculateTotal($package, $voucher);

        $invoice = DB::transaction(function () use ($validated, $child, $package, $parentId, $voucher, $calculation) {
            $invoice = Invoice::create([
                'invoice_number' => Invoice::generateInvoiceNumber(),
                'child_id' => $child->id,
                'package_id' => $package->id,
                'parent_id' => $parentId,
                'subtotal' => $calculation['subtotal'],
                'discount' => $calculation['discount'],
                'total' => $calculation['total'],
                'due_date' => $validated['due_date'],
                'status' => 'pending',
                'notes' => $validated['notes'] ?? null,
            ]);

            // Record voucher usage
            if ($voucher) {
                VoucherUsage::create([
                    'voucher_id' => $voucher->id,
                    'invoice_id' => $invoice->id,
                    'parent_id' => $parentId,
                    'discount_applied' => $calculation['discount'],
                ]);

                $voucher->increment('current_usage');
            }

            return $invoice->load(['child', 'package', 'parent.user']);
        });

        // Notify the parent about the new invoice (DB + FCM)
        $parentUser = $invoice->parent->user ?? null;
        if ($parentUser && $parentUser->status === 'active') {
            $fcm = app(FcmNotificationService::class);
            $fcm->notifyUser(
                $parentUser,
                [
                    'type' => 'invoice_created',
                    'title' => 'Tagihan Baru',
                    'message' => "Tagihan baru untuk {$child->name}: {$package->name}",
                    'link' => '/invoices',
                    'data' => [
                        'type' => 'invoice_created',
                        'invoice_id' => (string) $invoice->id,
                    ],
                ],
                'Tagihan Baru',
                "Tagihan baru untuk {$child->name}: {$package->name}",
                '/invoices',
                [
                    'type' => 'invoice_created',
                    'invoice_id' => (string) $invoice->id,
                ]
            );
        }

        return response()->json([
            'success' => true,
            'message' => 'Invoice berhasil dibuat.',
            'data' => $invoice,
        ], 201);
    }

    /**
     * Admin: show invoice detail.
     */
    public function show(Invoice $invoice): JsonResponse
    {
        $invoice->load(['child', 'package', 'parent.user', 'payments.verifier', 'voucherUsages.voucher']);

        return response()->json([
            'success' => true,
            'data' => $invoice,
        ]);
    }

    /**
     * Admin: update invoice status.
     */
    public function updateStatus(Request $request, Invoice $invoice): JsonResponse
    {
        $validated = $request->validate([
            'status' => 'required|in:pending,paid,failed,expired,cancelled',
            'notes' => 'nullable|string|max:500',
        ]);

        // Validate status transition
        $allowedTransitions = [
            'pending' => ['paid', 'failed', 'expired', 'cancelled'],
            'paid' => [], // cannot change from paid
            'failed' => ['pending'], // can retry
            'expired' => ['pending'], // can retry
            'cancelled' => [], // cannot change from cancelled
        ];

        $currentStatus = $invoice->status;
        $newStatus = $validated['status'];

        if (! in_array($newStatus, $allowedTransitions[$currentStatus] ?? [])) {
            return response()->json([
                'success' => false,
                'message' => "Tidak dapat mengubah status dari '$currentStatus' ke '$newStatus'.",
            ], 400);
        }

        $invoice->update([
            'status' => $newStatus,
            'notes' => $validated['notes'] ?? $invoice->notes,
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Status invoice berhasil diperbarui.',
            'data' => $invoice->load(['child', 'package', 'parent.user']),
        ]);
    }

    /**
     * Parent: list own invoices.
     */
    public function parentIndex(Request $request): JsonResponse
    {
        $parentId = $request->user()->parent->id;

        $query = Invoice::with(['child', 'package', 'latestPayment'])
            ->where('parent_id', $parentId);

        // Filter by status
        if ($request->status) {
            $query->where('status', $request->status);
        }

        $invoices = $query->orderBy('created_at', 'desc')
            ->paginate($request->per_page ?? 15);

        return response()->json([
            'success' => true,
            'data' => $invoices,
        ]);
    }

    /**
     * Parent: show own invoice detail.
     */
    public function parentShow(Request $request, Invoice $invoice): JsonResponse
    {
        // Verify ownership
        if ($invoice->parent_id !== $request->user()->parent->id) {
            return response()->json([
                'success' => false,
                'message' => 'Tidak memiliki akses ke invoice ini.',
            ], 403);
        }

        $invoice->load(['child', 'package', 'payments', 'voucherUsages.voucher']);

        return response()->json([
            'success' => true,
            'data' => $invoice,
        ]);
    }
}
