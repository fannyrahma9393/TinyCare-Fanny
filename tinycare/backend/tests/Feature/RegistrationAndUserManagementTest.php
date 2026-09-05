<?php

namespace Tests\Feature;

use App\Models\Admin;
use App\Models\Child;
use App\Models\Invoice;
use App\Models\Package;
use App\Models\ParentModel;
use App\Models\Payment;
use App\Models\Role;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Hash;
use Tests\TestCase;

class RegistrationAndUserManagementTest extends TestCase
{
    use RefreshDatabase;

    private User $adminMaster;

    private User $admin;

    private User $parent;

    private string $accessCode;

    protected function setUp(): void
    {
        parent::setUp();

        // Create roles
        Role::firstOrCreate(['name' => 'parent'], ['description' => 'Parent']);
        Role::firstOrCreate(['name' => 'admin'], ['description' => 'Admin']);
        Role::firstOrCreate(['name' => 'admin_master'], ['description' => 'Admin Master']);

        // Create admin_master
        $this->adminMaster = User::create([
            'name' => 'Admin Master',
            'email' => 'master@tinycare.com',
            'password' => Hash::make('password123'),
            'role_id' => Role::where('name', 'admin_master')->first()->id,
            'status' => 'active',
        ]);
        Admin::create(['user_id' => $this->adminMaster->id]);

        // Create regular admin
        $this->admin = User::create([
            'name' => 'Regular Admin',
            'email' => 'admin@tinycare.com',
            'password' => Hash::make('password123'),
            'role_id' => Role::where('name', 'admin')->first()->id,
            'status' => 'active',
        ]);
        Admin::create(['user_id' => $this->admin->id]);

        // Create active parent
        $this->parent = User::create([
            'name' => 'Parent User',
            'email' => 'parent@tinycare.com',
            'password' => Hash::make('password123'),
            'role_id' => Role::where('name', 'parent')->first()->id,
            'status' => 'active',
        ]);
        ParentModel::create(['user_id' => $this->parent->id]);
    }

    // ==================== PARENT REGISTRATION ====================

    public function test_parent_registration_succeeds(): void
    {
        $response = $this->postJson('/api/v1/auth/register-parent', [
            'name' => 'New Parent',
            'email' => 'newparent@test.com',
            'password' => 'password123',
            'password_confirmation' => 'password123',
            'phone' => '081234567890',
        ]);

        $response->assertStatus(201)
            ->assertJson([
                'success' => true,
                'message' => 'Registrasi berhasil. Akun Anda akan segera diverifikasi oleh admin.',
            ]);

        // Verify user is created with pending status
        $user = User::where('email', 'newparent@test.com')->first();
        $this->assertNotNull($user);
        $this->assertEquals('pending', $user->status);
        $this->assertEquals('parent', $user->role->name);
    }

    public function test_duplicate_email_rejected(): void
    {
        $response = $this->postJson('/api/v1/auth/register-parent', [
            'name' => 'Duplicate Parent',
            'email' => 'parent@tinycare.com',
            'password' => 'password123',
            'password_confirmation' => 'password123',
        ]);

        $response->assertStatus(422)
            ->assertJsonValidationErrors(['email']);
    }

    public function test_pending_parent_cannot_login(): void
    {
        User::create([
            'name' => 'Pending Parent',
            'email' => 'pending@test.com',
            'password' => Hash::make('password123'),
            'role_id' => Role::where('name', 'parent')->first()->id,
            'status' => 'pending',
        ]);

        $response = $this->postJson('/api/v1/auth/login', [
            'email' => 'pending@test.com',
            'password' => 'password123',
        ]);

        // Pending parent should be rejected (422 ValidationException)
        $response->assertStatus(422);
        $response->assertJsonFragment(['email' => ['Akun Anda masih menunggu persetujuan admin.']]);
    }

