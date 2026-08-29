<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('weekly_reports', function (Blueprint $table) {
            $table->id();
            $table->foreignId('child_id')->constrained()->cascadeOnDelete();
            $table->date('week_start');
            $table->date('week_end');
            $table->integer('total_attendance')->default(0);
            $table->integer('total_activities')->default(0);
            $table->integer('total_daily_stories')->default(0);
            $table->text('attendance_summary')->nullable();
            $table->text('activity_summary')->nullable();
            $table->text('development_summary')->nullable();
            $table->text('overall_summary')->nullable();
            $table->boolean('is_generated')->default(false);
            $table->timestamps();

            $table->unique(['child_id', 'week_start']);
            $table->index('week_start');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('weekly_reports');
    }
};
