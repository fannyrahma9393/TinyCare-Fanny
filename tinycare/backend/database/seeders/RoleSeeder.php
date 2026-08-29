<?php

namespace Database\Seeders;

use App\Models\Role;
use Illuminate\Database\Seeder;

class RoleSeeder extends Seeder
{
    public function run(): void
    {
        Role::firstOrCreate(['name' => 'parent'], [
            'description' => 'Orang tua/wali dari anak yang terdaftar di daycare.',
        ]);

        Role::firstOrCreate(['name' => 'admin'], [
            'description' => 'Pengelola daycare dengan akses operasional dan finansial penuh.',
        ]);

        Role::firstOrCreate(['name' => 'admin_master'], [
            'description' => 'Admin utama yang dapat mengelola admin lainnya.',
        ]);
    }
}
