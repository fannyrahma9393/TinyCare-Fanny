<?php

namespace Tests\Feature;

use App\Models\Event;
use App\Models\Role;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Auth;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class ParentEventsTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        Role::firstOrCreate(['name' => 'parent'], ['name' => 'parent']);
        Role::firstOrCreate(['name' => 'admin'], ['name' => 'admin']);
    }

    protected function createActiveParent(): User
    {
        $parentRole = Role::where('name', 'parent')->first();

        return User::create([
            'name' => 'Test Parent',
            'email' => 'parent@test.com',
            'password' => bcrypt('password123'),
            'role_id' => $parentRole->id,
            'status' => 'active',
        ]);
    }

    /** TEST 1: Active parent can fetch events (even if empty). */
    public function test_active_parent_can_fetch_events(): void
    {
        $parent = $this->createActiveParent();
        Sanctum::actingAs($parent);

        $response = $this->getJson('/api/v1/parent/events');
        $response->assertStatus(200);
        $response->assertJsonStructure([
            'success',
            'data' => ['events', 'calendar'],
        ]);
        $response->assertJson(['success' => true]);
    }

    /** TEST 2: Events are returned when they exist. */
    public function test_parent_can_see_events_when_they_exist(): void
    {
        $parent = $this->createActiveParent();
        Sanctum::actingAs($parent);

        Event::create([
            'title' => 'Parent Meeting',
            'description' => 'Monthly parent meeting',
            'date' => now()->addDays(5)->toDateString(),
            'start_time' => '09:00',
            'end_time' => '11:00',
            'type' => 'meeting',
            'status' => 'scheduled',
        ]);

        Event::create([
            'title' => 'Holiday',
            'description' => 'National holiday',
            'date' => now()->addDays(10)->toDateString(),
            'type' => 'holiday',
            'status' => 'scheduled',
        ]);

        $response = $this->getJson('/api/v1/parent/events');
        $response->assertStatus(200);
        $events = $response->json('data.events');
        $this->assertCount(2, $events);
        $this->assertNotEmpty($response->json('data.calendar'));

        $firstEvent = $events[0];
        $this->assertArrayHasKey('id', $firstEvent);
        $this->assertArrayHasKey('title', $firstEvent);
        $this->assertArrayHasKey('date', $firstEvent);
        $this->assertArrayHasKey('type', $firstEvent);
        $this->assertArrayHasKey('status', $firstEvent);
    }

    /** TEST 3: Events with different types parse correctly. */
    public function test_events_with_all_types_are_returned(): void
    {
        $parent = $this->createActiveParent();
        Sanctum::actingAs($parent);

        $types = ['activity', 'holiday', 'special', 'meeting'];
        foreach ($types as $i => $type) {
            Event::create([
                'title' => "Event $type",
                'date' => now()->addDays($i + 1)->toDateString(),
                'type' => $type,
                'status' => 'scheduled',
            ]);
        }

        $response = $this->getJson('/api/v1/parent/events');
        $response->assertStatus(200);
        $events = $response->json('data.events');
        $this->assertCount(4, $events);

        $returnedTypes = array_column($events, 'type');
        foreach ($types as $type) {
            $this->assertContains($type, $returnedTypes);
        }
    }

    /** TEST 4: Empty events returns valid structure with empty arrays. */
    public function test_empty_events_returns_valid_structure(): void
    {
        $parent = $this->createActiveParent();
        Sanctum::actingAs($parent);

        $response = $this->getJson('/api/v1/parent/events');
        $response->assertStatus(200);
        $data = $response->json('data');
        $this->assertIsArray($data['events']);
        $this->assertEmpty($data['events']);
        $this->assertIsArray($data['calendar']);
    }

    /** TEST 5: Events with null optional fields don't crash. */
    public function test_events_with_null_fields_dont_crash(): void
    {
        $parent = $this->createActiveParent();
        Sanctum::actingAs($parent);

        Event::create([
            'title' => 'Minimal Event',
            'date' => now()->addDays(1)->toDateString(),
        ]);

        $response = $this->getJson('/api/v1/parent/events');
        $response->assertStatus(200);
        $events = $response->json('data.events');
        $this->assertCount(1, $events);
        $this->assertNull($events[0]['description']);
        $this->assertNull($events[0]['start_time']);
        $this->assertNull($events[0]['end_time']);
        $this->assertNull($events[0]['location']);
    }

    /** TEST 6: Unauthenticated request is rejected. */
    public function test_unauthenticated_request_is_rejected(): void
    {
        $response = $this->getJson('/api/v1/parent/events');
        $response->assertStatus(401);
    }

    /** TEST 7: Admin cannot access parent events endpoint. */
    public function test_admin_cannot_access_parent_events(): void
    {
        $adminRole = Role::where('name', 'admin')->first();
        $admin = User::create([
            'name' => 'Test Admin',
            'email' => 'admin@test.com',
            'password' => bcrypt('password123'),
            'role_id' => $adminRole->id,
            'status' => 'active',
        ]);
        Sanctum::actingAs($admin);

        $response = $this->getJson('/api/v1/parent/events');
        $response->assertStatus(403);
    }

    /** TEST 8: Pending parent cannot login. */
    public function test_pending_parent_cannot_login(): void
    {
        $parentRole = Role::where('name', 'parent')->first();
        User::create([
            'name' => 'Pending Parent',
            'email' => 'pending@test.com',
            'password' => bcrypt('password123'),
            'role_id' => $parentRole->id,
            'status' => 'pending',
        ]);

        $response = $this->postJson('/api/v1/auth/login', [
            'email' => 'pending@test.com',
            'password' => 'password123',
        ]);

        $response->assertStatus(422);
        $response->assertJsonValidationErrors('email');
    }

    /** TEST 9: Newly registered parent gets status 'pending'. */
    public function test_new_parent_registration_returns_pending(): void
    {
        $response = $this->postJson('/api/v1/auth/register-parent', [
            'name' => 'New Parent',
            'email' => 'newparent@test.com',
            'password' => 'password123456',
            'password_confirmation' => 'password123456',
        ]);

        $response->assertStatus(201);
        $response->assertJson([
            'success' => true,
            'data' => ['status' => 'pending'],
        ]);

        $user = User::where('email', 'newparent@test.com')->first();
        $this->assertNotNull($user);
        $this->assertEquals('pending', $user->status);
        $this->assertEquals('parent', $user->role->name);
    }

    /** TEST 10: Full flow - register → approve → login → events. */
    public function test_full_flow_register_approve_login_events(): void
    {
        // Step 1: Register
        $response = $this->postJson('/api/v1/auth/register-parent', [
            'name' => 'Flow Test Parent',
            'email' => 'flowtest@test.com',
            'password' => 'password123456',
            'password_confirmation' => 'password123456',
        ]);
        $response->assertStatus(201);

        $user = User::where('email', 'flowtest@test.com')->first();
        $this->assertEquals('pending', $user->status);

        // Step 2: Admin approve (use actingAs for admin)
        $adminRole = Role::where('name', 'admin')->first();
        $admin = User::create([
            'name' => 'Admin',
            'email' => 'flowtest-admin@test.com',
            'password' => bcrypt('password123'),
            'role_id' => $adminRole->id,
            'status' => 'active',
        ]);

        $this->actingAs($admin, 'sanctum')
            ->postJson("/api/v1/admin/users/{$user->id}/approve")
            ->assertStatus(200);

        // Clear the admin's auth state to avoid leaking
        Auth::forgetGuards();

        $user->refresh();
        $this->assertEquals('active', $user->status);

        // Step 3: Parent login
        $loginResponse = $this->postJson('/api/v1/auth/login', [
            'email' => 'flowtest@test.com',
            'password' => 'password123456',
        ]);
        $loginResponse->assertStatus(200);
        $loginResponse->assertJson(['success' => true]);
        $this->assertEquals('parent', $loginResponse->json('data.user.role'));

        // Step 4: Fetch events using the token with explicit header
        $token = $loginResponse->json('data.token');
        $this->assertNotEmpty($token);

        // Use a fresh request with only the Bearer token
        $response = $this->withHeaders([
            'Authorization' => 'Bearer '.$token,
            'Accept' => 'application/json',
        ])->getJson('/api/v1/parent/events');

        $response->assertStatus(200);
        $response->assertJson(['success' => true]);
        $response->assertJsonStructure([
            'data' => ['events', 'calendar'],
        ]);
    }
}
