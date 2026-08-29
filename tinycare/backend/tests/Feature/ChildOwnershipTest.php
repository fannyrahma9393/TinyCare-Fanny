<?php

namespace Tests\Feature;

use App\Models\Admin;
use App\Models\Child;
use App\Models\ParentModel;
use App\Models\Role;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class ChildOwnershipTest extends TestCase
{
    use RefreshDatabase;

    private User $admin;

    private User $parentA;

    private User $parentB;

    private Child $childA1;

    private Child $childB1;

    protected function setUp(): void
    {
        parent::setUp();

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

        $this->parentA = User::create([
            'name' => 'Parent A',
            'email' => 'parenta@test.com',
            'password' => bcrypt('password123'),
            'role_id' => $parentRole->id,
            'status' => 'active',
        ]);
        $parentModelA = ParentModel::create(['user_id' => $this->parentA->id]);

        $this->parentB = User::create([
            'name' => 'Parent B',
            'email' => 'parentb@test.com',
            'password' => bcrypt('password123'),
            'role_id' => $parentRole->id,
            'status' => 'active',
        ]);
        $parentModelB = ParentModel::create(['user_id' => $this->parentB->id]);

        $this->childA1 = Child::create([
            'name' => 'Child A1',
            'birth_date' => '2022-01-01',
            'gender' => 'male',
            'status' => 'active',
        ]);
        $parentModelA->children()->attach($this->childA1->id);

        $this->childB1 = Child::create([
            'name' => 'Child B1',
            'birth_date' => '2022-06-01',
            'gender' => 'female',
            'status' => 'active',
        ]);
        $parentModelB->children()->attach($this->childB1->id);
    }

    // Admin sees all children
    public function test_admin_sees_all_children(): void
    {
        $token = $this->admin->createToken('atoken')->plainTextToken;
        $response = $this->withHeader('Authorization', "Bearer $token")
            ->getJson('/api/v1/admin/children');

        $response->assertOk();
        $this->assertCount(2, $response->json('data.data'));
    }

    // Parent A sees only child A1
    public function test_parent_sees_only_own_children(): void
    {
        $token = $this->parentA->createToken('ptoken')->plainTextToken;
        $response = $this->withHeader('Authorization', "Bearer $token")
            ->getJson('/api/v1/parent/children');

        $response->assertOk();
        $children = $response->json('data.data');
        $this->assertCount(1, $children);
        $this->assertEquals($this->childA1->id, $children[0]['id']);
    }

    // Parent B does NOT see child A1
    public function test_parent_does_not_see_other_children(): void
    {
        $token = $this->parentB->createToken('ptoken')->plainTextToken;
        $response = $this->withHeader('Authorization', "Bearer $token")
            ->getJson('/api/v1/parent/children');

        $response->assertOk();
        $children = $response->json('data.data');
        $ids = collect($children)->pluck('id')->toArray();
        $this->assertNotContains($this->childA1->id, $ids);
    }

    // Parent cannot access other parent's child directly
    public function test_parent_cannot_access_other_child(): void
    {
        $token = $this->parentA->createToken('ptoken')->plainTextToken;
        $response = $this->withHeader('Authorization', "Bearer $token")
            ->getJson('/api/v1/parent/children/'.$this->childB1->id);

        $response->assertForbidden();
    }

    // Parent can access own child
    public function test_parent_can_access_own_child(): void
    {
        $token = $this->parentA->createToken('ptoken')->plainTextToken;
        $response = $this->withHeader('Authorization', "Bearer $token")
            ->getJson('/api/v1/parent/children/'.$this->childA1->id);

        $response->assertOk();
        $this->assertEquals($this->childA1->id, $response->json('data.id'));
    }
}
