<?php

namespace App\Models;

use App\Support\MediaUrl;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Support\Facades\Storage;

class Payment extends Model
{
    protected $fillable = [
        'invoice_id',
        'amount',
        'status',
        'payment_method',
        'proof_file',
        'notes',
        'verified_by',
        'verified_at',
        'transaction_id',
        'gateway_provider',
        'gateway_response',
        'payment_url',
        'paid_at',
    ];

    protected $casts = [
        'amount' => 'decimal:2',
        'verified_at' => 'datetime',
        'paid_at' => 'datetime',
        'gateway_response' => 'array',
    ];

    public function invoice(): BelongsTo
    {
        return $this->belongsTo(Invoice::class);
    }

    public function verifier(): BelongsTo
    {
        return $this->belongsTo(User::class, 'verified_by');
    }

    /**
     * Check if payment is verified.
     */
    public function isVerified(): bool
    {
        return $this->status === 'verified';
    }

    /**
     * Check if payment is pending.
     */
    public function isPending(): bool
    {
        return $this->status === 'pending';
    }

    /**
     * Verify payment and mark invoice as paid.
     */
    public function verify(User $admin): void
    {
        $this->update([
            'status' => 'verified',
            'verified_by' => $admin->id,
            'verified_at' => now(),
        ]);

        // Mark invoice as paid
        $this->invoice->markAsPaid();
    }

    /**
     * Reject payment.
     */
    public function reject(User $admin, ?string $reason = null): void
    {
        $this->update([
            'status' => 'rejected',
            'verified_by' => $admin->id,
            'verified_at' => now(),
            'notes' => $reason ?? $this->notes,
        ]);
    }

    /**
     * Get status label.
     */
    public function getStatusLabelAttribute(): string
    {
        return match ($this->status) {
            'pending' => 'Menunggu Verifikasi',
            'verified' => 'Terverifikasi',
            'rejected' => 'Ditolak',
            default => $this->status,
        };
    }

    /**
     * Get proof file URL (private storage).
     */
    public function getProofUrlAttribute(): ?string
    {
        if (! $this->proof_file) {
            return null;
        }

        // Use temporary URL for private file access
        return MediaUrl::temporary($this->proof_file);
    }
}
