<?php

namespace Tests\Feature;

use App\Models\Admin;
use App\Models\Child;
use App\Models\ParentModel;
use App\Models\Role;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class ParentManagementTest extends TestCase
{
    use RefreshDatabase;

    private User $admin;

    private User $parent;

    protected function setUp(): void
    {
        parent::setUp();

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
        ParentModel::create(['user_id' => $this->parent->id, 'phone' => '08123456']);
    }

    private function adminToken(): string
    {
        return $this->admin->createToken('admin-token')->plainTextToken;
    }

    private function parentToken(): string
    {
        return $this->parent->createToken('parent-token')->plainTextToken;
    }

    // --- Admin can create parent ---
    public function test_admin_can_create_parent(): void
    {
        $response = $this->withHeader('Authorization', 'Bearer '.$this->adminToken())
            ->postJson('/api/v1/admin/parents', [
                'name' => 'New Parent',
                'email' => 'new@test.com',
                'password' => 'password123',
            ]);

        $response->assertCreated()
            ->assertJson([
                'success' => true,
                'message' => 'Orang tua berhasil ditambahkan.',
            ]);

        $this->assertDatabaseHas('users', ['email' => 'new@test.com']);
        $this->assertDatabaseHas('parents', ['user_id' => User::where('email', 'new@test.com')->first()->id]);
    }

    // --- Parent cannot create parent ---
    public function test_parent_cannot_create_parent(): void
    {
        $response = $this->withHeader('Authorization', 'Bearer '.$this->parentToken())
            ->postJson('/api/v1/admin/parents', [
                'name' => 'Fake Parent',
                'email' => 'fake@test.com',
                'password' => 'password123',
            ]);

        $response->assertForbidden();
    }

    // --- Unauthenticated cannot create parent ---
    public function test_unauthenticated_cannot_create_parent(): void
    {
        $response = $this->postJson('/api/v1/admin/parents', [
            'name' => 'Fake Parent',
            'email' => 'fake@test.com',
            'password' => 'password123',
        ]);

        $response->assertUnauthorized();
    }

    // --- Admin can list parents ---
    public function test_admin_can_list_parents(): void
    {
        $response = $this->withHeader('Authorization', 'Bearer '.$this->adminToken())
            ->getJson('/api/v1/admin/parents');

        $response->assertOk()
            ->assertJson(['success' => true]);
    }

    // --- Admin list parents includes children ---
    public function test_admin_parents_list_includes_children(): void
    {
        $child = Child::create([
            'name' => 'Test Child',
            'birth_date' => '2022-01-01',
            'gender' => 'male',
            'status' => 'active',
        ]);
        $this->parent->parent->children()->attach($child->id);

        $response = $this->withHeader('Authorization', 'Bearer '.$this->adminToken())
            ->getJson('/api/v1/admin/parents');

        $response->assertOk();
        $parents = $response->json('data.data');
        $found = collect($parents)->firstWhere('id', $this->parent->parent->id);
        $this->assertNotNull($found);
        $this->assertCount(1, $found['children']);
        $this->assertEquals('Test Child', $found['children'][0]['name']);
    }

    // --- Admin can update parent ---
    public function test_admin_can_update_parent(): void
    {
        $response = $this->withHeader('Authorization', 'Bearer '.$this->adminToken())
            ->putJson('/api/v1/admin/parents/'.$this->parent->parent->id, [
                'phone' => '08999999',
            ]);

        $response->assertOk()
            ->assertJson(['success' => true]);

        $this->assertDatabaseHas('parents', [
            'id' => $this->parent->parent->id,
            'phone' => '08999999',
        ]);
    }

    // --- Admin can delete parent ---
    public function test_admin_can_delete_parent(): void
    {
        $response = $this->withHeader('Authorization', 'Bearer '.$this->adminToken())
            ->deleteJson('/api/v1/admin/parents/'.$this->parent->parent->id);

        $response->assertOk()
            ->assertJson(['success' => true]);

        $this->assertDatabaseMissing('parents', ['id' => $this->parent->parent->id]);
        $this->assertDatabaseMissing('users', ['id' => $this->parent->id]);
    }

    // --- Duplicate email rejected ---
    public function test_duplicate_email_rejected(): void
    {
        $response = $this->withHeader('Authorization', 'Bearer '.$this->adminToken())
            ->postJson('/api/v1/admin/parents', [
                'name' => 'Duplicate',
                'email' => 'admin@test.com', // already exists
                'password' => 'password123',
            ]);

        $response->assertUnprocessable()
            ->assertJsonValidationErrors('email');
    }

    // --- Validation: name required ---
    public function test_name_required(): void
    {
        $response = $this->withHeader('Authorization', 'Bearer '.$this->adminToken())
            ->postJson('/api/v1/admin/parents', [
                'email' => 'new@test.com',
                'password' => 'password123',
            ]);

        $response->assertUnprocessable()
            ->assertJsonValidationErrors('name');
    }
}
