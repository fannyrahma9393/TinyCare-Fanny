<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('payments', function (Blueprint $table) {
            $table->string('transaction_id')->nullable()->after('id');
            $table->string('gateway_provider')->nullable()->after('transaction_id');
            $table->json('gateway_response')->nullable()->after('gateway_provider');
            $table->string('payment_url')->nullable()->after('gateway_response');
            $table->timestamp('paid_at')->nullable()->after('verified_at');
        });
    }

    public function down(): void
    {
        Schema::table('payments', function (Blueprint $table) {
            $table->dropColumn([
                'transaction_id',
                'gateway_provider',
                'gateway_response',
                'payment_url',
                'paid_at',
            ]);
        });
    }
};