    public function test_rejected_parent_cannot_login(): void
    {
        User::create([
            'name' => 'Rejected Parent',
            'email' => 'rejected@test.com',
            'password' => Hash::make('password123'),
            'role_id' => Role::where('name', 'parent')->first()->id,
            'status' => 'rejected',
        ]);

        $response = $this->postJson('/api/v1/auth/login', [
            'email' => 'rejected@test.com',
            'password' => 'password123',
        ]);

        // Rejected parent should be rejected
        $response->assertStatus(422);
        $response->assertJsonFragment(['email' => ['Akun Anda telah ditolak. Silakan hubungi admin.']]);
    }

    public function test_approved_parent_can_login(): void
    {
        $response = $this->postJson('/api/v1/auth/login', [
            'email' => 'parent@tinycare.com',
            'password' => 'password123',
        ]);

        $response->assertStatus(200)
            ->assertJson([
                'success' => true,
                'data' => [
                    'user' => [
                        'role' => 'parent',
                        'status' => 'active',
                    ],
                ],
            ]);
    }

    // ==================== USER MANAGEMENT ====================

    public function test_admin_can_list_users(): void
    {
        $token = $this->admin->createToken('test-token')->plainTextToken;

        $response = $this->getJson('/api/v1/admin/users', [
            'Authorization' => "Bearer $token",
        ]);

        $response->assertStatus(200)
            ->assertJson([
                'success' => true,
            ]);
    }

    public function test_parent_cannot_access_admin_endpoints(): void
    {
        $token = $this->parent->createToken('test-token')->plainTextToken;

        $response = $this->getJson('/api/v1/admin/users', [
            'Authorization' => "Bearer $token",
        ]);

        $response->assertStatus(403);
    }

    public function test_admin_can_see_pending_parents(): void
    {
        // Create pending parent
        User::create([
            'name' => 'Pending Parent',
            'email' => 'pending2@test.com',
            'password' => Hash::make('password123'),
            'role_id' => Role::where('name', 'parent')->first()->id,
            'status' => 'pending',
        ]);

        $token = $this->admin->createToken('test-token')->plainTextToken;

        $response = $this->getJson('/api/v1/admin/users/pending', [
            'Authorization' => "Bearer $token",
        ]);

        $response->assertStatus(200)
            ->assertJson([
                'success' => true,
            ]);

        $this->assertGreaterThan(0, $response->json('data.data'));
    }

    public function test_admin_can_approve_parent(): void
    {
        $pendingParent = User::create([
            'name' => 'Approve Test',
            'email' => 'approve@test.com',
            'password' => Hash::make('password123'),
            'role_id' => Role::where('name', 'parent')->first()->id,
            'status' => 'pending',
        ]);
        ParentModel::create(['user_id' => $pendingParent->id]);

        $token = $this->admin->createToken('test-token')->plainTextToken;

        $response = $this->postJson("/api/v1/admin/users/{$pendingParent->id}/approve", [], [
            'Authorization' => "Bearer $token",
        ]);

        $response->assertStatus(200)
            ->assertJson([
                'success' => true,
                'message' => 'Akun parent berhasil disetujui.',
            ]);

        $pendingParent->refresh();
        $this->assertEquals('active', $pendingParent->status);
    }

    public function test_admin_can_reject_parent(): void
    {
        $pendingParent = User::create([
            'name' => 'Reject Test',
            'email' => 'reject@test.com',
            'password' => Hash::make('password123'),
            'role_id' => Role::where('name', 'parent')->first()->id,
            'status' => 'pending',
        ]);

        $token = $this->admin->createToken('test-token')->plainTextToken;

        $response = $this->postJson("/api/v1/admin/users/{$pendingParent->id}/reject", [
            'reason' => 'Data tidak lengkap',
        ], [
            'Authorization' => "Bearer $token",
        ]);

        $response->assertStatus(200)
            ->assertJson([
                'success' => true,
            ]);

        $pendingParent->refresh();
        $this->assertEquals('rejected', $pendingParent->status);
    }

    // ==================== ADMIN MANAGEMENT ====================

