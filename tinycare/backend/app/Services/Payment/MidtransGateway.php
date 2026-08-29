<?php

namespace App\Services\Payment;

use App\Models\Invoice;
use App\Models\Payment;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;

/**
 * Midtrans Payment Gateway (Production-ready).
 *
 * Requires environment variables:
 *   PAYMENT_PROVIDER=midtrans
 *   PAYMENT_SERVER_KEY=SB-Mid-server-xxxx
 *   PAYMENT_CLIENT_KEY=SB-Mid-client-xxxx
 *   PAYMENT_MERCHANT_ID=xxxx
 *   PAYMENT_IS_SANDBOX=true (or false for production)
 */
class MidtransGateway implements PaymentGatewayInterface
{
    private string $serverKey;

    private string $baseUrl;

    public function __construct()
    {
        $this->serverKey = config('services.payment.server_key', '');
        $isSandbox = config('services.payment.is_sandbox', true);
        $this->baseUrl = $isSandbox
            ? 'https://api.sandbox.midtrans.com'
            : 'https://api.midtrans.com';
    }

    public function createTransaction(Invoice $invoice, Payment $payment): array
    {
        if (empty($this->serverKey)) {
            throw new \RuntimeException(
                'Midtrans server key belum dikonfigurasi. '
                .'Atur PAYMENT_SERVER_KEY di .env'
            );
        }

        $orderId = 'TINY-'.$invoice->id.'-'.strtoupper(substr(uniqid(), -6));

        $payload = [
            'transaction_details' => [
                'order_id' => $orderId,
                'gross_amount' => (int) $invoice->total,
            ],
            'customer_details' => [
                'first_name' => $invoice->parent->user->name ?? 'Parent',
                'email' => $invoice->parent->user->email ?? '',
            ],
            'callbacks' => [
                'finish' => config('app.url').'/parent/invoices/'.$invoice->id,
            ],
        ];

        $response = Http::withBasicAuth($this->serverKey, '')
            ->post("{$this->baseUrl}/v1/payment-links", $payload);

        if (! $response->successful()) {
            Log::error('Midtrans payment link creation failed', [
                'status' => $response->status(),
                'response' => $response->json(),
            ]);
            throw new \RuntimeException('Gagal membuat payment link.');
        }

        $data = $response->json();

        $payment->update([
            'transaction_id' => $orderId,
            'gateway_provider' => 'midtrans',
            'gateway_response' => $data,
            'payment_url' => $data['payment_url'] ?? null,
        ]);

        return [
            'payment_id' => $payment->id,
            'transaction_id' => $orderId,
            'status' => 'pending',
            'payment_url' => $data['payment_url'] ?? null,
            'expires_at' => $data['expiry_time'] ?? now()->addHours(24)->toIso8601String(),
        ];
    }

    public function checkStatus(Payment $payment): array
    {
        if (empty($this->serverKey)) {
            return [
                'status' => $payment->status,
                'paid' => $payment->status === 'verified',
                'gateway_response' => $payment->gateway_response ?? [],
            ];
        }

        $orderId = $payment->transaction_id;
        if (! $orderId) {
            return [
                'status' => $payment->status,
                'paid' => false,
                'gateway_response' => [],
            ];
        }

        $response = Http::withBasicAuth($this->serverKey, '')
            ->get("{$this->baseUrl}/v2/{$orderId}/status");

        if (! $response->successful()) {
            return [
                'status' => $payment->status,
                'paid' => false,
                'gateway_response' => $payment->gateway_response ?? [],
            ];
        }

        $data = $response->json();
        $transactionStatus = $data['transaction_status'] ?? '';
        $statusCode = $data['status_code'] ?? '';

        $isPaid = in_array($transactionStatus, ['capture', 'settlement']);

        return [
            'status' => $isPaid ? 'verified' : $transactionStatus,
            'paid' => $isPaid,
            'gateway_response' => $data,
        ];
    }

    public function handleCallback(array $payload): ?int
    {
        // Midtrans sends callback with order_id and transaction_status
        $orderId = $payload['order_id'] ?? null;
        $transactionStatus = $payload['transaction_status'] ?? null;

        if (! $orderId || ! $transactionStatus) {
            return null;
        }

        $payment = Payment::where('transaction_id', $orderId)->first();
        if (! $payment) {
            return null;
        }

        $isPaid = in_array($transactionStatus, ['capture', 'settlement']);

        if ($isPaid && $payment->status === 'pending') {
            $payment->update([
                'status' => 'verified',
                'paid_at' => now(),
                'gateway_response' => $payload,
            ]);
            $payment->invoice->markAsPaid();

            Log::info('Midtrans payment verified via webhook', [
                'payment_id' => $payment->id,
                'order_id' => $orderId,
            ]);

            return $payment->id;
        }

        return null;
    }

    public function getProviderName(): string
    {
        return 'midtrans';
    }
}
