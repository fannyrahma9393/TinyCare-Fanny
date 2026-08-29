<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class Notification extends Model
{
    protected $fillable = [
        'user_id',
        'type',
        'title',
        'message',
        'link',
        'is_read',
        'read_at',
        'data',
    ];

    protected $casts = [
        'is_read' => 'boolean',
        'read_at' => 'datetime',
        'data' => 'array',
    ];

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    /**
     * Mark notification as read.
     */
    public function markAsRead(): void
    {
        $this->update([
            'is_read' => true,
            'read_at' => now(),
        ]);
    }

    /**
     * Get type label.
     */
    public function getTypeLabelAttribute(): string
    {
        return match ($this->type) {
            'payment_success' => 'Pembayaran Berhasil',
            'payment_due' => 'Pembayaran Jatuh Tempo',
            'voucher_available' => 'Voucher Tersedia',
            'announcement' => 'Pengumuman',
            'development_report' => 'Laporan Perkembangan',
            'daily_story' => 'Hari Ini di Daycare',
            'activity_new' => 'Aktivitas Baru',
            'check_in' => 'Check In',
            'check_out' => 'Check Out',
            default => $this->type,
        };
    }

    /**
     * Get type icon.
     */
    public function getTypeIconAttribute(): string
    {
        return match ($this->type) {
            'payment_success' => '💰',
            'payment_due' => '⏰',
            'voucher_available' => '🎁',
            'announcement' => '📢',
            'development_report' => '📊',
            'daily_story' => '📖',
            'activity_new' => '🎨',
            'check_in' => '✅',
            'check_out' => '🏠',
            default => '🔔',
        };
    }
}
