<?php

namespace Tests\Feature;

use App\Models\Admin;
use App\Models\Announcement;
use App\Models\Child;
use App\Models\FcmToken;
use App\Models\Notification;
use App\Models\ParentModel;
use App\Models\Role;
use App\Models\User;
use App\Services\FcmNotificationService;
use Carbon\Carbon;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class AnnouncementTargetingTest extends TestCase
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

    /**
     * Bind a configured FcmNotificationService with a mock transport callable.
     */
    private function bindFcm(callable $transport): void
    {
        config(['services.firebase.project_id' => 'tinycare-test']);
        config(['services.firebase.client_email' => 'test@tinycare-test.iam.gserviceaccount.com']);
        config(['services.firebase.private_key' => 'test-private-key']);

        $service = new FcmNotificationService(null, $transport);
        $service->setAccessToken('test-access-token');

        $this->app->instance(FcmNotificationService::class, $service);

        FcmNotificationService::setStaticTransport($transport);
    }

    public function test_publish_with_child_ids_notifies_only_targeted_parent(): void
    {
        FcmToken::create(['user_id' => $this->parentA->id, 'token' => 'a-token', 'platform' => 'web', 'last_used_at' => now()]);
        FcmToken::create(['user_id' => $this->parentB->id, 'token' => 'b-token', 'platform' => 'web', 'last_used_at' => now()]);

        $sent = [];
        $this->bindFcm(function ($method, $url, $options) use (&$sent) {
            if (isset($options['json']['message']['token'])) {
                $sent[] = $options['json']['message']['token'];
            }
            return ['status' => 200, 'body' => '{"name":"ok"}'];
        });

        $res = $this->withHeader('Authorization', 'Bearer '.$this->adminToken())
            ->postJson('/api/v1/admin/announcements', [
                'title' => 'Anak sakit',
                'content' => 'Ananda Budi sedang demam, mohon doa.',
                'priority' => 'urgent',
                'is_published' => true,
                'child_ids' => [$this->childA->id],
            ]);

        $res->assertCreated()
            ->assertJsonPath('notify.targeted_parents', 1)
            ->assertJsonPath('notify.fcm_sent', 1)
            ->assertJsonPath('notify.fcm_failed', 0);

        // Only parent A's token used.
        $this->assertEquals(['a-token'], $sent);
        $this->assertNotContains('b-token', $sent);

        // Pivot row stored so the targeted children are persisted.
        $this->assertDatabaseHas('announcement_child', [
            'announcement_id' => $res->json('data.id'),
            'child_id' => $this->childA->id,
        ]);

        // DB notification only for parent A.
        $this->assertDatabaseHas('notifications', [
            'user_id' => $this->parentA->id,
            'type' => 'announcement',
        ]);
        $this->assertDatabaseMissing('notifications', ['user_id' => $this->parentB->id]);
    }

    public function test_same_parent_with_multiple_targeted_children_is_notified_once(): void
    {
        $childC = Child::create([
            'name' => 'Cici',
            'birth_date' => '2022-03-01',
            'gender' => 'female',
            'status' => 'active',
        ]);
        $this->parentModelA->children()->attach($childC->id);

        FcmToken::create(['user_id' => $this->parentA->id, 'token' => 'a-token', 'platform' => 'web', 'last_used_at' => now()]);

        $sent = [];
        $this->bindFcm(function ($method, $url, $options) use (&$sent) {
            if (isset($options['json']['message']['token'])) {
                $sent[] = $options['json']['message']['token'];
            }
            return ['status' => 200, 'body' => '{"name":"ok"}'];
        });

        $res = $this->withHeader('Authorization', 'Bearer '.$this->adminToken())
            ->postJson('/api/v1/admin/announcements', [
                'title' => 'Jadwal berubah',
                'content' => 'Jadwal kegiatan minggu ini berubah.',
                'is_published' => true,
                'child_ids' => [$this->childA->id, $childC->id],
            ]);

        // Two targeted children, but ONE parent -> one DB notification + one FCM.
        $res->assertCreated()->assertJsonPath('notify.targeted_parents', 1);

        $this->assertDatabaseCount('notifications', 1);
        $this->assertCount(1, $sent);
    }

    public function test_publish_without_child_ids_broadcasts_to_all_active_parents(): void
    {
        FcmToken::create(['user_id' => $this->parentA->id, 'token' => 'a-token', 'platform' => 'web', 'last_used_at' => now()]);
        FcmToken::create(['user_id' => $this->parentB->id, 'token' => 'b-token', 'platform' => 'web', 'last_used_at' => now()]);

        $sent = [];
        $this->bindFcm(function ($method, $url, $options) use (&$sent) {
            if (isset($options['json']['message']['token'])) {
                $sent[] = $options['json']['message']['token'];
            }
            return ['status' => 200, 'body' => '{"name":"ok"}'];
        });

        $res = $this->withHeader('Authorization', 'Bearer '.$this->adminToken())
            ->postJson('/api/v1/admin/announcements', [
                'title' => 'Libur',
                'content' => 'Daycare tutup sementara.',
                'is_published' => true,
            ]);

        $res->assertCreated()->assertJsonPath('notify.targeted_parents', 2);

        $this->assertEqualsCanonicalizing(['a-token', 'b-token'], $sent);
        $this->assertDatabaseCount('notifications', 2);
        $this->assertDatabaseCount('announcement_child', 0);
    }

    public function test_invalid_child_id_is_rejected(): void
    {
        $res = $this->withHeader('Authorization', 'Bearer '.$this->adminToken())
            ->postJson('/api/v1/admin/announcements', [
                'title' => 'X',
                'content' => 'Y',
                'is_published' => true,
                'child_ids' => [9999],
            ]);

        $res->assertStatus(422)
            ->assertJsonValidationErrors('child_ids.0');

        $this->assertDatabaseCount('announcements', 0);
    }

    public function test_update_from_draft_to_published_notifies_new_targets(): void
    {
        FcmToken::create(['user_id' => $this->parentA->id, 'token' => 'a-token', 'platform' => 'web', 'last_used_at' => now()]);

        $announcement = Announcement::create([
            'title' => 'Draft',
            'content' => 'Belum jadi.',
            'is_published' => false,
            'created_by' => $this->admin->id,
        ]);

        $sent = [];
        $this->bindFcm(function ($method, $url, $options) use (&$sent) {
            if (isset($options['json']['message']['token'])) {
                $sent[] = $options['json']['message']['token'];
            }
            return ['status' => 200, 'body' => '{"name":"ok"}'];
        });

        $res = $this->withHeader('Authorization', 'Bearer '.$this->adminToken())
            ->putJson('/api/v1/admin/announcements/'.$announcement->id, [
                'title' => 'Final',
                'content' => 'Jadi.',
                'is_published' => true,
                'child_ids' => [$this->childA->id],
            ]);

        $res->assertOk()->assertJsonPath('notify.targeted_parents', 1);
        $this->assertEquals(['a-token'], $sent);

        $this->assertDatabaseHas('announcement_child', [
            'announcement_id' => $announcement->id,
            'child_id' => $this->childA->id,
        ]);

        $this->assertDatabaseHas('notifications', [
            'user_id' => $this->parentA->id,
            'type' => 'announcement',
        ]);
    }

    public function test_admin_index_returns_targeted_children(): void
    {
        $announcement = Announcement::create([
            'title' => 'Target',
            'content' => 'Halo',
            'is_published' => true,
            'created_by' => $this->admin->id,
        ]);
        $announcement->children()->attach([$this->childA->id]);

        $res = $this->withHeader('Authorization', 'Bearer '.$this->adminToken())
            ->getJson('/api/v1/admin/announcements');

        $res->assertOk();
        $item = collect($res->json('data.data'))->firstWhere('id', $announcement->id);
        $this->assertNotNull($item);
        $this->assertEquals([$this->childA->id], array_column($item['children'], 'id'));
    }

    public function test_publish_with_parent_ids_notifies_only_selected_parent(): void
    {
        FcmToken::create(['user_id' => $this->parentA->id, 'token' => 'a-token', 'platform' => 'web', 'last_used_at' => now()]);
        FcmToken::create(['user_id' => $this->parentB->id, 'token' => 'b-token', 'platform' => 'web', 'last_used_at' => now()]);

        $sent = [];
        $this->bindFcm(function ($method, $url, $options) use (&$sent) {
            if (isset($options['json']['message']['token'])) {
                $sent[] = $options['json']['message']['token'];
            }
            return ['status' => 200, 'body' => '{"name":"ok"}'];
        });

        $res = $this->withHeader('Authorization', 'Bearer '.$this->adminToken())
            ->postJson('/api/v1/admin/announcements', [
                'title' => 'Khusus A',
                'content' => 'Undangan rapat orang tua kelas A.',
                'is_published' => true,
                'parent_ids' => [$this->parentModelA->id],
            ]);

        $res->assertCreated()
            ->assertJsonPath('notify.targeted_parents', 1)
            ->assertJsonPath('notify.fcm_sent', 1)
            ->assertJsonPath('notify.fcm_failed', 0);

        // Only parent A's token used.
        $this->assertEquals(['a-token'], $sent);
        $this->assertNotContains('b-token', $sent);

        // Pivot row stored so the targeted parent is persisted.
        $this->assertDatabaseHas('announcement_parent', [
            'announcement_id' => $res->json('data.id'),
            'parent_id' => $this->parentModelA->id,
        ]);

        // DB notification only for parent A.
        $this->assertDatabaseHas('notifications', [
            'user_id' => $this->parentA->id,
            'type' => 'announcement',
        ]);
        $this->assertDatabaseMissing('notifications', ['user_id' => $this->parentB->id]);
    }

    public function test_invalid_parent_id_is_rejected(): void
    {
        $res = $this->withHeader('Authorization', 'Bearer '.$this->adminToken())
            ->postJson('/api/v1/admin/announcements', [
                'title' => 'X',
                'content' => 'Y',
                'is_published' => true,
                'parent_ids' => [9999],
            ]);

        $res->assertStatus(422)
            ->assertJsonValidationErrors('parent_ids.0');

        $this->assertDatabaseCount('announcements', 0);
    }

    /**
     * Build the announcements fixture used by the visibility tests.
     *
     * @return array<string, Announcement>
     */
    private function visibilityFixture(): array
    {
        $broadcast = Announcement::create([
            'title' => 'Umum',
            'content' => 'Untuk semua.',
            'is_published' => true,
            'created_by' => $this->admin->id,
        ]);

        $targetedA = Announcement::create([
            'title' => 'Khusus A',
            'content' => 'Hanya parent A.',
            'is_published' => true,
            'created_by' => $this->admin->id,
        ]);
        $targetedA->parents()->attach($this->parentModelA->id);

        $targetedB = Announcement::create([
            'title' => 'Khusus B',
            'content' => 'Hanya parent B.',
            'is_published' => true,
            'created_by' => $this->admin->id,
        ]);
        $targetedB->parents()->attach($this->parentModelB->id);

        $targetedByChild = Announcement::create([
            'title' => 'Lewat anak',
            'content' => 'Target anak A.',
            'is_published' => true,
            'created_by' => $this->admin->id,
        ]);
        $targetedByChild->children()->attach($this->childA->id);

        $draft = Announcement::create([
            'title' => 'Draft',
            'content' => 'Belum publish.',
            'is_published' => false,
            'created_by' => $this->admin->id,
        ]);

        $expired = Announcement::create([
            'title' => 'Expired',
            'content' => 'Sudah lewat.',
            'is_published' => true,
            'expire_date' => Carbon::today()->subDay(),
            'created_by' => $this->admin->id,
        ]);

        // Expires today -> must still be visible for the whole day.
        $expiresToday = Announcement::create([
            'title' => 'Habis Hari Ini',
            'content' => 'Masih tampil hari ini.',
            'is_published' => true,
            'expire_date' => Carbon::today(),
            'created_by' => $this->admin->id,
        ]);

        return compact('broadcast', 'targetedA', 'targetedB', 'targetedByChild', 'draft', 'expired', 'expiresToday');
    }

    public function test_parent_a_visibility_broadcast_and_own_targets_only(): void
    {
        $f = $this->visibilityFixture();

        $res = $this->withHeader('Authorization', 'Bearer '.$this->parentA->createToken('a')->plainTextToken)
            ->getJson('/api/v1/parent/announcements');
        $res->assertOk();
        $ids = collect($res->json('data.data'))->pluck('id')->all();

        $this->assertContains($f['broadcast']->id, $ids);
        $this->assertContains($f['targetedA']->id, $ids);
        $this->assertContains($f['targetedByChild']->id, $ids);
        $this->assertContains($f['expiresToday']->id, $ids);
        $this->assertNotContains($f['targetedB']->id, $ids);
        $this->assertNotContains($f['draft']->id, $ids);
        $this->assertNotContains($f['expired']->id, $ids);
    }

    public function test_parent_b_visibility_broadcast_and_own_targets_only(): void
    {
        $f = $this->visibilityFixture();

        $res = $this->withHeader('Authorization', 'Bearer '.$this->parentB->createToken('b')->plainTextToken)
            ->getJson('/api/v1/parent/announcements');
        $res->assertOk();
        $ids = collect($res->json('data.data'))->pluck('id')->all();

        $this->assertContains($f['broadcast']->id, $ids);
        $this->assertContains($f['targetedB']->id, $ids);
        $this->assertNotContains($f['targetedA']->id, $ids);
        $this->assertNotContains($f['targetedByChild']->id, $ids);
    }

    public function test_parent_can_open_own_announcement_detail(): void
    {
        $targetedA = Announcement::create([
            'title' => 'Khusus A',
            'content' => 'Hanya parent A.',
            'is_published' => true,
            'created_by' => $this->admin->id,
        ]);
        $targetedA->parents()->attach($this->parentModelA->id);

        $this->withHeader('Authorization', 'Bearer '.$this->parentA->createToken('a')->plainTextToken)
            ->getJson('/api/v1/parent/announcements/'.$targetedA->id)
            ->assertOk()
            ->assertJsonPath('data.id', $targetedA->id);
    }

    public function test_parent_cannot_open_other_parent_announcement_detail(): void
    {
        $targetedA = Announcement::create([
            'title' => 'Khusus A',
            'content' => 'Hanya parent A.',
            'is_published' => true,
            'created_by' => $this->admin->id,
        ]);
        $targetedA->parents()->attach($this->parentModelA->id);

        $this->withHeader('Authorization', 'Bearer '.$this->parentB->createToken('b')->plainTextToken)
            ->getJson('/api/v1/parent/announcements/'.$targetedA->id)
            ->assertNotFound();
    }

    public function test_announcement_expiring_today_is_still_active(): void
    {
        $announcement = Announcement::create([
            'title' => 'Hari Ini',
            'content' => 'Berlaku sampai akhir hari.',
            'is_published' => true,
            'publish_date' => Carbon::today(),
            'expire_date' => Carbon::today(),
            'created_by' => $this->admin->id,
        ]);

        $this->assertTrue($announcement->isActive());

        $res = $this->withHeader('Authorization', 'Bearer '.$this->parentA->createToken('a')->plainTextToken)
            ->getJson('/api/v1/parent/announcements');

        $res->assertOk();
        $this->assertContains($announcement->id, collect($res->json('data.data'))->pluck('id')->all());
    }
}