    public function test_admin_master_can_create_admin(): void
    {
        $token = $this->adminMaster->createToken('test-token')->plainTextToken;

        $response = $this->postJson('/api/v1/admin/admins', [
            'name' => 'New Admin',
            'email' => 'newadmin@test.com',
            'password' => 'password123',
            'position' => 'Staff',
        ], [
            'Authorization' => "Bearer $token",
        ]);

        $response->assertStatus(201)
            ->assertJson([
                'success' => true,
                'message' => 'Admin berhasil ditambahkan.',
            ]);

        $newAdmin = User::where('email', 'newadmin@test.com')->first();
        $this->assertNotNull($newAdmin);
        $this->assertEquals('admin', $newAdmin->role->name);
    }

    public function test_regular_admin_cannot_create_admin(): void
    {
        $token = $this->admin->createToken('test-token')->plainTextToken;

        $response = $this->postJson('/api/v1/admin/admins', [
            'name' => 'Should Fail',
            'email' => 'shouldfail@test.com',
            'password' => 'password123',
        ], [
            'Authorization' => "Bearer $token",
        ]);

        // AdminPolicy::create requires admin_master, so regular admin gets 403
        $response->assertStatus(403);
    }

    public function test_admin_master_can_list_admins(): void
    {
        $token = $this->adminMaster->createToken('test-token')->plainTextToken;

        $response = $this->getJson('/api/v1/admin/admins', [
            'Authorization' => "Bearer $token",
        ]);

        $response->assertStatus(200)
            ->assertJson([
                'success' => true,
            ]);
    }

    public function test_admin_master_can_activate_admin(): void
    {
        // Deactivate admin first
        $this->admin->update(['status' => 'inactive']);

        $token = $this->adminMaster->createToken('test-token')->plainTextToken;
        $adminProfile = Admin::where('user_id', $this->admin->id)->first();

        $response = $this->postJson("/api/v1/admin/admins/{$adminProfile->id}/activate", [], [
            'Authorization' => "Bearer $token",
        ]);

        $response->assertStatus(200);

        $this->admin->refresh();
        $this->assertEquals('active', $this->admin->status);
    }

    public function test_admin_master_can_deactivate_admin(): void
    {
        $token = $this->adminMaster->createToken('test-token')->plainTextToken;
        $adminProfile = Admin::where('user_id', $this->admin->id)->first();

        $response = $this->postJson("/api/v1/admin/admins/{$adminProfile->id}/deactivate", [], [
            'Authorization' => "Bearer $token",
        ]);

        $response->assertStatus(200);

        $this->admin->refresh();
        $this->assertEquals('inactive', $this->admin->status);
    }

    public function test_admin_master_cannot_deactivate_self(): void
    {
        $token = $this->adminMaster->createToken('test-token')->plainTextToken;
        $adminProfile = Admin::where('user_id', $this->adminMaster->id)->first();

        $response = $this->postJson("/api/v1/admin/admins/{$adminProfile->id}/deactivate", [], [
            'Authorization' => "Bearer $token",
        ]);

        $response->assertStatus(400)
            ->assertJson([
                'success' => false,
                'message' => 'Tidak dapat menonaktifkan akun sendiri.',
            ]);

        $this->adminMaster->refresh();
        $this->assertEquals('active', $this->adminMaster->status);
    }

    public function test_regular_admin_cannot_activate_admin(): void
    {
        $token = $this->admin->createToken('test-token')->plainTextToken;
        $adminProfile = Admin::where('user_id', $this->adminMaster->id)->first();

        $response = $this->postJson("/api/v1/admin/admins/{$adminProfile->id}/activate", [], [
            'Authorization' => "Bearer $token",
        ]);

        $response->assertStatus(403);
    }

    public function test_regular_admin_cannot_deactivate_admin(): void
    {
        $token = $this->admin->createToken('test-token')->plainTextToken;
        $adminProfile = Admin::where('user_id', $this->adminMaster->id)->first();

        $response = $this->postJson("/api/v1/admin/admins/{$adminProfile->id}/deactivate", [], [
            'Authorization' => "Bearer $token",
        ]);

        $response->assertStatus(403);
    }

    // ==================== LOGIN ROLE TESTS ====================

