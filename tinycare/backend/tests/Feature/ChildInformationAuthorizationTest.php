<?php

namespace Tests\Feature;

use App\Models\Admin;
use App\Models\Child;
use App\Models\ChildInformation;
use App\Models\Notification;
use App\Models\ParentModel;
use App\Models\Role;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class ChildInformationAuthorizationTest extends TestCase
{
    use RefreshDatabase;

    private User $admin;

    private User $parentA;

    private User $parentB;

    private Child $childA;

    private Child $childB;

    private ParentModel $parentModelA;

    private ParentModel $parentModelB;

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
        $this->parentModelA = ParentModel::create(['user_id' => $this->parentA->id]);

        $this->parentB = User::create([
            'name' => 'Parent B',
            'email' => 'parentb@test.com',
            'password' => bcrypt('password123'),
            'role_id' => $parentRole->id,
            'status' => 'active',
        ]);
        $this->parentModelB = ParentModel::create(['user_id' => $this->parentB->id]);

        $this->childA = Child::create([
            'name' => 'Child A',
            'birth_date' => '2022-01-01',
            'gender' => 'male',
            'status' => 'active',
        ]);
        $this->parentModelA->children()->attach($this->childA->id);

        $this->childB = Child::create([
            'name' => 'Child B',
            'birth_date' => '2022-06-01',
            'gender' => 'female',
            'status' => 'active',
        ]);
        $this->parentModelB->children()->attach($this->childB->id);
    }

    private function adminToken(): string
    {
        return $this->admin->createToken('admin-token')->plainTextToken;
    }

    private function parentAToken(): string
    {
        return $this->parentA->createToken('pa-token')->plainTextToken;
    }

    private function parentBToken(): string
    {
        return $this->parentB->createToken('pb-token')->plainTextToken;
    }

    // ==================== ADMIN CAN CREATE / MANAGE ====================

    public function test_admin_can_create_child_information(): void
    {
        $res = $this->withHeader('Authorization', 'Bearer '.$this->adminToken())
            ->postJson('/api/v1/admin/child-information', [
                'child_id' => $this->childA->id,
                'title' => 'Alergi makanan',
                'content' => 'Tidak boleh makan kacang.',
                'priority' => 'important',
            ]);

        $res->assertCreated()
            ->assertJsonPath('data.child_id', $this->childA->id)
            ->assertJsonPath('data.title', 'Alergi makanan');
    }

    public function test_admin_can_list_all_child_information(): void
    {
        ChildInformation::create([
            'child_id' => $this->childA->id,
            'created_by' => $this->admin->id,
            'title' => 'Info A',
            'content' => 'Konten A',
        ]);
        ChildInformation::create([
            'child_id' => $this->childB->id,
            'created_by' => $this->admin->id,
            'title' => 'Info B',
            'content' => 'Konten B',
        ]);

        $res = $this->withHeader('Authorization', 'Bearer '.$this->adminToken())
            ->getJson('/api/v1/admin/child-information');

        $res->assertOk();
        $this->assertCount(2, $res->json('data.data'));
    }

    // ==================== PARENT ISOLATION ====================

    public function test_parent_sees_only_own_children_information(): void
    {
        ChildInformation::create([
            'child_id' => $this->childA->id,
            'created_by' => $this->admin->id,
            'title' => 'Milik A',
            'content' => 'Konten A',
        ]);
        ChildInformation::create([
            'child_id' => $this->childB->id,
            'created_by' => $this->admin->id,
            'title' => 'Milik B',
            'content' => 'Konten B',
        ]);

        $res = $this->withHeader('Authorization', 'Bearer '.$this->parentAToken())
            ->getJson('/api/v1/parent/child-information');

        $res->assertOk();
        $data = $res->json('data.data');
        $this->assertCount(1, $data);
        $this->assertEquals('Milik A', $data[0]['title']);
    }

    public function test_parent_b_cannot_see_child_a_information(): void
    {
        ChildInformation::create([
            'child_id' => $this->childA->id,
            'created_by' => $this->admin->id,
            'title' => 'Milik A',
            'content' => 'Konten A',
        ]);

        $res = $this->withHeader('Authorization', 'Bearer '.$this->parentBToken())
            ->getJson('/api/v1/parent/child-information');

        $res->assertOk();
        $this->assertCount(0, $res->json('data.data'));
    }

    // ==================== IDOR: PARENT ACCESSING OTHER CHILD ====================

    public function test_parent_cannot_read_information_of_other_child_via_show(): void
    {
        $info = ChildInformation::create([
            'child_id' => $this->childB->id,
            'created_by' => $this->admin->id,
            'title' => 'Milik B',
            'content' => 'Konten B',
        ]);

        // Policy: parent A cannot view information belonging to child B
        $res = $this->actingAs($this->parentA)
            ->getJson('/api/v1/admin/child-information/'.$info->id);

        // Parent is not even authorized to reach the admin route (role:admin middleware)
        $res->assertForbidden();
    }

    public function test_parent_cannot_create_child_information(): void
    {
        $res = $this->withHeader('Authorization', 'Bearer '.$this->parentAToken())
            ->postJson('/api/v1/admin/child-information', [
                'child_id' => $this->childA->id,
                'title' => 'Coba',
                'content' => 'Tidak boleh.',
            ]);

        $res->assertForbidden();
    }

    public function test_parent_cannot_filter_to_other_child_via_child_id(): void
    {
        ChildInformation::create([
            'child_id' => $this->childB->id,
            'created_by' => $this->admin->id,
            'title' => 'Milik B',
            'content' => 'Konten B',
        ]);

        // Parent A requests info filtered by child B -> should get empty (ownership enforced)
        $res = $this->withHeader('Authorization', 'Bearer '.$this->parentAToken())
            ->getJson('/api/v1/parent/child-information?child_id='.$this->childB->id);

        $res->assertOk();
        $this->assertCount(0, $res->json('data.data'));
    }

    // ==================== PARENT CANNOT USE ADMIN MANAGEMENT ====================

    public function test_parent_cannot_create_admin(): void
    {
        $res = $this->withHeader('Authorization', 'Bearer '.$this->parentAToken())
            ->postJson('/api/v1/admin/admins', [
                'name' => 'Fake Admin',
                'email' => 'fakeadmin@test.com',
                'password' => 'password123',
            ]);

        $res->assertForbidden();
    }

    // ==================== NOTIFICATION TARGETING ====================

    public function test_creating_information_notifies_only_targeted_parent(): void
    {
        $this->withHeader('Authorization', 'Bearer '.$this->adminToken())
            ->postJson('/api/v1/admin/child-information', [
                'child_id' => $this->childA->id,
                'title' => 'Info untuk Anak A',
                'content' => 'Konten A',
                'priority' => 'normal',
            ]);

        // Only parent A should have a notification for child A's information
        $notifA = Notification::where('user_id', $this->parentA->id)->get();
        $notifB = Notification::where('user_id', $this->parentB->id)->get();

        $this->assertCount(1, $notifA, 'Parent A should receive the notification');
        $this->assertEquals('child_information', $notifA->first()->type);
        $this->assertEquals($this->childA->id, $notifA->first()->data['child_id'] ?? null);

        $this->assertCount(0, $notifB, 'Parent B should NOT receive the notification');
    }

    public function test_inactive_parent_does_not_receive_notification(): void
    {
        $this->parentA->update(['status' => 'inactive']);

        $this->withHeader('Authorization', 'Bearer '.$this->adminToken())
            ->postJson('/api/v1/admin/child-information', [
                'child_id' => $this->childA->id,
                'title' => 'Info',
                'content' => 'Konten',
            ]);

        $notifA = Notification::where('user_id', $this->parentA->id)->count();
        $this->assertEquals(0, $notifA, 'Inactive parent should not receive notification');
    }

    // ==================== DATABASE SAVE + TRANSPORT FAILURE ISOLATION ====================

    public function test_information_saved_even_if_role_has_no_parent_record(): void
    {
        // A child with no parents should still allow admin to create information
        $orphanChild = Child::create([
            'name' => 'Orphan',
            'birth_date' => '2021-01-01',
            'gender' => 'male',
            'status' => 'active',
        ]);

        $res = $this->withHeader('Authorization', 'Bearer '.$this->adminToken())
            ->postJson('/api/v1/admin/child-information', [
                'child_id' => $orphanChild->id,
                'title' => 'Info Orphan',
                'content' => 'Konten',
            ]);

        // Information still persists even with no parent to notify
        $res->assertCreated();
        $this->assertDatabaseHas('child_information', [
            'child_id' => $orphanChild->id,
            'title' => 'Info Orphan',
        ]);
    }

    // ==================== VALIDATION ====================

    public function test_child_information_requires_child_and_content(): void
    {
        $res = $this->withHeader('Authorization', 'Bearer '.$this->adminToken())
            ->postJson('/api/v1/admin/child-information', [
                'title' => 'No child',
            ]);

        $res->assertStatus(422)
            ->assertJsonValidationErrors(['child_id', 'content']);
    }
}
