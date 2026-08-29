<?php

namespace App\Services\Payment;

use App\Models\Invoice;
use App\Models\Payment;
use Illuminate\Support\Facades\Log;

class PaymentService
{
    private PaymentGatewayInterface $gateway;

    public function __construct()
    {
        $provider = config('services.payment.provider', 'manual_transfer');
        $this->gateway = $this->resolveGateway($provider);
    }

    private function resolveGateway(string $provider): PaymentGatewayInterface
    {
        return match ($provider) {
            'midtrans' => new MidtransGateway,
            default => new ManualTransferGateway,
        };
    }

    /**
     * Initiate a payment for an invoice.
     */
    public function initiatePayment(Invoice $invoice, array $metadata = []): array
    {
        // Check if invoice can be paid
        if (! $invoice->canBePaid()) {
            throw new \RuntimeException('Invoice tidak dapat dibayar saat ini.');
        }

        // Check for existing pending payment
        $existingPending = $invoice->payments()
            ->where('status', 'pending')
            ->first();

        if ($existingPending) {
            // Return existing payment info instead of creating new one
            $status = $this->gateway->checkStatus($existingPending);

            return [
                'payment_id' => $existingPending->id,
                'transaction_id' => $existingPending->transaction_id,
                'status' => $existingPending->status,
                'va_number' => $existingPending->gateway_response['va_number'] ?? null,
                'bank_name' => $existingPending->gateway_response['bank_name'] ?? null,
                'amount' => $existingPending->amount,
                'expires_at' => $existingPending->gateway_response['expires_at'] ?? null,
                'instructions' => $existingPending->gateway_response['instructions'] ?? [],
                'already_pending' => true,
            ];
        }

        // Create payment record
        $payment = Payment::create([
            'invoice_id' => $invoice->id,
            'amount' => $invoice->total,
            'status' => 'pending',
            'payment_method' => $metadata['payment_method'] ?? 'bank_transfer',
        ]);

        // Create transaction via gateway
        $result = $this->gateway->createTransaction($invoice, $payment);

        Log::info('TinyCare payment initiated', [
            'invoice_id' => $invoice->id,
            'payment_id' => $payment->id,
            'amount' => $invoice->total,
            'provider' => $this->gateway->getProviderName(),
        ]);

        return $result;
    }

    /**
     * Check payment status.
     */
    public function checkPaymentStatus(Payment $payment): array
    {
        return $this->gateway->checkStatus($payment);
    }

    /**
     * Verify a payment (admin action for manual transfer).
     */
    public function verifyPayment(Payment $payment, int $adminId): void
    {
        if ($payment->status !== 'pending') {
            throw new \RuntimeException('Pembayaran sudah diproses.');
        }

        $payment->update([
            'status' => 'verified',
            'verified_by' => $adminId,
            'verified_at' => now(),
            'paid_at' => now(),
        ]);

        // Mark invoice as paid
        $payment->invoice->markAsPaid();

        Log::info('TinyCare payment verified', [
            'payment_id' => $payment->id,
            'invoice_id' => $payment->invoice_id,
            'verified_by' => $adminId,
        ]);
    }

    /**
     * Reject a payment.
     */
    public function rejectPayment(Payment $payment, int $adminId, ?string $reason = null): void
    {
        if ($payment->status !== 'pending') {
            throw new \RuntimeException('Pembayaran sudah diproses.');
        }

        $payment->update([
            'status' => 'rejected',
            'verified_by' => $adminId,
            'verified_at' => now(),
            'notes' => $reason ?? $payment->notes,
        ]);

        Log::info('TinyCare payment rejected', [
            'payment_id' => $payment->id,
            'invoice_id' => $payment->invoice_id,
            'reason' => $reason,
        ]);
    }

    /**
     * Handle webhook/callback from payment provider.
     */
    public function handleWebhook(array $payload): void
    {
        $this->gateway->handleCallback($payload);
    }
}
