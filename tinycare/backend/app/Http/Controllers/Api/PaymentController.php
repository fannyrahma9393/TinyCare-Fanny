<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Invoice;
use App\Models\Payment;
use App\Services\Payment\PaymentService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Storage;

class PaymentController extends Controller
{
    /**
     * Admin: list all payments.
     */
    public function index(Request $request): JsonResponse
    {
        $query = Payment::with(['invoice.child', 'invoice.package', 'invoice.parent.user', 'verifier']);

        if ($request->status) {
            $query->where('status', $request->status);
        }

        if ($request->invoice_id) {
            $query->where('invoice_id', $request->invoice_id);
        }

        $payments = $query->orderBy('created_at', 'desc')
            ->paginate($request->per_page ?? 15);

        return response()->json([
            'success' => true,
            'data' => $payments,
        ]);
    }

    /**
     * Parent: initiate payment for an invoice.
     * Creates a payment transaction and returns payment instructions/URL.
     */
    public function initiate(Request $request, Invoice $invoice): JsonResponse
    {
        // Verify ownership
        if ($invoice->parent_id !== $request->user()->parent->id) {
            return response()->json([
                'success' => false,
                'message' => 'Tidak memiliki akses ke invoice ini.',
            ], 403);
        }

        try {
            $paymentService = new PaymentService;
            $result = $paymentService->initiatePayment($invoice, [
                'payment_method' => $request->input('payment_method', 'bank_transfer'),
            ]);

            return response()->json([
                'success' => true,
                'message' => $result['already_pending'] ?? false
                    ? 'Pembayaran sebelumnya masih dalam proses.'
                    : 'Pembayaran berhasil dibuat.',
                'data' => $result,
            ]);

        } catch (\RuntimeException $e) {
            return response()->json([
                'success' => false,
                'message' => $e->getMessage(),
            ], 422);
        }
    }

    /**
     * Parent: check payment status.
     */
    public function checkStatus(Request $request, Payment $payment): JsonResponse
    {
        // Verify ownership through invoice
        if ($payment->invoice->parent_id !== $request->user()->parent->id) {
            return response()->json([
                'success' => false,
                'message' => 'Tidak memiliki akses.',
            ], 403);
        }

        try {
            $paymentService = new PaymentService;
            $status = $paymentService->checkPaymentStatus($payment);

            return response()->json([
                'success' => true,
                'data' => $status,
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Gagal memeriksa status pembayaran.',
            ], 500);
        }
    }

    /**
     * Parent: submit payment proof (manual transfer).
     */
    public function store(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'invoice_id' => 'required|exists:invoices,id',
            'amount' => 'required|numeric|min:0',
            'payment_method' => 'nullable|string|max:100',
            'proof_file' => 'required|file|mimes:jpg,jpeg,png,pdf|max:5120',
            'notes' => 'nullable|string|max:500',
        ]);

        $invoice = Invoice::findOrFail($validated['invoice_id']);

        if ($invoice->parent_id !== $request->user()->parent->id) {
            return response()->json([
                'success' => false,
                'message' => 'Tidak memiliki akses ke invoice ini.',
            ], 403);
        }

        if (! $invoice->canBePaid()) {
            return response()->json([
                'success' => false,
                'message' => 'Invoice tidak dapat dibayar.',
            ], 400);
        }

        if ($validated['amount'] != $invoice->total) {
            return response()->json([
                'success' => false,
                'message' => 'Jumlah pembayaran harus sesuai dengan total invoice.',
            ], 400);
        }

        $existingPending = $invoice->payments()
            ->where('status', 'pending')
            ->first();

        if ($existingPending) {
            return response()->json([
                'success' => false,
                'message' => 'Sudah ada pembayaran yang menunggu verifikasi.',
            ], 400);
        }

        $proofPath = $request->file('proof_file')->store('payments/proof', 'local');

        $payment = Payment::create([
            'invoice_id' => $invoice->id,
            'amount' => $validated['amount'],
            'status' => 'pending',
            'payment_method' => $validated['payment_method'] ?? 'bank_transfer',
            'proof_file' => $proofPath,
            'notes' => $validated['notes'] ?? null,
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Bukti pembayaran berhasil dikirim. Menunggu verifikasi.',
            'data' => $payment->load('invoice'),
        ], 201);
    }

    /**
     * Admin: verify payment.
     */
    public function verify(Request $request, Payment $payment): JsonResponse
    {
        try {
            $paymentService = new PaymentService;
            $paymentService->verifyPayment($payment, $request->user()->id);

            return response()->json([
                'success' => true,
                'message' => 'Pembayaran berhasil diverifikasi.',
                'data' => $payment->fresh()->load(['invoice', 'verifier']),
            ]);
        } catch (\RuntimeException $e) {
            return response()->json([
                'success' => false,
                'message' => $e->getMessage(),
            ], 400);
        }
    }

    /**
     * Admin: reject payment.
     */
    public function reject(Request $request, Payment $payment): JsonResponse
    {
        $validated = $request->validate([
            'reason' => 'nullable|string|max:500',
        ]);

        try {
            $paymentService = new PaymentService;
            $paymentService->rejectPayment($payment, $request->user()->id, $validated['reason'] ?? null);

            return response()->json([
                'success' => true,
                'message' => 'Pembayaran ditolak.',
                'data' => $payment->fresh()->load(['invoice', 'verifier']),
            ]);
        } catch (\RuntimeException $e) {
            return response()->json([
                'success' => false,
                'message' => $e->getMessage(),
            ], 400);
        }
    }

    /**
     * Admin: view payment proof file.
     */
    public function showProof(Payment $payment): JsonResponse
    {
        if (! $payment->proof_file) {
            return response()->json([
                'success' => false,
                'message' => 'Bukti pembayaran tidak tersedia.',
            ], 404);
        }

        if (! Storage::disk('local')->exists($payment->proof_file)) {
            return response()->json([
                'success' => false,
                'message' => 'File bukti pembayaran tidak ditemukan.',
            ], 404);
        }

        $url = Storage::disk('local')->temporaryUrl(
            $payment->proof_file,
            now()->addMinutes(30)
        );

        return response()->json([
            'success' => true,
            'data' => [
                'url' => $url,
                'expires_at' => now()->addMinutes(30)->toIso8601String(),
            ],
        ]);
    }

    /**
     * Parent: view own payment history for specific invoice.
     */
    public function parentInvoicePayments(Request $request, Invoice $invoice): JsonResponse
    {
        if ($invoice->parent_id !== $request->user()->parent->id) {
            return response()->json([
                'success' => false,
                'message' => 'Tidak memiliki akses ke invoice ini.',
            ], 403);
        }

        $payments = $invoice->payments()
            ->orderBy('created_at', 'desc')
            ->get();

        return response()->json([
            'success' => true,
            'data' => $payments,
        ]);
    }

    /**
     * Webhook: handle payment provider callback.
     */
    public function webhook(Request $request): JsonResponse
    {
        try {
            $paymentService = new PaymentService;
            $paymentService->handleWebhook($request->all());

            return response()->json(['success' => true]);
        } catch (\Exception $e) {
            Log::error('Payment webhook error', ['error' => $e->getMessage()]);

            return response()->json(['success' => false], 500);
        }
    }
}
