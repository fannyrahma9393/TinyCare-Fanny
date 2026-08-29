<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('daily_stories', function (Blueprint $table) {
            $table->id();
            $table->foreignId('child_id')->constrained()->cascadeOnDelete();
            $table->date('date');
            $table->text('summary')->nullable(); // ringkasan naratif hari ini
            $table->string('mood')->nullable(); // bahagia, biasa, sedih, sakit, rewel
            $table->text('meal_notes')->nullable(); // catatan makan
            $table->text('sleep_notes')->nullable(); // catatan tidur
            $table->text('admin_notes')->nullable(); // catatan admin
            $table->decimal('meal_rating', 3, 1)->nullable(); // rating makan 1-5
            $table->decimal('sleep_hours', 4, 1)->Nullable(); // jam tidur
            $table->foreignId('created_by')->nullable()->constrained('users')->nullOnDelete();
            $table->timestamps();

            $table->unique(['child_id', 'date']);
            $table->index('date');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('daily_stories');
    }
};
