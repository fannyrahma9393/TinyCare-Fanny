<?php

namespace Tests\Feature;

use App\Models\Admin;
use App\Models\Package;
use App\Models\ParentModel;
use App\Models\Role;
use App\Models\User;
use App\Models\Voucher;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class PackageVoucherTest extends TestCase
{
    use RefreshDatabase;

    private User $admin;

    protected function setUp(): void
    {
        parent::setUp();

        config(['services.tinycare.admin_access_code' => 'TEST-ADMIN-CODE']);

        $adminRole = Role::firstOrCreate(['name' => 'admin'], ['description' => 'Admin']);
        $this->admin = User::create([
            'name' => 'Admin',
            'email' => 'admin@test.com',
            'password' => bcrypt('password123'),
            'role_id' => $adminRole->id,
            'status' => 'active',
        ]);
        Admin::create(['user_id' => $this->admin->id, 'position' => 'Manager']);
    }

    private function adminToken(): string
    {
        return $this->admin->createToken('admin-token')->plainTextToken;
    }

    // ==================== PACKAGE TESTS ====================

    public function test_admin_can_create_package(): void
    {
        $response = $this->withHeader('Authorization', 'Bearer '.$this->adminToken())
            ->postJson('/api/v1/admin/packages', [
                'name' => 'Paket Bulanan',
                'description' => 'Paket bulanan lengkap',
                'price' => 1500000,
                'duration_days' => 30,
                'facilities' => 'AC, CCTV, Daily Report',
            ]);

        $response->assertCreated()
            ->assertJson(['success' => true, 'message' => 'Paket berhasil ditambahkan.']);

        $this->assertDatabaseHas('packages', ['name' => 'Paket Bulanan', 'price' => 1500000]);
    }

    public function test_admin_can_list_packages(): void
    {
        Package::create(['name' => 'Basic', 'price' => 500000, 'duration_days' => 30]);

        $response = $this->withHeader('Authorization', 'Bearer '.$this->adminToken())
            ->getJson('/api/v1/admin/packages');

        $response->assertOk()
            ->assertJson(['success' => true]);
    }

    public function test_admin_can_update_package(): void
    {
        $package = Package::create(['name' => 'Old Name', 'price' => 500000, 'duration_days' => 30]);

        $response = $this->withHeader('Authorization', 'Bearer '.$this->adminToken())
            ->putJson('/api/v1/admin/packages/'.$package->id, [
                'name' => 'New Name',
                'price' => 600000,
            ]);

        $response->assertOk()->assertJson(['success' => true]);
        $this->assertDatabaseHas('packages', ['id' => $package->id, 'name' => 'New Name', 'price' => 600000]);
    }

    public function test_admin_can_delete_package(): void
    {
        $package = Package::create(['name' => 'Deletable', 'price' => 500000, 'duration_days' => 30]);

        $response = $this->withHeader('Authorization', 'Bearer '.$this->adminToken())
            ->deleteJson('/api/v1/admin/packages/'.$package->id);

        $response->assertOk()->assertJson(['success' => true]);
        $this->assertDatabaseMissing('packages', ['id' => $package->id]);
    }

    public function test_package_search_works(): void
    {
        Package::create(['name' => 'Paket Premium', 'price' => 2000000, 'duration_days' => 30]);
        Package::create(['name' => 'Paket Basic', 'price' => 500000, 'duration_days' => 30]);

        $response = $this->withHeader('Authorization', 'Bearer '.$this->adminToken())
            ->getJson('/api/v1/admin/packages?search=Premium');

        $response->assertOk();
        $data = $response->json('data.data');
        $this->assertCount(1, $data);
        $this->assertEquals('Paket Premium', $data[0]['name']);
    }

    public function test_package_price_is_numeric(): void
    {
        $response = $this->withHeader('Authorization', 'Bearer '.$this->adminToken())
            ->postJson('/api/v1/admin/packages', [
                'name' => 'Test',
                'price' => 'not_a_number',
                'duration_days' => 30,
            ]);

        $response->assertUnprocessable()
            ->assertJsonValidationErrors('price');
    }

    public function test_package_requires_name(): void
    {
        $response = $this->withHeader('Authorization', 'Bearer '.$this->adminToken())
            ->postJson('/api/v1/admin/packages', [
                'price' => 500000,
                'duration_days' => 30,
            ]);

        $response->assertUnprocessable()
            ->assertJsonValidationErrors('name');
    }

    // ==================== VOUCHER TESTS ====================

    public function test_admin_can_create_voucher_percentage(): void
    {
        $response = $this->withHeader('Authorization', 'Bearer '.$this->adminToken())
            ->postJson('/api/v1/admin/vouchers', [
                'code' => 'TEST20',
                'description' => 'Diskon 20%',
                'discount_type' => 'percentage',
                'discount_value' => 20,
                'max_usage' => 10,
                'start_date' => now()->toDateString(),
                'end_date' => now()->addMonth()->toDateString(),
            ]);

        $response->assertCreated()
            ->assertJson(['success' => true]);

        $this->assertDatabaseHas('vouchers', ['code' => 'TEST20', 'discount_type' => 'percentage']);
    }

    public function test_admin_can_create_voucher_nominal(): void
    {
        $response = $this->withHeader('Authorization', 'Bearer '.$this->adminToken())
            ->postJson('/api/v1/admin/vouchers', [
                'code' => 'HEMAT50K',
                'description' => 'Diskon Rp 50.000',
                'discount_type' => 'nominal',
                'discount_value' => 50000,
                'max_usage' => 5,
                'start_date' => now()->toDateString(),
                'end_date' => now()->addMonth()->toDateString(),
            ]);

        $response->assertCreated();
        $this->assertDatabaseHas('vouchers', ['code' => 'HEMAT50K', 'discount_type' => 'nominal']);
    }

    public function test_percentage_over_100_rejected(): void
    {
        $response = $this->withHeader('Authorization', 'Bearer '.$this->adminToken())
            ->postJson('/api/v1/admin/vouchers', [
                'code' => 'OVER100',
                'discount_type' => 'percentage',
                'discount_value' => 150,
                'max_usage' => 10,
                'start_date' => now()->toDateString(),
                'end_date' => now()->addMonth()->toDateString(),
            ]);

        $response->assertStatus(422)
            ->assertJson(['success' => false, 'message' => 'Persentase diskon maksimal 100%.']);
    }

    public function test_duplicate_voucher_code_rejected(): void
    {
        Voucher::create([
            'code' => 'UNIQUE1',
            'discount_type' => 'percentage',
            'discount_value' => 10,
            'max_usage' => 1,
            'start_date' => now(),
            'end_date' => now()->addMonth(),
        ]);

        $response = $this->withHeader('Authorization', 'Bearer '.$this->adminToken())
            ->postJson('/api/v1/admin/vouchers', [
                'code' => 'UNIQUE1',
                'discount_type' => 'percentage',
                'discount_value' => 20,
                'max_usage' => 5,
                'start_date' => now()->toDateString(),
                'end_date' => now()->addMonth()->toDateString(),
            ]);

        $response->assertUnprocessable()
            ->assertJsonValidationErrors('code');
    }

    public function test_voucher_code_is_uppercased(): void
    {
        $response = $this->withHeader('Authorization', 'Bearer '.$this->adminToken())
            ->postJson('/api/v1/admin/vouchers', [
                'code' => 'lowercase',
                'discount_type' => 'percentage',
                'discount_value' => 10,
                'max_usage' => 1,
                'start_date' => now()->toDateString(),
                'end_date' => now()->addMonth()->toDateString(),
            ]);

        $response->assertCreated();
        $this->assertDatabaseHas('vouchers', ['code' => 'LOWERCASE']);
    }

    public function test_expired_voucher_cannot_be_used(): void
    {
        $voucher = Voucher::create([
            'code' => 'EXPIRED',
            'discount_type' => 'percentage',
            'discount_value' => 10,
            'max_usage' => 10,
            'start_date' => now()->subMonths(2),
            'end_date' => now()->subMonth(),
        ]);

        $this->assertTrue($voucher->isExpired());
        $this->assertFalse($voucher->canBeUsed(100000));
    }

    public function test_inactive_voucher_cannot_be_used(): void
    {
        $voucher = Voucher::create([
            'code' => 'INACTIVE',
            'discount_type' => 'percentage',
            'discount_value' => 10,
            'max_usage' => 10,
            'status' => 'inactive',
            'start_date' => now(),
            'end_date' => now()->addMonth(),
        ]);

        $this->assertFalse($voucher->canBeUsed(100000));
    }

    public function test_voucher_usage_limit_respected(): void
    {
        $voucher = Voucher::create([
            'code' => 'FULLUSE',
            'discount_type' => 'percentage',
            'discount_value' => 10,
            'max_usage' => 1,
            'current_usage' => 1,
            'start_date' => now(),
            'end_date' => now()->addMonth(),
        ]);

        $this->assertFalse($voucher->canBeUsed(100000));
    }

    public function test_percentage_discount_calculation(): void
    {
        $voucher = Voucher::create([
            'code' => 'CALC20',
            'discount_type' => 'percentage',
            'discount_value' => 20,
            'max_usage' => 10,
            'start_date' => now(),
            'end_date' => now()->addMonth(),
        ]);

        $discount = $voucher->calculateDiscount(1000000);
        $this->assertEquals(200000, $discount);
    }

    public function test_nominal_discount_calculation(): void
    {
        $voucher = Voucher::create([
            'code' => 'CALC50K',
            'discount_type' => 'nominal',
            'discount_value' => 50000,
            'max_usage' => 10,
            'start_date' => now(),
            'end_date' => now()->addMonth(),
        ]);

        $discount = $voucher->calculateDiscount(1000000);
        $this->assertEquals(50000, $discount);
    }

    public function test_nominal_discount_not_exceed_amount(): void
    {
        $voucher = Voucher::create([
            'code' => 'BIGFIX',
            'discount_type' => 'nominal',
            'discount_value' => 100000,
            'max_usage' => 10,
            'start_date' => now(),
            'end_date' => now()->addMonth(),
        ]);

        $discount = $voucher->calculateDiscount(50000);
        $this->assertEquals(50000, $discount); // capped at amount
    }

    public function test_voucher_min_transaction_validation(): void
    {
        $voucher = Voucher::create([
            'code' => 'MIN200K',
            'discount_type' => 'percentage',
            'discount_value' => 10,
            'min_transaction' => 200000,
            'max_usage' => 10,
            'start_date' => now(),
            'end_date' => now()->addMonth(),
        ]);

        $this->assertFalse($voucher->canBeUsed(100000)); // below min
        $this->assertTrue($voucher->canBeUsed(300000));  // above min
    }

    // ==================== INTEGRATION TESTS ====================

    public function test_apply_voucher_returns_discount_info(): void
    {
        $parentRole = Role::firstOrCreate(['name' => 'parent'], ['description' => 'Parent']);
        $parentUser = User::create([
            'name' => 'Parent Voucher Test',
            'email' => 'pvoucher@test.com',
            'password' => bcrypt('password123'),
            'role_id' => $parentRole->id,
            'status' => 'active',
        ]);
        ParentModel::create(['user_id' => $parentUser->id]);

        $token = $parentUser->createToken('ptoken')->plainTextToken;

        Voucher::create([
            'code' => 'APPLY20',
            'discount_type' => 'percentage',
            'discount_value' => 20,
            'max_usage' => 10,
            'start_date' => now(),
            'end_date' => now()->addMonth(),
        ]);

        $response = $this->withHeader('Authorization', "Bearer $token")
            ->postJson('/api/v1/parent/vouchers/apply', [
                'code' => 'APPLY20',
                'amount' => 1500000,
            ]);

        $response->assertOk()
            ->assertJson([
                'success' => true,
                'data' => [
                    'discount_type' => 'percentage',
                    'discount_value' => 20,
                    'discount_amount' => 300000,
                    'original_amount' => 1500000,
                    'final_amount' => 1200000,
                ],
            ]);
    }
}