    public function test_parent_login_without_access_code(): void
    {
        $response = $this->postJson('/api/v1/auth/login', [
            'email' => 'parent@tinycare.com',
            'password' => 'password123',
        ]);

        $response->assertStatus(200)
            ->assertJson([
                'success' => true,
                'data' => [
                    'user' => [
                        'role' => 'parent',
                    ],
                ],
            ]);
    }

    public function test_admin_login_without_access_code_succeeds(): void
    {
        $response = $this->postJson('/api/v1/auth/login', [
            'email' => 'admin@tinycare.com',
            'password' => 'password123',
        ]);

        $response->assertStatus(200)
            ->assertJson([
                'success' => true,
                'data' => [
                    'user' => [
                        'role' => 'admin',
                    ],
                ],
            ]);
    }

    public function test_admin_login_ignores_access_code(): void
    {
        $response = $this->postJson('/api/v1/auth/login', [
            'email' => 'admin@tinycare.com',
            'password' => 'password123',
            'admin_access_code' => 'WRONG-CODE',
        ]);

        $response->assertStatus(200)
            ->assertJson([
                'success' => true,
                'data' => [
                    'user' => [
                        'role' => 'admin',
                    ],
                ],
            ]);
    }

    public function test_admin_login_with_email_password_only(): void
    {
        $response = $this->postJson('/api/v1/auth/login', [
            'email' => 'admin@tinycare.com',
            'password' => 'password123',
        ]);

        $response->assertStatus(200)
            ->assertJson([
                'success' => true,
                'data' => [
                    'user' => [
                        'role' => 'admin',
                    ],
                ],
            ]);
    }

    public function test_admin_master_login_succeeds(): void
    {
        $response = $this->postJson('/api/v1/auth/login', [
            'email' => 'master@tinycare.com',
            'password' => 'password123',
        ]);

        $response->assertStatus(200)
            ->assertJson([
                'success' => true,
                'data' => [
                    'user' => [
                        'role' => 'admin_master',
                    ],
                ],
            ]);
    }

    // ==================== PAYMENT PARSING TESTS ====================

    public function test_invoice_model_handles_string_amounts(): void
    {
        // Create required foreign key data
        $child = Child::create([
            'name' => 'Test Child',
            'birth_date' => '2020-01-01',
            'gender' => 'male',
        ]);
        // Link child to parent
        $this->parent->parent->children()->attach($child->id);

        $package = Package::create([
            'name' => 'Test Package',
            'price' => 800000,
            'description' => 'Test',
            'duration_days' => 30,
        ]);

        // The Invoice model uses 'decimal:2' cast which handles string-to-decimal
        $invoice = Invoice::create([
            'invoice_number' => 'INV-TEST-001',
            'child_id' => $child->id,
            'package_id' => $package->id,
            'parent_id' => $this->parent->parent->id,
            'subtotal' => '800000.00',
            'discount' => '0.00',
            'total' => '800000.00',
            'due_date' => now()->addDays(30),
            'status' => 'pending',
        ]);

        $this->assertEquals('800000.00', $invoice->fresh()->subtotal);
        $this->assertEquals('800000.00', $invoice->fresh()->total);
    }

    public function test_payment_model_handles_string_amounts(): void
    {
        // Create required foreign key data
        $child = Child::create([
            'name' => 'Test Child 2',
            'birth_date' => '2020-01-01',
            'gender' => 'female',
        ]);
        $this->parent->parent->children()->attach($child->id);

        $package = Package::create([
            'name' => 'Test Package 2',
            'price' => 500000,
            'description' => 'Test',
            'duration_days' => 30,
        ]);

        $invoice = Invoice::create([
            'invoice_number' => 'INV-TEST-002',
            'child_id' => $child->id,
            'package_id' => $package->id,
            'parent_id' => $this->parent->parent->id,
            'subtotal' => 500000,
            'discount' => 0,
            'total' => 500000,
            'due_date' => now()->addDays(30),
            'status' => 'pending',
        ]);

        $payment = Payment::create([
            'invoice_id' => $invoice->id,
            'amount' => '500000.00',
            'status' => 'pending',
            'payment_method' => 'bank_transfer',
        ]);

        $this->assertEquals('500000.00', $payment->fresh()->amount);
    }
}
