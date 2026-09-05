<?php

namespace Tests\Feature;

use App\Models\Role;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class AuthTest extends TestCase
{
    use RefreshDatabase;

    private function createAdmin(): User
    {
        $role = Role::firstOrCreate(['name' => 'admin'], ['description' => 'Admin']);

        return User::create([
            'name' => 'Admin Test',
            'email' => 'admin@test.com',
            'password' => bcrypt('password123'),
            'role_id' => $role->id,
            'status' => 'active',
        ]);
    }

    private function createParent(): User
    {
        $role = Role::firstOrCreate(['name' => 'parent'], ['description' => 'Parent']);

        return User::create([
            'name' => 'Parent Test',
            'email' => 'parent@test.com',
            'password' => bcrypt('password123'),
            'role_id' => $role->id,
            'status' => 'active',
        ]);
    }

    // ==================== PARENT LOGIN TESTS ====================

    public function test_parent_login_without_admin_code_success(): void
    {
        $this->createParent();

        $response = $this->postJson('/api/v1/auth/login', [
            'email' => 'parent@test.com',
            'password' => 'password123',
        ]);

        $response->assertOk()
            ->assertJson([
                'success' => true,
                'data' => [
                    'user' => ['role' => 'parent'],
                ],
            ])
            ->assertJsonStructure(['data' => ['token', 'user']]);
    }

    public function test_parent_login_with_admin_code_still_success(): void
    {
        $this->createParent();

        $response = $this->postJson('/api/v1/auth/login', [
            'email' => 'parent@test.com',
            'password' => 'password123',
            'admin_access_code' => 'some-random-code',
        ]);

        $response->assertOk()
            ->assertJson([
                'success' => true,
                'data' => [
                    'user' => ['role' => 'parent'],
                ],
            ]);
    }

    // ==================== ADMIN LOGIN TESTS ====================

    public function test_admin_login_success(): void
    {
        $this->createAdmin();

        $response = $this->postJson('/api/v1/auth/login', [
            'email' => 'admin@test.com',
            'password' => 'password123',
        ]);

        $response->assertOk()
            ->assertJson([
                'success' => true,
                'data' => [
                    'user' => ['role' => 'admin'],
                ],
            ])
            ->assertJsonStructure(['data' => ['token', 'user']]);
    }

    public function test_admin_login_without_admin_code_success(): void
    {
        $this->createAdmin();

        $response = $this->postJson('/api/v1/auth/login', [
            'email' => 'admin@test.com',
            'password' => 'password123',
        ]);

        $response->assertOk()
            ->assertJson([
                'success' => true,
                'data' => [
                    'user' => ['role' => 'admin'],
                ],
            ]);
    }

    public function test_admin_login_ignores_access_code(): void
    {
        $this->createAdmin();

        $response = $this->postJson('/api/v1/auth/login', [
            'email' => 'admin@test.com',
            'password' => 'password123',
            'admin_access_code' => 'any-code-ignored',
        ]);

        $response->assertOk()
            ->assertJson([
                'success' => true,
                'data' => [
                    'user' => ['role' => 'admin'],
                ],
            ]);
    }

    public function test_admin_master_login_success(): void
    {
        $role = Role::firstOrCreate(['name' => 'admin_master'], ['description' => 'Admin Master']);
        User::create([
            'name' => 'Admin Master Test',
            'email' => 'master@test.com',
            'password' => bcrypt('password123'),
            'role_id' => $role->id,
            'status' => 'active',
        ]);

        $response = $this->postJson('/api/v1/auth/login', [
            'email' => 'master@test.com',
            'password' => 'password123',
        ]);

        $response->assertOk()
            ->assertJson([
                'success' => true,
                'data' => [
                    'user' => ['role' => 'admin_master'],
                ],
            ]);
    }

    public function test_role_comes_from_backend_not_frontend(): void
    {
        $this->createAdmin();

        $response = $this->postJson('/api/v1/auth/login', [
            'email' => 'admin@test.com',
            'password' => 'password123',
            'role' => 'parent',
        ]);

        $response->assertOk()
            ->assertJsonPath('data.user.role', 'admin');
    }

    // ==================== CREDENTIAL VALIDATION TESTS ====================

    public function test_invalid_credentials_rejected(): void
    {
        $this->createAdmin();

        $response = $this->postJson('/api/v1/auth/login', [
            'email' => 'admin@test.com',
            'password' => 'wrongpassword',
        ]);

        $response->assertUnprocessable()
            ->assertJsonValidationErrors('email');
    }

    public function test_unknown_email_rejected(): void
    {
        $response = $this->postJson('/api/v1/auth/login', [
            'email' => 'nonexistent@test.com',
            'password' => 'password123',
        ]);

        $response->assertUnprocessable()
            ->assertJsonValidationErrors('email');
    }

    public function test_missing_email_rejected(): void
    {
        $response = $this->postJson('/api/v1/auth/login', [
            'password' => 'password123',
        ]);

        $response->assertUnprocessable()
            ->assertJsonValidationErrors('email');
    }

    public function test_missing_password_rejected(): void
    {
        $response = $this->postJson('/api/v1/auth/login', [
            'email' => 'admin@test.com',
        ]);

        $response->assertUnprocessable()
            ->assertJsonValidationErrors('password');
    }

    // ==================== ME ENDPOINT TESTS ====================

    public function test_authenticated_user_can_access_me(): void
    {
        $user = $this->createAdmin();
        $token = $user->createToken('test-token')->plainTextToken;

        $response = $this->withHeader('Authorization', "Bearer $token")
            ->getJson('/api/v1/auth/me');

        $response->assertOk()
            ->assertJson([
                'success' => true,
                'data' => [
                    'email' => 'admin@test.com',
                    'role' => 'admin',
                ],
            ]);
    }

    public function test_me_returns_correct_role_for_parent(): void
    {
        $user = $this->createParent();
        $token = $user->createToken('test-token')->plainTextToken;

        $response = $this->withHeader('Authorization', "Bearer $token")
            ->getJson('/api/v1/auth/me');

        $response->assertOk()
            ->assertJsonPath('data.role', 'parent');
    }

    public function test_unauthenticated_user_cannot_access_me(): void
    {
        $response = $this->getJson('/api/v1/auth/me');

        $response->assertUnauthorized();
    }

    // ==================== LOGOUT TESTS ====================

    public function test_authenticated_user_can_logout(): void
    {
        $user = $this->createAdmin();
        $token = $user->createToken('test-token')->plainTextToken;

        $response = $this->withHeader('Authorization', "Bearer $token")
            ->postJson('/api/v1/auth/logout');

        $response->assertOk()
            ->assertJson(['success' => true]);
    }

    // ==================== INACTIVE USER TEST ====================

    public function test_inactive_user_cannot_login(): void
    {
        $role = Role::firstOrCreate(['name' => 'admin'], ['description' => 'Admin']);
        User::create([
            'name' => 'Inactive User',
            'email' => 'inactive@test.com',
            'password' => bcrypt('password123'),
            'role_id' => $role->id,
            'status' => 'inactive',
        ]);

        $response = $this->postJson('/api/v1/auth/login', [
            'email' => 'inactive@test.com',
            'password' => 'password123',
        ]);

        $response->assertUnprocessable()
            ->assertJsonValidationErrors('email');
    }
}
