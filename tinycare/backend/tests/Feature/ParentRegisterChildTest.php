<?php

namespace Tests\Feature;

use App\Models\Admin;
use App\Models\ParentModel;
use App\Models\Role;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class ParentRegisterChildTest extends TestCase
{
    use RefreshDatabase;

    private User $parent;

    private User $admin;

    protected function setUp(): void
    {
        parent::setUp();

        $parentRole = Role::firstOrCreate(['name' => 'parent'], ['description' => 'Parent']);
        $adminRole = Role::firstOrCreate(['name' => 'admin'], ['description' => 'Admin']);

        $this->parent = User::create([
            'name' => 'Parent A',
            'email' => 'parenta@test.com',
            'password' => bcrypt('password123'),
            'role_id' => $parentRole->id,
            'status' => 'active',
        ]);
        ParentModel::create(['user_id' => $this->parent->id]);

        $this->admin = User::create([
            'name' => 'Admin',
            'email' => 'admin@test.com',
            'password' => bcrypt('password123'),
            'role_id' => $adminRole->id,
            'status' => 'active',
        ]);
        Admin::create(['user_id' => $this->admin->id, 'position' => 'Manager']);
    }

    public function test_parent_can_register_own_child(): void
    {
        $response = $this->actingAs($this->parent)->postJson('/api/v1/parent/children', [
            'name' => 'Riska',
            'birth_date' => '2022-05-10',
            'gender' => 'female',
            'address' => 'Jl. Mawar No. 1',
            'health_info' => 'Tidak ada alergi',
        ]);

        $response->assertStatus(201)
            ->assertJson(['success' => true]);

        $this->assertDatabaseHas('children', [
            'name' => 'Riska',
            'gender' => 'female',
            'status' => 'active',
        ]);

        $child = \App\Models\Child::where('name', 'Riska')->first();
        $this->assertEquals('2022-05-10', $child->birth_date->format('Y-m-d'));
        $this->assertTrue($child->parents()->where('parents.id', $this->parent->parent->id)->exists());
        $this->assertNull($child->photo_url);
    }

    public function test_registered_child_appears_in_parent_children_list(): void
    {
        $this->actingAs($this->parent)->postJson('/api/v1/parent/children', [
            'name' => 'Riska',
            'birth_date' => '2022-05-10',
            'gender' => 'female',
        ])->assertStatus(201);

        $this->actingAs($this->parent)->getJson('/api/v1/parent/children')
            ->assertOk()
            ->assertJsonFragment(['name' => 'Riska']);
    }

    public function test_admin_cannot_use_parent_child_route(): void
    {
        $this->actingAs($this->admin)->postJson('/api/v1/parent/children', [
            'name' => 'Riska',
            'birth_date' => '2022-05-10',
            'gender' => 'female',
        ])->assertForbidden();
    }

    public function test_parent_child_registration_validates_required_fields(): void
    {
        $this->actingAs($this->parent)->postJson('/api/v1/parent/children', [
            'gender' => 'male',
        ])->assertStatus(422)
            ->assertJsonValidationErrors(['name', 'birth_date']);
    }

    public function test_parent_child_registration_rejects_future_birth_date(): void
    {
        $this->actingAs($this->parent)->postJson('/api/v1/parent/children', [
            'name' => 'Riska',
            'birth_date' => now()->addDay()->toDateString(),
            'gender' => 'female',
        ])->assertStatus(422)
            ->assertJsonValidationErrors(['birth_date']);
    }
}