<?php

namespace Database\Seeders;

use App\Models\Activity;
use App\Models\Admin;
use App\Models\Announcement;
use App\Models\Attendance;
use App\Models\AuthorizedPickup;
use App\Models\Child;
use App\Models\ChildActivity;
use App\Models\ChildPackage;
use App\Models\DailyStory;
use App\Models\DevelopmentAssessment;
use App\Models\DevelopmentCategory;
use App\Models\Event;
use App\Models\Invoice;
use App\Models\Package;
use App\Models\ParentModel;
use App\Models\Role;
use App\Models\User;
use App\Models\Voucher;
use Carbon\Carbon;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;

class SampleDataSeeder extends Seeder
{
    public function run(): void
    {
        $adminRole = Role::where('name', 'admin')->first();
        $parentRole = Role::where('name', 'parent')->first();

        // Create additional admin
        $admin2 = User::create([
            'name' => 'Staff Daycare',
            'email' => 'staff@tinycare.com',
            'password' => Hash::make('password123'),
            'role_id' => $adminRole->id,
            'status' => 'active',
        ]);
        Admin::create(['user_id' => $admin2->id, 'phone' => '081234567891', 'position' => 'Staff']);

        // Create parents
        $parentUsers = [];
        $parentModels = [];
        $emails = ['budi@example.com', 'sari@example.com', 'andi@example.com'];

        foreach ($emails as $i => $email) {
            $user = User::create([
                'name' => ['Budi Santoso', 'Sari Dewi', 'Andi Pratama'][$i],
                'email' => $email,
                'password' => Hash::make('password123'),
                'role_id' => $parentRole->id,
                'status' => 'active',
            ]);
            $parent = ParentModel::create([
                'user_id' => $user->id,
                'phone' => '08123456'.str_pad($i, 4, '0', STR_PAD_LEFT),
                'address' => ['Jl. Merdeka No. 1', 'Jl. Sudirman No. 2', 'Jl. Gatot Subroto No. 3'][$i],
            ]);
            $parentUsers[] = $user;
            $parentModels[] = $parent;
        }

        // Create children
        $children = [];
        $childData = [
            ['name' => 'Rina Santoso', 'gender' => 'female', 'birth_date' => '2022-03-15'],
            ['name' => 'Dika Dewi', 'gender' => 'male', 'birth_date' => '2021-08-20'],
            ['name' => 'Lina Pratama', 'gender' => 'female', 'birth_date' => '2022-11-10'],
        ];

        foreach ($childData as $i => $data) {
            $child = Child::create(array_merge($data, [
                'status' => 'active',
                'health_info' => 'Tidak ada alergi',
            ]));
            $child->parents()->attach($parentModels[$i]->id);
            $children[] = $child;
        }

        // Create packages
        $packages = [];
        $packageData = [
            ['name' => 'Paket Basic', 'price' => 500000, 'duration_days' => 30, 'facilities' => 'Ruang kelas, AC, CCTV'],
            ['name' => 'Paket Professional', 'price' => 800000, 'duration_days' => 30, 'facilities' => 'Ruang kelas, AC, CCTV, Daily Report, Development Tracking'],
            ['name' => 'Paket Premium', 'price' => 1200000, 'duration_days' => 30, 'facilities' => 'Semua fasilitas + QR Attendance, Pickup Management, Advanced Reports'],
        ];

        foreach ($packageData as $data) {
            $packages[] = Package::create(array_merge($data, [
                'description' => 'Paket '.$data['name'],
                'status' => 'active',
                'start_date' => now()->subMonth(),
                'end_date' => now()->addYear(),
            ]));
        }

        // Assign packages to children
        ChildPackage::create([
            'child_id' => $children[0]->id,
            'package_id' => $packages[1]->id,
            'start_date' => now()->subMonth(),
            'end_date' => now()->addMonths(2),
            'status' => 'active',
        ]);
        ChildPackage::create([
            'child_id' => $children[1]->id,
            'package_id' => $packages[2]->id,
            'start_date' => now()->subWeeks(2),
            'end_date' => now()->addMonths(2),
            'status' => 'active',
        ]);

        // Create vouchers
        Voucher::create([
            'code' => 'WELCOME20',
            'description' => 'Diskon 20% untuk pendaftaran pertama',
            'discount_type' => 'percentage',
            'discount_value' => 20,
            'min_transaction' => 100000,
            'max_usage' => 10,
            'start_date' => now()->subMonth(),
            'end_date' => now()->addMonths(3),
            'status' => 'active',
        ]);

        Voucher::create([
            'code' => 'HEMAT50K',
            'description' => 'Diskon Rp 50.000',
            'discount_type' => 'nominal',
            'discount_value' => 50000,
            'min_transaction' => 200000,
            'max_usage' => 5,
            'start_date' => now(),
            'end_date' => now()->addMonths(2),
            'status' => 'active',
        ]);

        // Create activities
        $activities = [];
        $activityData = [
            ['name' => 'Menggambar', 'category' => 'seni'],
            ['name' => 'Bermain Pasir', 'category' => 'bermain'],
            ['name' => 'Bernyanyi', 'category' => 'edukasi'],
            ['name' => 'Bermain Bola', 'category' => 'olahraga'],
            ['name' => 'Membaca Cerita', 'category' => 'edukasi'],
            ['name' => 'Makan Bersama', 'category' => 'makan'],
            ['name' => 'Tidur Siang', 'category' => 'istirahat'],
        ];

        foreach ($activityData as $data) {
            $activities[] = Activity::create(array_merge($data, [
                'status' => 'active',
            ]));
        }

        // Create development categories
        $categories = [];
        $categoryData = [
            ['name' => 'motorik', 'icon' => '🏃', 'sort_order' => 1],
            ['name' => 'bahasa', 'icon' => '💬', 'sort_order' => 2],
            ['name' => 'sosial', 'icon' => '👫', 'sort_order' => 3],
            ['name' => 'kognitif', 'icon' => '🧠', 'sort_order' => 4],
            ['name' => 'kemandirian', 'icon' => 'Independence', 'sort_order' => 5],
        ];

        foreach ($categoryData as $data) {
            $categories[] = DevelopmentCategory::create(array_merge($data, [
                'description' => 'Kategori perkembangan '.$data['name'],
                'status' => 'active',
            ]));
        }

        // Create attendance for today and past few days
        $statuses = ['hadir', 'hadir', 'hadir', 'izin', 'sakit', 'hadir'];
        for ($i = 0; $i < 6; $i++) {
            $date = Carbon::today()->subDays($i);
            foreach ($children as $child) {
                Attendance::create([
                    'child_id' => $child->id,
                    'date' => $date,
                    'status' => $statuses[$i],
                    'check_in_time' => $statuses[$i] === 'hadir' ? '07:30' : null,
                    'check_out_time' => $statuses[$i] === 'hadir' ? '16:00' : null,
                    'recorded_by' => $admin2->id,
                ]);
            }
        }

        // Create daily stories for today
        foreach ($children as $child) {
            DailyStory::create([
                'child_id' => $child->id,
                'date' => now()->toDateString(),
                'summary' => "Hari ini {$child->name} mengikuti kegiatan dengan baik. Anak makan dengan lahap dan tidur siang dengan nyenyak.",
                'mood' => 'bahagia',
                'meal_notes' => 'Makan pagi: bubur ayam, Makan siang: nasi ayam goreng',
                'sleep_notes' => 'Tidur siang: 13:00 - 14:30',
                'admin_notes' => 'Anak sangat aktif dan ceria hari ini',
                'meal_rating' => 4.5,
                'sleep_hours' => 1.5,
                'created_by' => $admin2->id,
            ]);
        }

        // Create child activities for today
        foreach ($children as $child) {
            foreach (array_slice($activities, 0, 4) as $activity) {
                ChildActivity::create([
                    'child_id' => $child->id,
                    'activity_id' => $activity->id,
                    'date' => now()->toDateString(),
                    'time' => '09:00',
                    'status' => 'selesai',
                    'notes' => 'Mengikuti dengan antusias',
                ]);
            }
        }

        // Create development assessments
        foreach ($children as $child) {
            foreach (array_slice($categories, 0, 3) as $category) {
                DevelopmentAssessment::create([
                    'child_id' => $child->id,
                    'development_category_id' => $category->id,
                    'indicator' => 'Indikator dasar '.$category->name,
                    'notes' => 'Anak menunjukkan perkembangan yang baik',
                    'progress' => ['mulai', 'berkembang', 'baik'][array_rand([0, 1, 2])],
                    'observation_date' => now()->subDays(rand(1, 7)),
                    'assessed_by' => $admin2->id,
                ]);
            }
        }

        // Create authorized pickups
        foreach ($children as $i => $child) {
            AuthorizedPickup::create([
                'parent_id' => $parentModels[$i]->id,
                'child_id' => $child->id,
                'name' => 'Paman '.$child->name,
                'phone' => '08199999'.str_pad($i, 4, '0', STR_PAD_LEFT),
                'relationship' => 'paman',
                'status' => 'active',
            ]);
        }

        // Create announcements
        Announcement::create([
            'title' => 'Libur Nasional',
            'content' => 'Daycare akan libur pada tanggal 17 Agustus 2026 dalam rangka Hari Kemerdekaan.',
            'priority' => 'high',
            'publish_date' => now(),
            'expire_date' => now()->addWeek(),
            'is_published' => true,
            'created_by' => auth()->id(),
        ]);

        Announcement::create([
            'title' => 'Jadwal Vaksinasi',
            'content' => 'Akan diadakan vaksinasi rutin pada minggu depan. Mohon pastikan anak dalam kondisi sehat.',
            'priority' => 'normal',
            'publish_date' => now(),
            'is_published' => true,
            'created_by' => auth()->id(),
        ]);

        // Create events
        Event::create([
            'title' => 'Lomba 17 Agustus',
            'description' => 'Lomba memperingati Hari Kemerdekaan RI',
            'date' => now()->addDays(24)->toDateString(),
            'start_time' => '08:00',
            'end_time' => '11:00',
            'location' => 'Halaman Daycare',
            'type' => 'special',
            'status' => 'scheduled',
            'created_by' => auth()->id(),
        ]);

        Event::create([
            'title' => 'Parent Meeting',
            'description' => 'Pertemuan orang tua untuk membahas perkembangan anak',
            'date' => now()->addWeek()->toDateString(),
            'start_time' => '14:00',
            'end_time' => '16:00',
            'location' => 'Ruang Rapat',
            'type' => 'meeting',
            'status' => 'scheduled',
            'created_by' => auth()->id(),
        ]);

        // Create invoices
        Invoice::create([
            'invoice_number' => 'INV-202608-0001',
            'child_id' => $children[0]->id,
            'package_id' => $packages[1]->id,
            'parent_id' => $parentModels[0]->id,
            'subtotal' => 800000,
            'discount' => 0,
            'total' => 800000,
            'due_date' => now()->addDays(7),
            'status' => 'pending',
        ]);

        Invoice::create([
            'invoice_number' => 'INV-202608-0002',
            'child_id' => $children[1]->id,
            'package_id' => $packages[2]->id,
            'parent_id' => $parentModels[1]->id,
            'subtotal' => 1200000,
            'discount' => 50000,
            'total' => 1150000,
            'due_date' => now()->addDays(7),
            'status' => 'pending',
        ]);

        $this->command->info('✅ Sample data berhasil dibuat!');
        $this->command->info('📧 Admin: admin@tinycare.com / password123');
        $this->command->info('📧 Parent: budi@example.com / password123');
        $this->command->info('👶 Children: 3 anak terdaftar');
        $this->command->info('📦 Packages: 3 paket tersedia');
        $this->command->info('🎫 Vouchers: 2 voucher aktif');
    }
}
