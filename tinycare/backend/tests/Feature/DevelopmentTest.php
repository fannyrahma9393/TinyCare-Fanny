<?php

namespace Tests\Feature;

use App\Models\Admin;
use App\Models\Child;
use App\Models\DevelopmentAssessment;
use App\Models\DevelopmentCategory;
use App\Models\ParentModel;
use App\Models\Role;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class DevelopmentTest extends TestCase
{
    use RefreshDatabase;

    private User $admin;

    private User $parent;

    private Child $child;

    private DevelopmentCategory $category;

    protected function setUp(): void
    {
        parent::setUp();

        config(['services.tinycare.admin_access_code' => 'TEST-ADMIN-CODE']);

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
        $parentModel = ParentModel::create(['user_id' => $this->parent->id]);

        $this->child = Child::create([
            'name' => 'Child Test',
            'birth_date' => '2022-01-01',
            'gender' => 'male',
            'status' => 'active',
        ]);
        $parentModel->children()->attach($this->child->id);

        $this->category = DevelopmentCategory::create([
            'name' => 'motorik',
            'description' => 'Perkembangan motorik',
            'icon' => '🏃',
            'sort_order' => 1,
            'status' => 'active',
        ]);
    }

    private function adminToken(): string
    {
        return $this->admin->createToken('admin-token')->plainTextToken;
    }

    private function parentToken(): string
    {
        return $this->parent->createToken('parent-token')->plainTextToken;
    }

    // ==================== ADMIN CRUD ====================

    public function test_admin_can_get_categories(): void
    {
        $res = $this->withHeader('Authorization', 'Bearer '.$this->adminToken())
            ->getJson('/api/v1/admin/development-categories');

        $res->assertOk()->assertJson(['success' => true]);
        $this->assertCount(1, $res->json('data'));
    }

    public function test_admin_can_create_category(): void
    {
        $res = $this->withHeader('Authorization', 'Bearer '.$this->adminToken())
            ->postJson('/api/v1/admin/development-categories', [
                'name' => 'bahasa',
                'description' => 'Perkembangan bahasa',
            ]);

        $res->assertCreated()->assertJson(['success' => true]);
        $this->assertDatabaseHas('development_categories', ['name' => 'bahasa']);
    }

    public function test_admin_can_get_child_development(): void
    {
        // Create an assessment first
        DevelopmentAssessment::create([
            'child_id' => $this->child->id,
            'development_category_id' => $this->category->id,
            'indicator' => 'Test indicator',
            'progress' => 'baik',
            'observation_date' => now(),
            'assessed_by' => $this->admin->id,
        ]);

        $res = $this->withHeader('Authorization', 'Bearer '.$this->adminToken())
            ->getJson('/api/v1/admin/children/'.$this->child->id.'/development');

        $res->assertOk()->assertJson([
            'success' => true,
            'data' => [
                'child' => ['id' => $this->child->id, 'name' => $this->child->name],
            ],
        ]);

        $categories = $res->json('data.categories');
        $motorik = collect($categories)->firstWhere('name', 'motorik');
        $this->assertNotNull($motorik);
        $this->assertEquals(1, $motorik['total_assessments']);
    }

    public function test_admin_can_create_assessment(): void
    {
        $res = $this->withHeader('Authorization', 'Bearer '.$this->adminToken())
            ->postJson('/api/v1/admin/children/'.$this->child->id.'/development-assessments', [
                'development_category_id' => $this->category->id,
                'indicator' => 'Berjalan dengan stabil',
                'progress' => 'baik',
                'observation_date' => now()->toDateString(),
            ]);

        $res->assertCreated()
            ->assertJson([
                'success' => true,
                'message' => 'Penilaian perkembangan berhasil dicatat.',
            ]);

        $this->assertDatabaseHas('development_assessments', [
            'child_id' => $this->child->id,
            'development_category_id' => $this->category->id,
            'indicator' => 'Berjalan dengan stabil',
            'progress' => 'baik',
        ]);

        $res->assertCreated()
            ->assertJson([
                'success' => true,
                'message' => 'Penilaian perkembangan berhasil dicatat.',
            ]);

        $this->assertDatabaseHas('development_assessments', [
            'child_id' => $this->child->id,
            'development_category_id' => $this->category->id,
            'indicator' => 'Berjalan dengan stabil',
            'progress' => 'baik',
        ]);
    }

    public function test_admin_can_update_assessment(): void
    {
        $assessment = DevelopmentAssessment::create([
            'child_id' => $this->child->id,
            'development_category_id' => $this->category->id,
            'indicator' => 'Old indicator',
            'progress' => 'mulai',
            'observation_date' => now(),
        ]);

        $res = $this->withHeader('Authorization', 'Bearer '.$this->adminToken())
            ->putJson('/api/v1/admin/development-assessments/'.$assessment->id, [
                'progress' => 'sangat_baik',
                'notes' => 'Updated notes',
            ]);

        $res->assertOk()->assertJson(['success' => true]);

        $this->assertDatabaseHas('development_assessments', [
            'id' => $assessment->id,
            'progress' => 'sangat_baik',
            'notes' => 'Updated notes',
        ]);
    }

    public function test_admin_can_delete_assessment(): void
    {
        $assessment = DevelopmentAssessment::create([
            'child_id' => $this->child->id,
            'development_category_id' => $this->category->id,
            'indicator' => 'To delete',
            'progress' => 'baik',
            'observation_date' => now(),
        ]);

        $res = $this->withHeader('Authorization', 'Bearer '.$this->adminToken())
            ->deleteJson('/api/v1/admin/development-assessments/'.$assessment->id);

        $res->assertOk()->assertJson(['success' => true]);
        $this->assertDatabaseMissing('development_assessments', ['id' => $assessment->id]);
    }

    // ==================== VALIDATION ====================

    public function test_assessment_requires_category(): void
    {
        $res = $this->withHeader('Authorization', 'Bearer '.$this->adminToken())
            ->postJson('/api/v1/admin/children/'.$this->child->id.'/development-assessments', [
                'indicator' => 'Test',
                'progress' => 'baik',
                'observation_date' => now()->toDateString(),
            ]);

        $res->assertUnprocessable()->assertJsonValidationErrors('development_category_id');
    }

    public function test_assessment_requires_indicator(): void
    {
        $res = $this->withHeader('Authorization', 'Bearer '.$this->adminToken())
            ->postJson('/api/v1/admin/children/'.$this->child->id.'/development-assessments', [
                'development_category_id' => $this->category->id,
                'progress' => 'baik',
                'observation_date' => now()->toDateString(),
            ]);

        $res->assertUnprocessable()->assertJsonValidationErrors('indicator');
    }

    public function test_assessment_requires_valid_progress(): void
    {
        $res = $this->withHeader('Authorization', 'Bearer '.$this->adminToken())
            ->postJson('/api/v1/admin/children/'.$this->child->id.'/development-assessments', [
                'development_category_id' => $this->category->id,
                'indicator' => 'Test',
                'progress' => 'invalid_progress',
                'observation_date' => now()->toDateString(),
            ]);

        $res->assertUnprocessable()->assertJsonValidationErrors('progress');
    }

    public function test_assessment_requires_observation_date(): void
    {
        $res = $this->withHeader('Authorization', 'Bearer '.$this->adminToken())
            ->postJson('/api/v1/admin/children/'.$this->child->id.'/development-assessments', [
                'development_category_id' => $this->category->id,
                'indicator' => 'Test',
                'progress' => 'baik',
            ]);

        $res->assertUnprocessable()->assertJsonValidationErrors('observation_date');
    }

    public function test_assessment_requires_valid_category(): void
    {
        $res = $this->withHeader('Authorization', 'Bearer '.$this->adminToken())
            ->postJson('/api/v1/admin/children/'.$this->child->id.'/development-assessments', [
                'development_category_id' => 9999,
                'indicator' => 'Test',
                'progress' => 'baik',
                'observation_date' => now()->toDateString(),
            ]);

        $res->assertUnprocessable()->assertJsonValidationErrors('development_category_id');
    }

    // ==================== PARENT ACCESS ====================

    public function test_parent_can_view_child_development(): void
    {
        DevelopmentAssessment::create([
            'child_id' => $this->child->id,
            'development_category_id' => $this->category->id,
            'indicator' => 'Parent view test',
            'progress' => 'berkembang',
            'observation_date' => now(),
        ]);

        $res = $this->withHeader('Authorization', 'Bearer '.$this->parentToken())
            ->getJson('/api/v1/parent/children/'.$this->child->id.'/development');

        $res->assertOk()->assertJson(['success' => true]);
    }

    public function test_parent_cannot_view_other_child_development(): void
    {
        $otherChild = Child::create([
            'name' => 'Other Child',
            'birth_date' => '2022-06-01',
            'gender' => 'female',
            'status' => 'active',
        ]);

        $res = $this->withHeader('Authorization', 'Bearer '.$this->parentToken())
            ->getJson('/api/v1/parent/children/'.$otherChild->id.'/development');

        $res->assertForbidden();
    }

    public function test_parent_cannot_create_assessment(): void
    {
        $res = $this->withHeader('Authorization', 'Bearer '.$this->parentToken())
            ->postJson('/api/v1/admin/children/'.$this->child->id.'/development-assessments', [
                'development_category_id' => $this->category->id,
                'indicator' => 'Parent cannot create',
                'progress' => 'baik',
                'observation_date' => now()->toDateString(),
            ]);

        $res->assertForbidden();
    }

    // ==================== EMPTY STATE ====================

    public function test_empty_child_development_returns_zero_assessments(): void
    {
        $res = $this->withHeader('Authorization', 'Bearer '.$this->adminToken())
            ->getJson('/api/v1/admin/children/'.$this->child->id.'/development');

        $res->assertOk();
        $categories = $res->json('data.categories');
        foreach ($categories as $cat) {
            $this->assertEquals(0, $cat['total_assessments']);
            $this->assertNull($cat['latest_assessment']);
        }
    }

    // ==================== DATA PERSISTENCE ====================

    public function test_assessment_data_persists_correctly(): void
    {
        $res = $this->withHeader('Authorization', 'Bearer '.$this->adminToken())
            ->postJson('/api/v1/admin/children/'.$this->child->id.'/development-assessments', [
                'development_category_id' => $this->category->id,
                'indicator' => 'Persistence test indicator',
                'notes' => 'Test notes for persistence',
                'progress' => 'sangat_baik',
                'observation_date' => '2026-01-15',
            ]);

        $res->assertCreated();
        $id = $res->json('data.id');

        // Verify in DB
        $this->assertDatabaseHas('development_assessments', [
            'id' => $id,
            'child_id' => $this->child->id,
            'development_category_id' => $this->category->id,
            'indicator' => 'Persistence test indicator',
            'notes' => 'Test notes for persistence',
            'progress' => 'sangat_baik',
        ]);

        // Verify GET returns it
        $getRes = $this->withHeader('Authorization', 'Bearer '.$this->adminToken())
            ->getJson('/api/v1/admin/children/'.$this->child->id.'/development');

        $motorik = collect($getRes->json('data.categories'))->firstWhere('name', 'motorik');
        $this->assertEquals(1, $motorik['total_assessments']);
        $this->assertEquals('Persistence test indicator', $motorik['latest_assessment']['indicator']);
        $this->assertEquals('sangat_baik', $motorik['latest_assessment']['progress']);
    }
}
