<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('child_activities', function (Blueprint $table) {
            $table->id();
            $table->foreignId('child_id')->constrained()->cascadeOnDelete();
            $table->foreignId('activity_id')->constrained()->cascadeOnDelete();
            $table->date('date');
            $table->time('time')->nullable(); // waktu kegiatan
            $table->string('status')->nullable(); // selesai, sedang berlangsung, tidak hadir
            $table->text('notes')->nullable();
            $table->timestamps();

            $table->index(['child_id', 'date']);
            $table->index(['activity_id', 'date']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('child_activities');
    }
};
