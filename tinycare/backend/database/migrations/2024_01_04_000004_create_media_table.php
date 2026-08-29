<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('media', function (Blueprint $table) {
            $table->id();
            $table->string('file_path'); // path file
            $table->string('file_type'); // image, video
            $table->string('file_name'); // nama file asli
            $table->unsignedBigInteger('file_size'); // ukuran dalam bytes
            $table->text('caption')->nullable();
            $table->string('mediable_type'); // polymorphic: child, activity, daily_story, event
            $table->unsignedBigInteger('mediable_id');
            $table->foreignId('uploaded_by')->nullable()->constrained('users')->nullOnDelete();
            $table->timestamps();

            $table->index(['mediable_type', 'mediable_id']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('media');
    }
};
