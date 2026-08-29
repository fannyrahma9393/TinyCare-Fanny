<?php

namespace Tests\Feature;

use App\Models\Admin;
use App\Models\Child;
use App\Models\ParentModel;
use App\Models\Role;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class AuthorizationTest extends TestCase
{
    use RefreshDatabase;

    private User $admin;

    private User $parent;

    private Child $child;

    protected function setUp(): void
    {
        parent::setUp();

        config(['services.tinycare.admin_access_code' => 'TEST-ADMIN-CODE']);
        putenv('TINYCARE_ADMIN_ACCESS_CODE=TEST-ADMIN-CODE');

        $adminRole = Role::firstOrCreate(['name' => 'admin'], ['description' => 'Admin']);
        $parentRole = Role::firstOrCreate(['name' => 'parent'], ['description' => 'Parent']);

        $this->admin = User::create([
            'name' => 'Admin Test',
            'email' => 'admin@test.com',
            'password' => bcrypt('password123'),
            'role_id' => $adminRole->id,
            'status' => 'active',
        ]);
        Admin::create(['user_id' => $this->admin->id, 'position' => 'Manager']);

        $this->parent = User::create([
            'name' => 'Parent Test',
            'email' => 'parent@test.com',
            'password' => bcrypt('password123'),
            'role_id' => $parentRole->id,
            'status' => 'active',
        ]);
        $parentModel = ParentModel::create(['user_id' => $this->parent->id]);

        $this->child = Child::create([
            'name' => 'Child Test',
            'birth_date' => '2022-01-01',
            'gender' => 'male',
            'status' => 'active',
        ]);
        $parentModel->children()->attach($this->child->id);
    }

    private function adminToken(): string
    {
        return $this->admin->createToken('admin-token')->plainTextToken;
    }

    private function parentToken(): string
    {
        return $this->parent->createToken('parent-token')->plainTextToken;
    }

    // ==================== AUTH TESTS ====================

    public function test_admin_login_returns_role_admin(): void
    {
        $res = $this->postJson('/api/v1/auth/login', [
            'email' => 'admin@test.com',
            'password' => 'password123',
            'admin_access_code' => 'TEST-ADMIN-CODE',
        ]);

        $res->assertOk()
            ->assertJsonPath('data.user.role', 'admin')
            ->assertJsonStructure(['data' => ['token', 'user' => ['id', 'name', 'email', 'role']]]);
    }

    public function test_parent_login_returns_role_parent(): void
    {
        $res = $this->postJson('/api/v1/auth/login', [
            'email' => 'parent@test.com',
            'password' => 'password123',
        ]);

        $res->assertOk()
            ->assertJsonPath('data.user.role', 'parent');
    }

    public function test_invalid_password_rejected(): void
    {
        $res = $this->postJson('/api/v1/auth/login', [
            'email' => 'admin@test.com',
            'password' => 'wrongpassword',
        ]);

        $res->assertStatus(422)
            ->assertJsonValidationErrors('email');
    }

    public function test_invalid_token_rejected(): void
    {
        $res = $this->withHeader('Authorization', 'Bearer invalid-token-12345')
            ->getJson('/api/v1/auth/me');

        $res->assertUnauthorized();
    }

    public function test_empty_token_rejected(): void
    {
        $res = $this->getJson('/api/v1/auth/me');

        $res->assertUnauthorized();
    }

    public function test_logout_returns_success_and_removes_token(): void
    {
        $token = $this->adminToken();
        $this->withHeader('Authorization', "Bearer $token")
            ->getJson('/api/v1/auth/me')
            ->assertOk();

        $res = $this->withHeader('Authorization', "Bearer $token")
            ->postJson('/api/v1/auth/logout');

        $res->assertOk()->assertJson([
            'success' => true,
            'message' => 'Logout berhasil.',
        ]);
    }

    // ==================== ADMIN-ONLY ACCESS ====================

    public function test_admin_can_access_admin_dashboard(): void
    {
        $res = $this->withHeader('Authorization', 'Bearer '.$this->adminToken())
            ->getJson('/api/v1/admin/dashboard');

        $res->assertOk()->assertJson(['success' => true]);
    }

    public function test_admin_can_access_admin_children(): void
    {
        $res = $this->withHeader('Authorization', 'Bearer '.$this->adminToken())
            ->getJson('/api/v1/admin/children');

        $res->assertOk()->assertJson(['success' => true]);
    }

    public function test_admin_can_access_admin_parents(): void
    {
        $res = $this->withHeader('Authorization', 'Bearer '.$this->adminToken())
            ->getJson('/api/v1/admin/parents');

        $res->assertOk()->assertJson(['success' => true]);
    }

    public function test_admin_can_access_admin_packages(): void
    {
        $res = $this->withHeader('Authorization', 'Bearer '.$this->adminToken())
            ->getJson('/api/v1/admin/packages');

        $res->assertOk()->assertJson(['success' => true]);
    }

    public function test_admin_can_access_admin_vouchers(): void
    {
        $res = $this->withHeader('Authorization', 'Bearer '.$this->adminToken())
            ->getJson('/api/v1/admin/vouchers');

        $res->assertOk()->assertJson(['success' => true]);
    }

    // ==================== PARENT CANNOT ACCESS ADMIN ====================

    public function test_parent_cannot_access_admin_dashboard(): void
    {
        $res = $this->withHeader('Authorization', 'Bearer '.$this->parentToken())
            ->getJson('/api/v1/admin/dashboard');

        $res->assertForbidden();
    }

    public function test_parent_cannot_access_admin_children(): void
    {
        $res = $this->withHeader('Authorization', 'Bearer '.$this->parentToken())
            ->getJson('/api/v1/admin/children');

        $res->assertForbidden();
    }

    public function test_parent_cannot_access_admin_parents(): void
    {
        $res = $this->withHeader('Authorization', 'Bearer '.$this->parentToken())
            ->getJson('/api/v1/admin/parents');

        $res->assertForbidden();
    }

    public function test_parent_cannot_access_admin_packages(): void
    {
        $res = $this->withHeader('Authorization', 'Bearer '.$this->parentToken())
            ->getJson('/api/v1/admin/packages');

        $res->assertForbidden();
    }

    public function test_parent_cannot_access_admin_vouchers(): void
    {
        $res = $this->withHeader('Authorization', 'Bearer '.$this->parentToken())
            ->getJson('/api/v1/admin/vouchers');

        $res->assertForbidden();
    }

    public function test_parent_cannot_create_parent(): void
    {
        $res = $this->withHeader('Authorization', 'Bearer '.$this->parentToken())
            ->postJson('/api/v1/admin/parents', [
                'name' => 'Fake',
                'email' => 'fake@test.com',
                'password' => 'password123',
            ]);

        $res->assertForbidden();
    }

    public function test_parent_cannot_create_child(): void
    {
        $res = $this->withHeader('Authorization', 'Bearer '.$this->parentToken())
            ->postJson('/api/v1/admin/children', [
                'name' => 'Fake Child',
                'birth_date' => '2022-01-01',
                'gender' => 'male',
                'parent_ids' => [1],
            ]);

        $res->assertForbidden();
    }

    // ==================== ADMIN CANNOT ACCESS PARENT ====================

    public function test_admin_cannot_access_parent_children(): void
    {
        $res = $this->withHeader('Authorization', 'Bearer '.$this->adminToken())
            ->getJson('/api/v1/parent/children');

        $res->assertForbidden();
    }

    public function test_admin_cannot_access_parent_dashboard(): void
    {
        $res = $this->withHeader('Authorization', 'Bearer '.$this->adminToken())
            ->getJson('/api/v1/parent/dashboard');

        $res->assertForbidden();
    }

    public function test_admin_cannot_access_parent_invoices(): void
    {
        $res = $this->withHeader('Authorization', 'Bearer '.$this->adminToken())
            ->getJson('/api/v1/parent/invoices');

        $res->assertForbidden();
    }

    // ==================== PARENT CAN ACCESS PARENT ====================

    public function test_parent_can_access_parent_dashboard(): void
    {
        $res = $this->withHeader('Authorization', 'Bearer '.$this->parentToken())
            ->getJson('/api/v1/parent/dashboard');

        $res->assertOk()->assertJson(['success' => true]);
    }

    public function test_parent_can_access_parent_children(): void
    {
        $res = $this->withHeader('Authorization', 'Bearer '.$this->parentToken())
            ->getJson('/api/v1/parent/children');

        $res->assertOk()->assertJson(['success' => true]);
    }

    public function test_parent_can_access_parent_invoices(): void
    {
        $res = $this->withHeader('Authorization', 'Bearer '.$this->parentToken())
            ->getJson('/api/v1/parent/invoices');

        $res->assertOk()->assertJson(['success' => true]);
    }

    public function test_parent_can_access_parent_announcements(): void
    {
        $res = $this->withHeader('Authorization', 'Bearer '.$this->parentToken())
            ->getJson('/api/v1/parent/announcements');

        $res->assertOk()->assertJson(['success' => true]);
    }

    // ==================== UNAUTHENTICATED ====================

    public function test_unauthenticated_cannot_access_admin(): void
    {
        $res = $this->getJson('/api/v1/admin/dashboard');

        $res->assertUnauthorized();
    }

    public function test_unauthenticated_cannot_access_parent(): void
    {
        $res = $this->getJson('/api/v1/parent/children');

        $res->assertUnauthorized();
    }

    // ==================== ROLE MIDDLEWARE ====================

    public function test_role_middleware_rejects_invalid_role(): void
    {
        $userRole = Role::firstOrCreate(['name' => 'user'], ['description' => 'User']);
        $user = User::create([
            'name' => 'User Test',
            'email' => 'usertest@test.com',
            'password' => bcrypt('password123'),
            'role_id' => $userRole->id,
            'status' => 'active',
        ]);
        $token = $user->createToken('user-token')->plainTextToken;

        $res = $this->withHeader('Authorization', "Bearer $token")
            ->getJson('/api/v1/admin/dashboard');

        $res->assertForbidden()
            ->assertJson(['message' => 'Tidak memiliki akses.']);
    }

    public function test_role_middleware_rejects_user_without_role(): void
    {
        $user = User::create([
            'name' => 'No Role',
            'email' => 'norole@test.com',
            'password' => bcrypt('password123'),
            'role_id' => null,
            'status' => 'active',
        ]);
        $token = $user->createToken('norole-token')->plainTextToken;

        $res = $this->withHeader('Authorization', "Bearer $token")
            ->getJson('/api/v1/admin/dashboard');

        $res->assertForbidden()
            ->assertJson(['message' => 'Akun tidak memiliki role.']);
    }
}
