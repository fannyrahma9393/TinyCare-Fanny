<?php

namespace App\Models;

use Carbon\Carbon;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Voucher extends Model
{
    protected $fillable = [
        'code',
        'description',
        'discount_type',
        'discount_value',
        'min_transaction',
        'max_usage',
        'current_usage',
        'start_date',
        'end_date',
        'status',
    ];

    protected $casts = [
        'discount_value' => 'decimal:2',
        'min_transaction' => 'decimal:2',
        'max_usage' => 'integer',
        'current_usage' => 'integer',
        'start_date' => 'date',
        'end_date' => 'date',
    ];

    public function usages(): HasMany
    {
        return $this->hasMany(VoucherUsage::class);
    }

    /**
     * Check if voucher can be used.
     */
    public function canBeUsed(float $transactionAmount): bool
    {
        // Check status
        if (($this->status ?? 'active') !== 'active') {
            return false;
        }

        // Check date validity
        $now = Carbon::now();
        if ($this->start_date && $now->lt($this->start_date)) {
            return false;
        }
        if ($this->end_date && $now->gt($this->end_date)) {
            return false;
        }

        // Check usage limit
        $currentUsage = (int) ($this->current_usage ?? 0);
        $maxUsage = (int) ($this->max_usage ?? 1);
        if ($currentUsage >= $maxUsage) {
            return false;
        }

        // Check minimum transaction
        $minTransaction = (float) ($this->min_transaction ?? 0);
        if ($transactionAmount < $minTransaction) {
            return false;
        }

        return true;
    }

    /**
     * Calculate discount amount.
     */
    public function calculateDiscount(float $amount): float
    {
        if ($this->discount_type === 'percentage') {
            return ($amount * $this->discount_value) / 100;
        }

        return min($this->discount_value, $amount); // nominal, max = amount
    }

    public function isExpired(): bool
    {
        return Carbon::now()->gt($this->end_date);
    }
}
