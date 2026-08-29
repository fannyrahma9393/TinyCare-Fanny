<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('development_assessments', function (Blueprint $table) {
            $table->id();
            $table->foreignId('child_id')->constrained()->cascadeOnDelete();
            $table->foreignId('development_category_id')->constrained()->cascadeOnDelete();
            $table->string('indicator'); // indikator yang dinilai
            $table->text('notes')->nullable(); // catatan observasi
            $table->enum('progress', ['belum', 'mulai', 'berkembang', 'baik', 'sangat_baik'])->default('belum');
            $table->date('observation_date');
            $table->foreignId('assessed_by')->nullable()->constrained('users')->nullOnDelete();
            $table->timestamps();

            $table->index(['child_id', 'development_category_id']);
            $table->index('observation_date');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('development_assessments');
    }
};
