<?php

namespace Tests\Feature;

use App\Models\Admin;
use App\Models\Child;
use App\Models\ChildInformation;
use App\Models\DailyStory;
use App\Models\DevelopmentAssessment;
use App\Models\DevelopmentCategory;
use App\Models\FcmToken;
use App\Models\Notification;
use App\Models\ParentModel;
use App\Models\Role;
use App\Models\User;
use App\Services\FcmNotificationService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class FcmNotificationTest extends TestCase
{
    use RefreshDatabase;

    private User $admin;

    private User $parentA;

    private User $parentB;

    private ParentModel $parentModelA;

    private ParentModel $parentModelB;

    private Child $childA;

    private Child $childB;

    protected function setUp(): void
    {
        parent::setUp();
        FcmNotificationService::setStaticTransport(null);

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
            'name' => 'Budi',
            'birth_date' => '2022-01-01',
            'gender' => 'male',
            'status' => 'active',
        ]);
        $this->parentModelA->children()->attach($this->childA->id);

        $this->childB = Child::create([
            'name' => 'Siti',
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

    // ==================== FCM TOKEN REGISTRATION ====================

    public function test_parent_can_register_fcm_token(): void
    {
        $res = $this->actingAs($this->parentA)
            ->postJson('/api/v1/fcm-tokens', [
                'token' => 'fcm-token-aaa',
                'platform' => 'web',
                'device' => 'Chrome on Windows',
            ]);

        $res->assertCreated();
        $this->assertDatabaseHas('fcm_tokens', [
            'user_id' => $this->parentA->id,
            'token' => 'fcm-token-aaa',
            'platform' => 'web',
        ]);
    }

    public function test_unauthenticated_user_cannot_register_token(): void
    {
        $res = $this->postJson('/api/v1/fcm-tokens', ['token' => 'xyz']);

        $res->assertUnauthorized();
        $this->assertDatabaseCount('fcm_tokens', 0);
    }

    public function test_duplicate_token_does_not_duplicate_row(): void
    {
        $payload = ['token' => 'fcm-token-dup', 'platform' => 'web'];

        $this->actingAs($this->parentA)->postJson('/api/v1/fcm-tokens', $payload);
        $this->actingAs($this->parentA)->postJson('/api/v1/fcm-tokens', $payload);

        $this->assertDatabaseCount('fcm_tokens', 1);
    }

    public function test_token_is_tied_to_the_authenticated_user(): void
    {
        $this->actingAs($this->parentA)->postJson('/api/v1/fcm-tokens', ['token' => 'fcm-token-a', 'platform' => 'web']);
        $this->actingAs($this->parentB)->postJson('/api/v1/fcm-tokens', ['token' => 'fcm-token-b', 'platform' => 'web']);

        $this->assertDatabaseHas('fcm_tokens', ['user_id' => $this->parentA->id, 'token' => 'fcm-token-a']);
        $this->assertDatabaseHas('fcm_tokens', ['user_id' => $this->parentB->id, 'token' => 'fcm-token-b']);
    }

    public function test_user_cannot_delete_other_users_token(): void
    {
        FcmToken::create([
            'user_id' => $this->parentA->id,
            'token' => 'shared-token',
            'platform' => 'web',
            'last_used_at' => now(),
        ]);

        // Parent B tries to delete a token that belongs to parent A -> no row removed
        $this->actingAs($this->parentB)
            ->deleteJson('/api/v1/fcm-tokens', ['token' => 'shared-token']);

        $this->assertDatabaseHas('fcm_tokens', ['user_id' => $this->parentA->id, 'token' => 'shared-token']);
    }

    // ==================== FCM SENDING + TARGETING ====================

    /**
     * Bind a configured FcmNotificationService with a mock transport callable.
     */
    private function bindFcm(callable $transport): void
    {
        // Configure credentials so isConfigured() is true, but force the access
        // token so the OAuth2 token-exchange / JWT signing (openssl) is bypassed.
        config(['services.firebase.project_id' => 'tinycare-test']);
        config(['services.firebase.client_email' => 'test@tinycare-test.iam.gserviceaccount.com']);
        config(['services.firebase.private_key' => 'test-private-key']);

        $service = new FcmNotificationService(null, $transport);
        $service->setAccessToken('test-access-token');

        // Bind the configured instance so app(FcmNotificationService::class)
        // inside the controller resolves it.
        $this->app->instance(FcmNotificationService::class, $service);

        // Also set the static transport so it is honored regardless of scope.
        FcmNotificationService::setStaticTransport($transport);
    }

    public function test_information_save_sends_fcm_to_correct_parent_only(): void
    {
        // Pre-create FCM tokens directly in DB (avoids multi-request auth issue)
        FcmToken::create(['user_id' => $this->parentA->id, 'token' => 'fcm-token-a1', 'platform' => 'web', 'last_used_at' => now()]);
        FcmToken::create(['user_id' => $this->parentB->id, 'token' => 'fcm-token-b1', 'platform' => 'web', 'last_used_at' => now()]);

        $sent = [];
        $this->bindFcm(function ($method, $url, $options) use (&$sent) {
            if (isset($options['json']['message']['token'])) {
                $sent[] = $options['json']['message']['token'];
            }
            return ['status' => 200, 'body' => '{"name":"projects/x/messages/y"}'];
        });

        $res = $this->withHeader('Authorization', 'Bearer '.$this->adminToken())
            ->postJson('/api/v1/admin/child-information', [
                'child_id' => $this->childA->id,
                'title' => 'Kurang sehat',
                'content' => 'Ananda sedang kurang sehat.',
                'priority' => 'important',
            ]);

        $res->assertCreated()
            ->assertJsonPath('notify.targeted_parents', 1)
            ->assertJsonPath('notify.fcm_sent', 1)
            ->assertJsonPath('notify.fcm_failed', 0);

        // Only parent A's token was used — never parent B's.
        $this->assertEquals(['fcm-token-a1'], $sent);
        $this->assertNotContains('fcm-token-b1', $sent);
    }

    public function test_database_notification_is_created_and_fcm_failure_does_not_fail_save(): void
    {
        FcmToken::create(['user_id' => $this->parentA->id, 'token' => 'fcm-a1', 'platform' => 'web', 'last_used_at' => now()]);

        // Simulate a server-side FCM failure (500) — must NOT fail the information save.
        $this->bindFcm(fn () => ['status' => 500, 'body' => '{"error":{"message":"internal"}}']);

        $res = $this->withHeader('Authorization', 'Bearer '.$this->adminToken())
            ->postJson('/api/v1/admin/child-information', [
                'child_id' => $this->childA->id,
                'title' => 'Kurang sehat',
                'content' => 'Ananda sedang kurang sehat.',
            ]);

        $res->assertCreated();
        $this->assertDatabaseHas('child_information', [
            'child_id' => $this->childA->id,
            'title' => 'Kurang sehat',
        ]);

        // DB notification still created for the targeted parent.
        $dbNotif = Notification::where('user_id', $this->parentA->id)->get();
        $this->assertCount(1, $dbNotif);
        $this->assertEquals('child_information', $dbNotif->first()->type);

        // And the FCM token is NOT removed on a generic server error.
        $this->assertDatabaseHas('fcm_tokens', ['user_id' => $this->parentA->id, 'token' => 'fcm-a1']);
    }

    public function test_invalid_token_is_removed_but_valid_other_tokens_still_sent(): void
    {
        // Parent A has two devices: one valid, one expired.
        FcmToken::create(['user_id' => $this->parentA->id, 'token' => 'valid-token', 'platform' => 'web', 'last_used_at' => now()]);
        FcmToken::create(['user_id' => $this->parentA->id, 'token' => 'expired-token', 'platform' => 'web', 'last_used_at' => now()]);

        $seen = [];
        $this->bindFcm(function ($method, $url, $options) use (&$seen) {
            if (! isset($options['json']['message']['token'])) {
                return ['status' => 200, 'body' => '{"access_token":"fake-token"}'];
            }
            $token = $options['json']['message']['token'];
            $seen[] = $token;

            if ($token === 'expired-token') {
                return ['status' => 404, 'body' => '{"error":{"status":"NOT_FOUND","message":"Requested entity was not found."}}'];
            }

            return ['status' => 200, 'body' => '{"name":"ok"}'];
        });

        $res = $this->withHeader('Authorization', 'Bearer '.$this->adminToken())
            ->postJson('/api/v1/admin/child-information', [
                'child_id' => $this->childA->id,
                'title' => 'Info',
                'content' => 'Konten',
            ]);

        // Both tokens were attempted.
        $this->assertEquals(['valid-token', 'expired-token'], $seen);

        // One success, one failed.
        $res->assertCreated()->assertJsonPath('notify.fcm_sent', 1)->assertJsonPath('notify.fcm_failed', 1);

        // Invalid token removed, valid token kept.
        $this->assertDatabaseMissing('fcm_tokens', ['user_id' => $this->parentA->id, 'token' => 'expired-token']);
        $this->assertDatabaseHas('fcm_tokens', ['user_id' => $this->parentA->id, 'token' => 'valid-token']);
    }

    public function test_other_parent_does_not_receive_fcm_for_child_a(): void
    {
        FcmToken::create(['user_id' => $this->parentA->id, 'token' => 'fcm-a', 'platform' => 'web', 'last_used_at' => now()]);
        FcmToken::create(['user_id' => $this->parentB->id, 'token' => 'fcm-b', 'platform' => 'web', 'last_used_at' => now()]);

        $sent = [];
        $this->bindFcm(function ($method, $url, $options) use (&$sent) {
            if (isset($options['json']['message']['token'])) {
                $sent[] = $options['json']['message']['token'];
            }
            return ['status' => 200, 'body' => '{"name":"ok"}'];
        });
        $this->withHeader('Authorization', 'Bearer '.$this->adminToken())
            ->postJson('/api/v1/admin/child-information', [
                'child_id' => $this->childA->id,
                'title' => 'Info Budi',
                'content' => 'Konten',
            ]);

        $this->assertEquals(['fcm-a'], $sent);
        $this->assertDatabaseMissing('notifications', ['user_id' => $this->parentB->id]);
    }

    public function test_fcm_send_logs_skipped_notification_when_not_configured(): void
    {
        // No Firebase credentials configured -> send is skipped, not crashed.
        config(['services.firebase.project_id' => null]);
        config(['services.firebase.client_email' => null]);
        config(['services.firebase.private_key' => null]);

        $res = $this->withHeader('Authorization', 'Bearer '.$this->adminToken())
            ->postJson('/api/v1/admin/child-information', [
                'child_id' => $this->childA->id,
                'title' => 'Info',
                'content' => 'Konten',
            ]);

        $res->assertCreated()->assertJsonPath('notify.fcm_configured', false);
        $this->assertDatabaseHas('child_information', ['child_id' => $this->childA->id]);
    }

    public function test_parent_cannot_access_other_children_information(): void
    {
        ChildInformation::create([
            'child_id' => $this->childB->id,
            'created_by' => $this->admin->id,
            'title' => 'Info Siti',
            'content' => 'Privat Siti',
        ]);

        // Parent A listing information must never see Child B's info.
        $res = $this->actingAs($this->parentA)
            ->getJson('/api/v1/parent/child-information');

        $res->assertOk();
        $this->assertCount(0, $res->json('data.data'));
    }

    // ==================== MULTI-PLATFORM (WEB + ANDROID) ====================

    public function test_parent_can_register_android_fcm_token(): void
    {
        $this->actingAs($this->parentA)
            ->postJson('/api/v1/fcm-tokens', [
                'token' => 'fcm-android-aaa',
                'platform' => 'android',
                'device' => 'Pixel 7',
            ])
            ->assertCreated();

        $this->assertDatabaseHas('fcm_tokens', [
            'user_id' => $this->parentA->id,
            'token' => 'fcm-android-aaa',
            'platform' => 'android',
        ]);
    }

    public function test_one_parent_can_hold_multiple_platform_tokens(): void
    {
        // Parent A registers on web AND on android (two devices).
        $this->actingAs($this->parentA)->postJson('/api/v1/fcm-tokens', ['token' => 'web-token', 'platform' => 'web']);
        $this->actingAs($this->parentA)->postJson('/api/v1/fcm-tokens', ['token' => 'android-token', 'platform' => 'android']);

        $this->assertDatabaseCount('fcm_tokens', 2);
        $this->assertDatabaseHas('fcm_tokens', ['user_id' => $this->parentA->id, 'token' => 'web-token', 'platform' => 'web']);
        $this->assertDatabaseHas('fcm_tokens', ['user_id' => $this->parentA->id, 'token' => 'android-token', 'platform' => 'android']);
    }

    public function test_child_information_push_goes_to_both_web_and_android_tokens(): void
    {
        // Parent A has a web AND an android device.
        FcmToken::create(['user_id' => $this->parentA->id, 'token' => 'web-token-a1', 'platform' => 'web', 'last_used_at' => now()]);
        FcmToken::create(['user_id' => $this->parentA->id, 'token' => 'android-token-a1', 'platform' => 'android', 'last_used_at' => now()]);

        $sent = [];
        $this->bindFcm(function ($method, $url, $options) use (&$sent) {
            if (isset($options['json']['message']['token'])) {
                $sent[] = $options['json']['message']['token'];
            }
            return ['status' => 200, 'body' => '{"name":"ok"}'];
        });

        $this->withHeader('Authorization', 'Bearer '.$this->adminToken())
            ->postJson('/api/v1/admin/child-information', [
                'child_id' => $this->childA->id,
                'title' => 'Info',
                'content' => 'Konten',
            ])
            ->assertCreated()
            ->assertJsonPath('notify.fcm_sent', 2);

        // Both the web and the android token of the SAME parent were used.
        $this->assertEqualsCanonicalizing(['web-token-a1', 'android-token-a1'], $sent);
    }

    // ==================== DEVELOPMENT + DAILY STORY FCM ====================

    public function test_development_save_sends_fcm_to_correct_parent_only(): void
    {
        $category = DevelopmentCategory::create([
            'name' => 'Motorik',
            'status' => 'active',
        ]);
        FcmToken::create(['user_id' => $this->parentA->id, 'token' => 'd-a', 'platform' => 'web', 'last_used_at' => now()]);
        FcmToken::create(['user_id' => $this->parentB->id, 'token' => 'd-b', 'platform' => 'web', 'last_used_at' => now()]);

        $sent = [];
        $this->bindFcm(function ($method, $url, $options) use (&$sent) {
            if (isset($options['json']['message']['token'])) {
                $sent[] = $options['json']['message']['token'];
            }
            return ['status' => 200, 'body' => '{"name":"ok"}'];
        });

        $res = $this->withHeader('Authorization', 'Bearer '.$this->adminToken())
            ->postJson('/api/v1/admin/children/'.$this->childA->id.'/development-assessments', [
                'development_category_id' => $category->id,
                'indicator' => 'Menggambar lingkaran',
                'progress' => 'berkembang',
                'observation_date' => '2024-02-10',
            ]);

        $res->assertCreated();
        $this->assertDatabaseHas('development_assessments', ['child_id' => $this->childA->id]);

        // Only parent A's token was targeted — never parent B's.
        $this->assertEquals(['d-a'], $sent);
        $this->assertNotContains('d-b', $sent);

        // DB notification with type 'development' for parent A only.
        $this->assertDatabaseHas('notifications', [
            'user_id' => $this->parentA->id,
            'type' => 'development',
        ]);
        $this->assertDatabaseMissing('notifications', ['user_id' => $this->parentB->id]);
    }

    public function test_daily_story_save_sends_fcm_to_correct_parent_only(): void
    {
        FcmToken::create(['user_id' => $this->parentA->id, 'token' => 's-a', 'platform' => 'web', 'last_used_at' => now()]);
        FcmToken::create(['user_id' => $this->parentB->id, 'token' => 's-b', 'platform' => 'web', 'last_used_at' => now()]);

        $sent = [];
        $this->bindFcm(function ($method, $url, $options) use (&$sent) {
            if (isset($options['json']['message']['token'])) {
                $sent[] = $options['json']['message']['token'];
            }
            return ['status' => 200, 'body' => '{"name":"ok"}'];
        });

        $res = $this->withHeader('Authorization', 'Bearer '.$this->adminToken())
            ->postJson('/api/v1/admin/children/'.$this->childA->id.'/daily-stories', [
                'date' => '2024-02-10',
                'summary' => 'Hari yang menyenangkan.',
            ]);

        $res->assertCreated();
        $this->assertDatabaseHas('daily_stories', ['child_id' => $this->childA->id]);

        // Only parent A's token was targeted — never parent B's.
        $this->assertEquals(['s-a'], $sent);
        $this->assertNotContains('s-b', $sent);

        $this->assertDatabaseHas('notifications', [
            'user_id' => $this->parentA->id,
            'type' => 'daily_story',
        ]);
        $this->assertDatabaseMissing('notifications', ['user_id' => $this->parentB->id]);
    }

    public function test_development_fcm_failure_does_not_fail_save(): void
    {
        $category = DevelopmentCategory::create(['name' => 'Bahasa', 'status' => 'active']);
        FcmToken::create(['user_id' => $this->parentA->id, 'token' => 'dev-fail', 'platform' => 'web', 'last_used_at' => now()]);

        // Server-side FCM error (500).
        $this->bindFcm(fn () => ['status' => 500, 'body' => '{"error":{"message":"internal"}}']);

        $res = $this->withHeader('Authorization', 'Bearer '.$this->adminToken())
            ->postJson('/api/v1/admin/children/'.$this->childA->id.'/development-assessments', [
                'development_category_id' => $category->id,
                'indicator' => 'Bicara 2 kata',
                'progress' => 'mulai',
                'observation_date' => '2024-02-10',
            ]);

        // Assessment is saved despite FCM failure; DB notification still created.
        $res->assertCreated()->assertJsonPath('notify.fcm_configured', true)->assertJsonPath('notify.fcm_failed', 1);
        $this->assertDatabaseHas('development_assessments', ['child_id' => $this->childA->id]);
        $this->assertDatabaseHas('notifications', ['user_id' => $this->parentA->id, 'type' => 'development']);
    }
}
