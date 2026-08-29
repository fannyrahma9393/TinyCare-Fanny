<?php

namespace App\Services\Payment;

use App\Models\Invoice;
use App\Models\Payment;
use Illuminate\Support\Str;

/**
 * Manual Bank Transfer Gateway (Sandbox/Development).
 *
 * In development mode, this generates a unique VA number and payment instructions.
 * Admin manually verifies payment after receiving bank transfer confirmation.
 *
 * For production, replace with Midtrans, Xendit, or other payment gateway.
 */
class ManualTransferGateway implements PaymentGatewayInterface
{
    public function createTransaction(Invoice $invoice, Payment $payment): array
    {
        // Generate unique virtual account / transfer reference
        $vaNumber = '8888'.str_pad($invoice->id, 6, '0', STR_PAD_LEFT);
        $transferAmount = (int) $invoice->total;
        $uniqueDigit = $transferAmount % 10;
        $totalWithCode = $transferAmount + $uniqueDigit;

        $expiresAt = now()->addHours(24);

        // Update payment with transaction details
        $payment->update([
            'transaction_id' => 'TXN-'.strtoupper(Str::random(12)),
            'gateway_provider' => 'manual_transfer',
            'gateway_response' => [
                'va_number' => $vaNumber,
                'bank_name' => 'Bank BCA',
                'account_name' => 'TinyCare Daycare',
                'amount' => $transferAmount,
                'total_with_code' => $totalWithCode,
                'unique_digit' => $uniqueDigit,
                'expires_at' => $expiresAt->toIso8601String(),
                'instructions' => [
                    'ATM' => "Transfer ke Virtual Account {$vaNumber} di ATM BCA",
                    'Mobile Banking' => "Pembayaran > Virtual Account > Masukkan {$vaNumber}",
                    'Internet Banking' => "Transfer Virtual Account > {$vaNumber}",
                ],
            ],
            'paid_at' => null,
        ]);

        return [
            'payment_id' => $payment->id,
            'transaction_id' => $payment->transaction_id,
            'status' => 'pending',
            'va_number' => $vaNumber,
            'bank_name' => 'Bank BCA',
            'account_name' => 'TinyCare Daycare',
            'amount' => $transferAmount,
            'total_with_code' => $totalWithCode,
            'expires_at' => $expiresAt->toIso8601String(),
            'instructions' => $payment->gateway_response['instructions'] ?? [],
        ];
    }

    public function checkStatus(Payment $payment): array
    {
        // For manual transfer, status is managed by admin verification
        return [
            'status' => $payment->status,
            'paid' => $payment->status === 'verified',
            'gateway_response' => $payment->gateway_response ?? [],
        ];
    }

    public function handleCallback(array $payload): ?int
    {
        // Manual transfer doesn't have automated callbacks
        // Admin verifies manually
        return null;
    }

    public function getProviderName(): string
    {
        return 'manual_transfer';
    }
}
