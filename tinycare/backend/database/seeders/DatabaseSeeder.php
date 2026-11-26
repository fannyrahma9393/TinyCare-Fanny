<?php

namespace Database\Seeders;

use App\Models\Admin;
use App\Models\Role;
use App\Models\User;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;

class DatabaseSeeder extends Seeder
{
    public function run(): void
    {
        // Seed roles
        $this->call(RoleSeeder::class);

        // Create default admin_master
        $adminMasterRole = Role::where('name', 'admin_master')->first();

        $adminMasterUser = User::firstOrCreate(
            ['email' => 'admin@tinycare.com'],
            [
                'name' => 'Admin TinyCare',
                'password' => Hash::make('password123'),
                'role_id' => $adminMasterRole->id,
                'status' => 'active',
                'email_verified_at' => now(),
            ]
        );

        Admin::firstOrCreate(
            ['user_id' => $adminMasterUser->id],
            [
                'phone' => '081234567890',
                'position' => 'Manager',
            ]
        );

        // Seed sample data
        $this->call(SampleDataSeeder::class);

        // Seed translation baseline (idempotent: existing rows are preserved)
        $this->call(TranslationsSeeder::class);
    }
}
