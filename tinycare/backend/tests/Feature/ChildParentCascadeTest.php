<?php

namespace Tests\Feature;

use App\Models\Admin;
use App\Models\Child;
use App\Models\ParentModel;
use App\Models\Role;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class ChildParentCascadeTest extends TestCase
{
    use RefreshDatabase;

    private User $admin;

    private User $parent;

    private ParentModel $parentModel;

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

        $this->parent = User::create([
            'name' => 'Parent',
            'email' => 'parent@test.com',
            'password' => bcrypt('password123'),
            'role_id' => $parentRole->id,
            'status' => 'active',
        ]);
        $this->parentModel = ParentModel::create(['user_id' => $this->parent->id]);
    }

    private function makeChild(string $name, string $status = 'active'): Child
    {
        $child = Child::create([
            'name' => $name,
            'birth_date' => '2022-01-01',
            'gender' => 'male',
            'status' => $status,
        ]);
        $this->parentModel->children()->attach($child->id);

        return $child;
    }

    private function adminToken(): string
    {
        return $this->admin->createToken('atok')->plainTextToken;
    }

    // Deactivating the only child makes the parent inactive.
    public function test_deactivating_only_child_deactivates_parent(): void
    {
        $child = $this->makeChild('Solo Child');

        $this->assertTrue($this->parent->fresh()->status === 'active');

        $response = $this->withHeader('Authorization', 'Bearer '.$this->adminToken())
            ->putJson('/api/v1/admin/children/'.$child->id, ['status' => 'inactive']);

        $response->assertOk();
        $this->assertEquals('inactive', $this->parent->fresh()->status);
        $this->assertEquals('inactive', $this->parentModel->fresh()->user->fresh()->status);
    }

    // Deactivating one of two children keeps the parent active.
    public function test_deactivating_one_of_two_children_keeps_parent_active(): void
    {
        $childA = $this->makeChild('Child A');
        $childB = $this->makeChild('Child B');

        $response = $this->withHeader('Authorization', 'Bearer '.$this->adminToken())
            ->putJson('/api/v1/admin/children/'.$childA->id, ['status' => 'inactive']);

        $response->assertOk();
        $this->assertEquals('active', $this->parent->fresh()->status);
        $this->assertEquals('inactive', $childA->fresh()->status);
        $this->assertEquals('active', $childB->fresh()->status);
    }

    // Reactivating the child (when parent has no other active child) reactivates the parent.
    public function test_reactivating_only_child_reactivates_parent(): void
    {
        $child = $this->makeChild('Solo Child');

        $this->withHeader('Authorization', 'Bearer '.$this->adminToken())
            ->putJson('/api/v1/admin/children/'.$child->id, ['status' => 'inactive']);

        $this->assertEquals('inactive', $this->parent->fresh()->status);

        $response = $this->withHeader('Authorization', 'Bearer '.$this->adminToken())
            ->putJson('/api/v1/admin/children/'.$child->id, ['status' => 'active']);

        $response->assertOk();
        $this->assertEquals('active', $this->parent->fresh()->status);
    }

    // An inactive parent cannot log in.
    public function test_inactive_parent_cannot_login(): void
    {
        $child = $this->makeChild('Solo Child');

        $this->withHeader('Authorization', 'Bearer '.$this->adminToken())
            ->putJson('/api/v1/admin/children/'.$child->id, ['status' => 'inactive']);

        $this->assertEquals('inactive', $this->parent->fresh()->status);

        $response = $this->postJson('/api/v1/auth/login', [
            'email' => 'parent@test.com',
            'password' => 'password123',
        ]);

        $response->assertStatus(422);
        $this->assertStringContainsString('tidak aktif', strtolower($response->json('message')));
    }

    // An existing token of a now-inactive user is rejected on the next request.
    public function test_existing_token_of_inactive_user_is_rejected(): void
    {
        $token = $this->parent->createToken('ptok')->plainTextToken;
        $this->makeChild('Solo Child');

        // Sanity: token works while active.
        $this->withHeader('Authorization', 'Bearer '.$token)
            ->getJson('/api/v1/parent/dashboard')
            ->assertOk();

        // Simulate the child->parent cascade: the parent's linked user becomes inactive.
        $this->parent->update(['status' => 'inactive']);
        $this->assertEquals('inactive', $this->parent->fresh()->status, 'user status persisted');

        // The auth guard caches the user across requests within a single test process.
        $this->app['auth']->forgetGuards();

        // The previously issued token is rejected on the next request.
        $this->withHeader('Authorization', 'Bearer '.$token)
            ->getJson('/api/v1/parent/dashboard')
            ->assertStatus(403);
    }

    // Deleting the only child deactivates the parent.
    public function test_deleting_only_child_deactivates_parent(): void
    {
        $child = $this->makeChild('Solo Child');

        $this->withHeader('Authorization', 'Bearer '.$this->adminToken())
            ->deleteJson('/api/v1/admin/children/'.$child->id)
            ->assertOk();

        $this->assertEquals('inactive', $this->parent->fresh()->status);
    }

    // Parent status remains pending (not touched) when no active child - safe guard.
    public function test_pending_parent_is_not_auto_reactivated_by_sync(): void
    {
        $this->parent->update(['status' => 'pending']);
        $this->makeChild('Child', 'inactive');

        // syncUserStatusFromChildren should NOT flip pending -> active/inactive
        $this->parentModel->syncUserStatusFromChildren();

        $this->assertEquals('pending', $this->parent->fresh()->status);
    }
}
