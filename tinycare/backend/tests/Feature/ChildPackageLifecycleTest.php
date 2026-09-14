<?php

namespace Tests\Feature;

use App\Models\Admin;
use App\Models\Attendance;
use App\Models\Child;
use App\Models\ChildPackage;
use App\Models\DevelopmentAssessment;
use App\Models\DevelopmentCategory;
use App\Models\FcmToken;
use App\Models\Notification;
use App\Models\Package;
use App\Models\ParentModel;
use App\Models\Role;
use App\Models\User;
use App\Models\WeeklyReport;
use App\Models\MonthlyReport;
use App\Services\FcmNotificationService;
use Carbon\Carbon;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class ChildPackageLifecycleTest extends TestCase
{
    use RefreshDatabase;

    private User $admin;

    private ParentModel $parent;

    private Child $child;

    protected function setUp(): void
    {
        parent::setUp();

        FcmNotificationService::setStaticTransport(null);

        $adminRole = Role::firstOrCreate(['name' => 'admin'], ['description' => 'Admin']);
        $parentRole = Role::firstOrCreate(['name' => 'parent'], ['description' => 'Parent']);

        $this->admin = User::create([
            'name' => 'Admin',
            'email' => 'admin@test.com',
            'password' => bcrypt('password123'),
            'role_id' => $adminRole->id,
            'status' => 'active',
        ]);
        Admin::create(['user_id' => $this->admin->id, 'position' => 'Manager']);

        $parentUser = User::create([
            'name' => 'Parent',
            'email' => 'parent@test.com',
            'password' => bcrypt('password123'),
            'role_id' => $parentRole->id,
            'status' => 'active',
        ]);
        $this->parent = ParentModel::create(['user_id' => $parentUser->id]);

        $this->child = Child::create([
            'name' => 'Budi',
            'birth_date' => '2022-01-01',
            'gender' => 'male',
            'status' => 'active',
        ]);
        $this->parent->children()->attach($this->child->id);
    }

    private function adminToken(): string
    {
        return $this->admin->createToken('admin-token')->plainTextToken;
    }

    private function makePackage(int $durationDays = 30): Package
    {
        return Package::create([
            'name' => 'Paket '.$durationDays.' Hari',
            'price' => 1000000,
            'duration_days' => $durationDays,
            'status' => 'active',
        ]);
    }

    private function assignActivePackage(Child $child, Package $package, string $startDate): ChildPackage
    {
        return ChildPackage::create([
            'child_id' => $child->id,
            'package_id' => $package->id,
            'start_date' => $startDate,
            'end_date' => Carbon::parse($startDate)->addDays($package->duration_days)->toDateString(),
            'status' => 'active',
        ]);
    }

    private function assignPackageEndingIn(Child $child, Package $package, int $daysFromToday): ChildPackage
    {
        $start = Carbon::today()->subDays($package->duration_days - $daysFromToday);

        return $this->assignActivePackage($child, $package, $start->toDateString());
    }

    // ==================== ACTIVATION STARTS PACKAGE ====================

    public function test_child_activation_sets_package_start_date_to_today(): void
    {
        $package = $this->makePackage(30);
        $this->child->update(['status' => 'inactive']);
        $this->assignActivePackage($this->child, $package, Carbon::today()->addDays(10)->toDateString());

        $this->withHeader('Authorization', 'Bearer '.$this->adminToken())
            ->putJson('/api/v1/admin/children/'.$this->child->id, ['status' => 'active'])
            ->assertOk()
            ->assertJsonPath('success', true);

        $cp = $this->child->childPackages()->first();
        $this->assertEquals(Carbon::today()->toDateString(), $cp->start_date->toDateString());
    }

    public function test_activation_end_date_is_start_plus_package_duration(): void
    {
        $package = $this->makePackage(30);
        $this->child->update(['status' => 'inactive']);
        $this->assignActivePackage($this->child, $package, Carbon::today()->addDays(10)->toDateString());

        $this->withHeader('Authorization', 'Bearer '.$this->adminToken())
            ->putJson('/api/v1/admin/children/'.$this->child->id, ['status' => 'active'])
            ->assertOk();

        $cp = $this->child->childPackages()->first();
        $this->assertEquals(
            Carbon::today()->addDays(30)->toDateString(),
            $cp->end_date->toDateString()
        );
    }

    public function test_activation_does_not_overwrite_already_running_package(): void
    {
        $package = $this->makePackage(30);
        $this->child->update(['status' => 'inactive']);
        $start = Carbon::today()->subDays(5)->toDateString();
        $this->assignActivePackage($this->child, $package, $start);

        $this->withHeader('Authorization', 'Bearer '.$this->adminToken())
            ->putJson('/api/v1/admin/children/'.$this->child->id, ['status' => 'active'])
            ->assertOk();

        $cp = $this->child->childPackages()->first();
        $this->assertEquals($start, $cp->start_date->toDateString());
    }

    public function test_activation_does_not_create_new_package_row(): void
    {
        $package = $this->makePackage(30);
        $this->child->update(['status' => 'inactive']);
        $this->assignActivePackage($this->child, $package, Carbon::today()->addDays(10)->toDateString());

        $this->withHeader('Authorization', 'Bearer '.$this->adminToken())
            ->putJson('/api/v1/admin/children/'.$this->child->id, ['status' => 'active'])
            ->assertOk();

        $this->assertDatabaseCount('child_packages', 1);
        $this->assertSame('active', $this->child->childPackages()->first()->status);
    }

    public function test_deactivating_child_never_starts_any_package(): void
    {
        $package = $this->makePackage(30);
        $this->child->update(['status' => 'inactive']);
        $this->assignActivePackage($this->child, $package, Carbon::today()->addDays(10)->toDateString());

        $this->withHeader('Authorization', 'Bearer '.$this->adminToken())
            ->putJson('/api/v1/admin/children/'.$this->child->id, ['name' => 'Budi Update'])
            ->assertOk();

        $cp = $this->child->childPackages()->first();
        $this->assertEquals(Carbon::today()->addDays(10)->toDateString(), $cp->start_date->toDateString());
    }

    // ==================== SCHEDULED AUTO-EXPIRE ====================

    public function test_expired_package_is_marked_expired_by_command(): void
    {
        $package = $this->makePackage(30);
        $this->assignActivePackage($this->child, $package, Carbon::today()->subDays(35)->toDateString());

        $this->artisan('process:child-packages')->assertSuccessful();

        $this->assertDatabaseHas('child_packages', [
            'child_id' => $this->child->id,
            'status' => 'expired',
        ]);
        $this->assertSame('expired', $this->child->childPackages()->first()->status);
    }

    public function test_package_ending_today_is_not_expired(): void
    {
        $package = $this->makePackage(30);
        $start = Carbon::today()->toDateString();
        $this->assignActivePackage($this->child, $package, $start);

        $this->artisan('process:child-packages')->assertSuccessful();

        $this->assertSame('active', $this->child->childPackages()->first()->status);
    }

    public function test_command_is_idempotent_for_expiry(): void
    {
        $package = $this->makePackage(30);
        $this->assignActivePackage($this->child, $package, Carbon::today()->subDays(35)->toDateString());

        $this->artisan('process:child-packages')->assertSuccessful();
        $this->artisan('process:child-packages')->assertSuccessful();

        $this->assertDatabaseCount('child_packages', 1);
        $this->assertSame('expired', $this->child->childPackages()->first()->status);
    }

    // ==================== H-3 REMINDER ====================

    public function test_h3_reminder_notification_created_for_parent(): void
    {
        $package = $this->makePackage(30);
        $this->assignPackageEndingIn($this->child, $package, 3);

        $this->artisan('process:child-packages')->assertSuccessful();

        $this->assertDatabaseHas('notifications', [
            'user_id' => $this->parent->user_id,
            'type' => 'package_expiring_reminder',
        ]);
        $this->assertDatabaseCount('notifications', 1);
    }

    public function test_reminder_targets_only_related_parent(): void
    {
        $parentRole = Role::firstOrCreate(['name' => 'parent'], ['description' => 'Parent']);
        $unrelated = User::create([
            'name' => 'Orang Tua Lain',
            'email' => 'other@test.com',
            'password' => bcrypt('password123'),
            'role_id' => $parentRole->id,
            'status' => 'active',
        ]);
        $unrelatedParent = ParentModel::create(['user_id' => $unrelated->id]);

        $otherChild = Child::create([
            'name' => 'Siti',
            'birth_date' => '2022-06-01',
            'gender' => 'female',
            'status' => 'active',
        ]);
        $unrelatedParent->children()->attach($otherChild->id);

        $package = $this->makePackage(30);
        $this->assignPackageEndingIn($this->child, $package, 3);
        // Unrelated parent's child has an active package too, but it is NOT
        // expiring in 3 days — so the unrelated parent must receive nothing.
        $this->assignActivePackage($otherChild, $this->makePackage(30), Carbon::today()->addDays(5)->toDateString());

        $this->artisan('process:child-packages')->assertSuccessful();

        $this->assertDatabaseHas('notifications', [
            'user_id' => $this->parent->user_id,
            'type' => 'package_expiring_reminder',
        ]);
        // Unrelated parent never receives the reminder.
        $this->assertDatabaseMissing('notifications', ['user_id' => $unrelated->id]);
    }

    public function test_h3_reminder_only_for_package_ending_in_three_days(): void
    {
        $package = $this->makePackage(30);

        $childA = Child::create(['name' => 'A', 'birth_date' => '2020-01-01', 'gender' => 'male', 'status' => 'active']);
        $this->parent->children()->attach($childA->id);
        $this->assignPackageEndingIn($childA, $package, 2);

        $childB = Child::create(['name' => 'B', 'birth_date' => '2020-01-01', 'gender' => 'male', 'status' => 'active']);
        $this->parent->children()->attach($childB->id);
        $this->assignPackageEndingIn($childB, $package, 4);

        $childC = Child::create(['name' => 'C', 'birth_date' => '2020-01-01', 'gender' => 'male', 'status' => 'active']);
        $this->parent->children()->attach($childC->id);
        $this->assignPackageEndingIn($childC, $package, 3);

        $this->artisan('process:child-packages')->assertSuccessful();

        // Only the package ending exactly 3 days from today gets a reminder.
        $this->assertDatabaseHas('notifications', [
            'user_id' => $this->parent->user_id,
            'type' => 'package_expiring_reminder',
        ]);
        $this->assertDatabaseCount('notifications', 1);

        $notif = Notification::where('user_id', $this->parent->user_id)->first();
        $this->assertEquals((string) $childC->childPackages()->first()->id, $notif->data['child_package_id']);
    }

    public function test_no_duplicate_reminder_when_command_runs_twice(): void
    {
        $package = $this->makePackage(30);
        $this->assignPackageEndingIn($this->child, $package, 3);

        $this->artisan('process:child-packages')->assertSuccessful();
        $this->artisan('process:child-packages')->assertSuccessful();

        $this->assertDatabaseCount('notifications', 1);
    }

    public function test_no_reminder_for_already_expired_package(): void
    {
        $package = $this->makePackage(30);
        $this->assignActivePackage($this->child, $package, Carbon::today()->subDays(35)->toDateString());

        $this->artisan('process:child-packages')->assertSuccessful();

        $this->assertDatabaseCount('notifications', 0);
    }

    public function test_h3_reminder_sends_fcm_to_parent_tokens(): void
    {
        FcmToken::create(['user_id' => $this->parent->user_id, 'token' => 'reminder-token', 'platform' => 'web']);

        config(['services.firebase.project_id' => 'tinycare-test']);
        config(['services.firebase.client_email' => 'test@tinycare-test.iam.gserviceaccount.com']);
        config(['services.firebase.private_key' => 'test-private-key']);

        $sent = [];
        $transport = function ($method, $url, $options) use (&$sent) {
            if (isset($options['json']['message']['token'])) {
                $sent[] = $options['json']['message']['token'];
            }

            return ['status' => 200, 'body' => '{"name":"ok"}'];
        };

        $service = new FcmNotificationService(null, $transport);
        $service->setAccessToken('test-access-token');
        $this->app->instance(FcmNotificationService::class, $service);
        FcmNotificationService::setStaticTransport($transport);

        $package = $this->makePackage(30);
        $this->assignPackageEndingIn($this->child, $package, 3);

        $this->artisan('process:child-packages')->assertSuccessful();

        $this->assertEquals(['reminder-token'], $sent);

        $notif = Notification::where('user_id', $this->parent->user_id)->first();
        $this->assertEquals('package_expiring_reminder', $notif->type);
        $this->assertEquals((string) $this->child->childPackages()->first()->id, $notif->data['child_package_id']);
        $this->assertEquals((string) $this->child->id, $notif->data['child_id']);
    }

    public function test_h3_reminder_skips_inactive_parent(): void
    {
        $this->parent->user->update(['status' => 'inactive']);

        $package = $this->makePackage(30);
        $this->assignPackageEndingIn($this->child, $package, 3);

        $this->artisan('process:child-packages')->assertSuccessful();

        $this->assertDatabaseCount('notifications', 0);
    }

    // ==================== DEVELOPMENT-FOCUSED REPORTS ====================

    private function seedWeekDevelopment(Child $child): void
    {
        $category = DevelopmentCategory::create(['name' => 'Motorik', 'status' => 'active']);

        DevelopmentAssessment::create([
            'child_id' => $child->id,
            'development_category_id' => $category->id,
            'indicator' => 'Menggambar lingkaran',
            'progress' => 'berkembang',
            'observation_date' => Carbon::today()->toDateString(),
            'assessed_by' => $this->admin->id,
        ]);
    }

    public function test_weekly_report_summary_is_development_focused_and_has_no_attendance_text(): void
    {
        $weekStart = Carbon::today()->startOfWeek()->toDateString();

        Attendance::create([
            'child_id' => $this->child->id,
            'date' => Carbon::today()->toDateString(),
            'status' => 'hadir',
            'recorded_by' => $this->admin->id,
        ]);

        $this->seedWeekDevelopment($this->child);

        $report = WeeklyReport::generateForChild($this->child, $weekStart);

        $this->assertNull($report->attendance_summary);
        $this->assertNull($report->activity_summary);
        $this->assertEquals(1, $report->total_attendance);
        $this->assertStringContainsString('Perkembangan Budi Minggu Ini', $report->overall_summary);
        $this->assertStringContainsString('Motorik', $report->overall_summary);
        $this->assertStringContainsString('Berkembang', $report->overall_summary);
        $this->assertStringNotContainsString('hadir', strtolower($report->overall_summary));
        $this->assertStringNotContainsString('Hadir', $report->overall_summary);
        $this->assertStringContainsString("\n", $report->overall_summary);
    }

    public function test_monthly_report_summary_is_development_focused(): void
    {
        $now = Carbon::today();
        Attendance::create([
            'child_id' => $this->child->id,
            'date' => Carbon::today()->toDateString(),
            'status' => 'hadir',
            'recorded_by' => $this->admin->id,
        ]);

        $this->seedWeekDevelopment($this->child);

        $report = MonthlyReport::generateForChild($this->child, $now->month, $now->year);

        $this->assertNull($report->attendance_summary);
        $this->assertNull($report->activity_summary);
        $this->assertEquals(1, $report->total_attendance);
        $this->assertStringContainsString('Motorik', $report->overall_summary);
        $this->assertStringContainsString('Berkembang', $report->overall_summary);
        $this->assertStringNotContainsString('Hadir', $report->overall_summary);
        $this->assertStringContainsString("\n", $report->overall_summary);
    }

    public function test_report_without_development_data_does_not_invent_categories(): void
    {
        $weekStart = Carbon::today()->startOfWeek()->toDateString();

        Attendance::create([
            'child_id' => $this->child->id,
            'date' => Carbon::today()->toDateString(),
            'status' => 'hadir',
            'recorded_by' => $this->admin->id,
        ]);

        $report = WeeklyReport::generateForChild($this->child, $weekStart);

        $this->assertStringContainsString('Belum ada penilaian perkembangan minggu ini.', $report->overall_summary);
        $this->assertStringContainsString("\n", $report->overall_summary);
        // No invented category names appear in the summary.
        $this->assertStringNotContainsString('Motorik', $report->overall_summary);
        $this->assertStringNotContainsString('- ', str_replace("\n", '', $report->overall_summary));
    }

    public function test_attendance_flow_still_works_end_to_end(): void
    {
        $res = $this->withHeader('Authorization', 'Bearer '.$this->adminToken())
            ->postJson('/api/v1/admin/attendance', [
                'child_id' => $this->child->id,
                'date' => Carbon::today()->toDateString(),
                'status' => 'hadir',
                'check_in_time' => '07:45',
            ]);

        $res->assertCreated();

        $this->assertDatabaseHas('attendance', [
            'child_id' => $this->child->id,
            'status' => 'hadir',
        ]);
    }
}