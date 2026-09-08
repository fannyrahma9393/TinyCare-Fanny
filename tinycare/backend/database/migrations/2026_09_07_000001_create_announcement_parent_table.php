<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Pivot storing direct parent targets for announcements.
     *
     * An announcement with rows in this table is only visible/notified to the
     * listed parents (combined with announcement_child when child targeting is
     * also used). An announcement with no rows in either pivot is a broadcast
     * to all active parents.
     */
    public function up(): void
    {
        Schema::create('announcement_parent', function (Blueprint $table) {
            $table->id();
            $table->foreignId('announcement_id')->constrained()->cascadeOnDelete();
            $table->foreignId('parent_id')->constrained('parents')->cascadeOnDelete();
            $table->timestamps();

            $table->unique(['announcement_id', 'parent_id']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('announcement_parent');
    }
};