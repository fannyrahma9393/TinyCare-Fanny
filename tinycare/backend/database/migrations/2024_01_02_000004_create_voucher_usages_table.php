<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('voucher_usages', function (Blueprint $table) {
            $table->id();
            $table->foreignId('voucher_id')->constrained()->cascadeOnDelete();
            $table->unsignedBigInteger('invoice_id')->nullable(); // FK ke invoices (Phase 3)
            $table->foreignId('parent_id')->nullable()->constrained('parents')->nullOnDelete();
            $table->decimal('discount_applied', 12, 2);
            $table->timestamps();

            $table->index(['voucher_id', 'invoice_id']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('voucher_usages');
    }
};
