<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('development_categories', function (Blueprint $table) {
            $table->id();
            $table->string('name'); // motorik, bahasa, sosial, kognitif, kemandirian
            $table->text('description')->nullable();
            $table->string('icon')->nullable(); // icon untuk tampilan
            $table->integer('sort_order')->default(0);
            $table->string('status')->default('active');
            $table->timestamps();

            $table->index('status');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('development_categories');
    }
};
