<?php

namespace App\Services\Payment;

use App\Models\Invoice;
use App\Models\Payment;

interface PaymentGatewayInterface
{
    /**
     * Create a payment transaction for an invoice.
     * Returns payment_url (for redirect) or payment instructions.
     */
    public function createTransaction(Invoice $invoice, Payment $payment): array;

    /**
     * Check the status of a payment transaction.
     * Returns ['status' => string, 'paid' => bool, 'gateway_response' => array].
     */
    public function checkStatus(Payment $payment): array;

    /**
     * Handle webhook/callback from payment provider.
     * Returns payment_id or null.
     */
    public function handleCallback(array $payload): ?int;

    /**
     * Get the provider name.
     */
    public function getProviderName(): string;
}
