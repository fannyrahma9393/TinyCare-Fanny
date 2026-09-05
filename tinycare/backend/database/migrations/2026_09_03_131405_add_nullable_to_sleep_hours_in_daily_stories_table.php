<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Make sleep_hours nullable.
     *
     * A historical migration declared the column with ->Nullable() (capital N),
     * which Laravel's Blueprint never applied as a real nullable flag, so the
     * column was physically created as NOT NULL in already-deployed databases
     * (and would also reject rows that omit sleep_hours). This migration
     * corrects existing schemas to match the intended, controller-validated
     * semantics where sleep_hours is optional.
     */
    public function up(): void
    {
        Schema::table('daily_stories', function (Blueprint $table) {
            $table->decimal('sleep_hours', 4, 1)->nullable()->change();
        });
    }

    /**
     * Reverse: bring back NOT NULL (matches the accidentally-created schema).
     */
    public function down(): void
    {
        Schema::table('daily_stories', function (Blueprint $table) {
            $table->decimal('sleep_hours', 4, 1)->nullable(false)->change();
        });
    }
};
