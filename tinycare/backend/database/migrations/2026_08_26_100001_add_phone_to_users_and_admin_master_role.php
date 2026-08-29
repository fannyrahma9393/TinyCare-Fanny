<?php

use App\Models\Role;
use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        // Add phone to users table
        Schema::table('users', function (Blueprint $table) {
            $table->string('phone')->nullable()->after('password');
        });

        // Create admin_master role
        Role::firstOrCreate(
            ['name' => 'admin_master'],
            ['description' => 'Admin utama yang dapat mengelola admin lainnya.']
        );
    }

    public function down(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->dropColumn('phone');
        });

        Role::where('name', 'admin_master')->delete();
    }
};
