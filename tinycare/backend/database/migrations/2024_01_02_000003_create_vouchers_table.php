<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('vouchers', function (Blueprint $table) {
            $table->id();
            $table->string('code')->unique(); // kode unik voucher
            $table->string('description')->nullable();
            $table->enum('discount_type', ['nominal', 'percentage']);
            $table->decimal('discount_value', 12, 2); // nominal atau persentase
            $table->decimal('min_transaction', 12, 2)->default(0); // minimum transaksi
            $table->integer('max_usage')->default(1); // batas jumlah penggunaan
            $table->integer('current_usage')->default(0); // sudah dipakai berapa kali
            $table->date('start_date');
            $table->date('end_date');
            $table->string('status')->default('active'); // active, inactive, expired
            $table->timestamps();

            $table->index('status');
            $table->index('code');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('vouchers');
    }
};
