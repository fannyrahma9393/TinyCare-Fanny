<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Additive migration: creates the `translations` table used as the global
     * (admin-editable) overlay for Web + Mobile UI wording. Existing tables
     * are untouched. The (key, locale) unique index prevents duplicates —
     * keys are stable identifiers (mostly the Indonesian source text used by
     * the existing client catalogs, plus `notif.*` system-notification keys).
     */
    public function up(): void
    {
        Schema::create('translations', function (Blueprint $table) {
            $table->id();
            $table->string('key', 191);
            $table->string('locale', 5); // 'id' | 'en' (validated at the API layer too)
            $table->text('value');
            $table->timestamps();

            $table->unique(['key', 'locale']);
            $table->index('locale');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('translations');
    }
};
