<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('authorized_pickups', function (Blueprint $table) {
            $table->id();
            $table->foreignId('parent_id')->constrained('parents')->cascadeOnDelete();
            $table->foreignId('child_id')->constrained()->cascadeOnDelete();
            $table->string('name');
            $table->string('phone');
            $table->string('relationship'); // ayah, ibu, paman, bibi, kakek, nenek, lainnya
            $table->string('id_number')->nullable(); // KTP/identitas
            $table->string('photo')->nullable();
            $table->string('status')->default('active'); // active, inactive
            $table->text('notes')->nullable();
            $table->timestamps();

            $table->index(['parent_id', 'child_id']);
            $table->index('status');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('authorized_pickups');
    }
};
