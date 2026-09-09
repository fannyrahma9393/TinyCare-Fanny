<?php

namespace Tests\Feature;

use App\Models\Admin;
use App\Models\Child;
use App\Models\Feedback;
use App\Models\FcmToken;
use App\Models\Invoice;
use App\Models\Notification;
use App\Models\Package;
use App\Models\ParentModel;
use App\Models\Payment;
use App\Models\Role;
use App\Models\User;
use App\Services\FcmNotificationService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Storage;
use Tests\TestCase;

class FcmEventNotifierTest extends TestCase
{
    use RefreshDatabase;

    private User $admin;

    private User $adminMaster;

    private User $parentA;

    private User $parentB;

    private ParentModel $parentModelA;

    private ParentModel $parentModelB;

    private Child $childA;

    private Child $childB;

    private Package $package;

    protected function setUp(): void
    {
        parent::setUp();
        FcmNotificationService::setStaticTransport(null);
        config(['services.payment.provider' => 'manual_transfer']);

        $adminRole = Role::firstOrCreate(['name' => 'admin'], ['description' => 'Admin']);
        $adminMasterRole = Role::firstOrCreate(['name' => 'admin_master'], ['description' => 'Admin Master']);
        $parentRole = Role::firstOrCreate(['name' => 'parent'], ['description' => 'Parent']);

        $this->admin = User::create([
            'name' => 'Admin',
            'email' => 'admin@test.com',
            'password' => bcrypt('password123'),
            'role_id' => $adminRole->id,
            'status' => 'active',
        ]);
        Admin::create(['user_id' => $this->admin->id, 'position' => 'Manager']);

        $this->adminMaster = User::create([
            'name' => 'Admin Master',
            'email' => 'master@test.com',
            'password' => bcrypt('password123'),
            'role_id' => $adminMasterRole->id,
            'status' => 'active',
        ]);
        Admin::create(['user_id' => $this->adminMaster->id, 'position' => 'Master']);

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

        $this->package = Package::create([
            'name' => 'Paket Premium',
            'price' => 800000,
            'duration_days' => 30,
            'status' => 'active',
        ]);

        // Register an active child-package enrollment for child A so invoice
        // creation passes the "active package" check.
        $this->childA->childPackages()->create([
            'package_id' => $this->package->id,
            'status' => 'active',
            'start_date' => now()->toDateString(),
            'end_date' => now()->addDays(30)->toDateString(),
        ]);
    }

    private function adminToken(User $user): string
    {
        return $user->createToken('admin-token')->plainTextToken;
    }

    private function parentToken(User $user): string
    {
        return $user->createToken('parent-token')->plainTextToken;
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

    private function createTokenRow(User $user, string $token): void
    {
        FcmToken::create(['user_id' => $user->id, 'token' => $token, 'platform' => 'android', 'last_used_at' => now()]);
    }

    // ==================== INVOICE CREATED ====================

    public function test_invoice_creation_notifies_the_invoice_parent_only(): void
    {
        $this->createTokenRow($this->parentA, 'pa-invoice');
        $this->createTokenRow($this->parentB, 'pb-invoice');

        $sent = [];
        $this->bindFcm(function ($method, $url, $options) use (&$sent) {
            if (isset($options['json']['message']['token'])) {
                $sent[] = $options['json']['message']['token'];
            }
            return ['status' => 200, 'body' => '{"name":"ok"}'];
        });

        $res = $this->withHeader('Authorization', 'Bearer '.$this->adminToken($this->admin))
            ->postJson('/api/v1/admin/invoices', [
                'child_id' => $this->childA->id,
                'package_id' => $this->package->id,
                'due_date' => now()->addDays(14)->toDateString(),
            ]);

        $res->assertCreated()->assertJson(['success' => true]);

        // Only parent A's token is targeted — never parent B.
        $this->assertEquals(['pa-invoice'], $sent);
        $this->assertNotContains('pb-invoice', $sent);

        // DB notification created for parent A only.
        $this->assertDatabaseHas('notifications', [
            'user_id' => $this->parentA->id,
            'type' => 'invoice_created',
        ]);
        $this->assertDatabaseMissing('notifications', ['user_id' => $this->parentB->id]);
    }

    // ==================== PAYMENT SUBMITTED ====================

    public function test_payment_submission_notifies_active_admins(): void
    {
        Storage::fake('local');

        $invoice = $this->makeInvoice($this->parentModelA);
        $this->createTokenRow($this->admin, 'admin-pay');
        $this->createTokenRow($this->adminMaster, 'master-pay');
        $this->createTokenRow($this->parentB, 'other-pay');

        $sent = [];
        $this->bindFcm(function ($method, $url, $options) use (&$sent) {
            if (isset($options['json']['message']['token'])) {
                $sent[] = $options['json']['message']['token'];
            }
            return ['status' => 200, 'body' => '{"name":"ok"}'];
        });

        $file = UploadedFile::fake()->create('proof.pdf', 100, 'application/pdf');

        $res = $this->withHeader('Authorization', 'Bearer '.$this->parentToken($this->parentA))
            ->postJson('/api/v1/parent/payments', [
                'invoice_id' => $invoice->id,
                'amount' => $invoice->total,
                'payment_method' => 'bank_transfer',
                'proof_file' => $file,
            ]);

        $res->assertCreated();

        // Both admins (admin + admin_master) get the push; other parents do not.
        $this->assertEqualsCanonicalizing(['admin-pay', 'master-pay'], $sent);
        $this->assertNotContains('other-pay', $sent);

        // DB notifications for both admins.
        $this->assertDatabaseHas('notifications', [
            'user_id' => $this->admin->id,
            'type' => 'payment_submitted',
        ]);
        $this->assertDatabaseHas('notifications', [
            'user_id' => $this->adminMaster->id,
            'type' => 'payment_submitted',
        ]);
        $this->assertDatabaseMissing('notifications', ['user_id' => $this->parentB->id]);
    }

    public function test_payment_submission_does_not_notify_inactive_admin(): void
    {
        Storage::fake('local');

        $inactiveRole = Role::firstOrCreate(['name' => 'admin'], ['description' => 'Admin']);
        $inactiveAdmin = User::create([
            'name' => 'Inactive Admin',
            'email' => 'inactive@test.com',
            'password' => bcrypt('password123'),
            'role_id' => $inactiveRole->id,
            'status' => 'inactive',
        ]);
        Admin::create(['user_id' => $inactiveAdmin->id, 'position' => 'X']);
        $this->createTokenRow($inactiveAdmin, 'inactive-token');
        $this->createTokenRow($this->admin, 'active-token');

        $invoice = $this->makeInvoice($this->parentModelA);

        $sent = [];
        $this->bindFcm(function ($method, $url, $options) use (&$sent) {
            if (isset($options['json']['message']['token'])) {
                $sent[] = $options['json']['message']['token'];
            }
            return ['status' => 200, 'body' => '{"name":"ok"}'];
        });

        $file = UploadedFile::fake()->create('proof.pdf', 100, 'application/pdf');

        $this->withHeader('Authorization', 'Bearer '.$this->parentToken($this->parentA))
            ->postJson('/api/v1/parent/payments', [
                'invoice_id' => $invoice->id,
                'amount' => $invoice->total,
                'proof_file' => $file,
            ])
            ->assertCreated();

        // Only the active admin receives the push.
        $this->assertEquals(['active-token'], $sent);
        $this->assertNotContains('inactive-token', $sent);
        $this->assertDatabaseMissing('notifications', ['user_id' => $inactiveAdmin->id]);
    }

    // ==================== PAYMENT VERIFIED / REJECTED ====================

    public function test_payment_verified_notifies_the_invoice_parent(): void
    {
        $invoice = $this->makeInvoice($this->parentModelA);
        $payment = Payment::create([
            'invoice_id' => $invoice->id,
            'amount' => $invoice->total,
            'status' => 'pending',
        ]);

        $this->createTokenRow($this->parentA, 'pa-verify');
        $this->createTokenRow($this->parentB, 'pb-verify');

        $sent = [];
        $this->bindFcm(function ($method, $url, $options) use (&$sent) {
            if (isset($options['json']['message']['token'])) {
                $sent[] = $options['json']['message']['token'];
            }
            return ['status' => 200, 'body' => '{"name":"ok"}'];
        });

        $this->withHeader('Authorization', 'Bearer '.$this->adminToken($this->admin))
            ->postJson("/api/v1/admin/payments/{$payment->id}/verify")
            ->assertOk();

        // Only the owning parent receives the push.
        $this->assertEquals(['pa-verify'], $sent);
        $this->assertNotContains('pb-verify', $sent);

        $this->assertDatabaseHas('notifications', [
            'user_id' => $this->parentA->id,
            'type' => 'payment_verified',
        ]);
        $this->assertDatabaseMissing('notifications', ['user_id' => $this->parentB->id]);
    }

    public function test_payment_rejected_notifies_the_invoice_parent_with_reason(): void
    {
        $invoice = $this->makeInvoice($this->parentModelA);
        $payment = Payment::create([
            'invoice_id' => $invoice->id,
            'amount' => $invoice->total,
            'status' => 'pending',
        ]);

        $this->createTokenRow($this->parentA, 'pa-reject');

        $sent = [];
        $this->bindFcm(function ($method, $url, $options) use (&$sent) {
            if (isset($options['json']['message']['token'])) {
                $sent[] = $options['json']['message']['token'];
            }
            return ['status' => 200, 'body' => '{"name":"ok"}'];
        });

        $reason = 'Bukti tidak jelas. Mohon unggah ulang.';

        $this->withHeader('Authorization', 'Bearer '.$this->adminToken($this->admin))
            ->postJson("/api/v1/admin/payments/{$payment->id}/reject", ['reason' => $reason])
            ->assertOk();

        $this->assertEquals(['pa-reject'], $sent);

        $notif = Notification::where('user_id', $this->parentA->id)
            ->where('type', 'payment_rejected')
            ->first();
        $this->assertNotNull($notif);
        $this->assertStringContainsString('Bukti tidak jelas', $notif->message);
    }

    // ==================== FEEDBACK CREATED ====================

    public function test_feedback_creation_notifies_active_admins(): void
    {
        $this->createTokenRow($this->admin, 'admin-fb');
        $this->createTokenRow($this->adminMaster, 'master-fb');
        $this->createTokenRow($this->parentB, 'other-fb');

        $sent = [];
        $this->bindFcm(function ($method, $url, $options) use (&$sent) {
            if (isset($options['json']['message']['token'])) {
                $sent[] = $options['json']['message']['token'];
            }
            return ['status' => 200, 'body' => '{"name":"ok"}'];
        });

        $this->withHeader('Authorization', 'Bearer '.$this->parentToken($this->parentA))
            ->postJson('/api/v1/parent/feedback', [
                'subject' => 'Saran fasilitas',
                'message' => 'Mohon tambah mainan outdoor.',
                'rating' => 5,
            ])
            ->assertCreated();

        $this->assertEqualsCanonicalizing(['admin-fb', 'master-fb'], $sent);
        $this->assertNotContains('other-fb', $sent);

        $this->assertDatabaseHas('notifications', [
            'user_id' => $this->admin->id,
            'type' => 'feedback_created',
        ]);
        $this->assertDatabaseHas('notifications', [
            'user_id' => $this->adminMaster->id,
            'type' => 'feedback_created',
        ]);
        $this->assertDatabaseMissing('notifications', ['user_id' => $this->parentB->id]);
    }

    // ==================== FEEDBACK REPLIED ====================

    public function test_feedback_reply_notifies_the_feedback_parent(): void
    {
        $feedback = Feedback::create([
            'parent_id' => $this->parentModelA->id,
            'child_id' => $this->childA->id,
            'subject' => 'Pertanyaan biaya',
            'message' => 'Berapa biaya bulan depan?',
            'rating' => 4,
            'status' => 'pending',
        ]);

        $this->createTokenRow($this->parentA, 'pa-fb-reply');
        $this->createTokenRow($this->parentB, 'pb-fb-reply');

        $sent = [];
        $this->bindFcm(function ($method, $url, $options) use (&$sent) {
            if (isset($options['json']['message']['token'])) {
                $sent[] = $options['json']['message']['token'];
            }
            return ['status' => 200, 'body' => '{"name":"ok"}'];
        });

        $this->withHeader('Authorization', 'Bearer '.$this->adminToken($this->admin))
            ->postJson("/api/v1/admin/feedback/{$feedback->id}/respond", [
                'admin_response' => 'Biaya bulan depan 900.000.',
            ])
            ->assertOk();

        // Only the feedback owner's parent receives the reply push.
        $this->assertEquals(['pa-fb-reply'], $sent);
        $this->assertNotContains('pb-fb-reply', $sent);

        $this->assertDatabaseHas('notifications', [
            'user_id' => $this->parentA->id,
            'type' => 'feedback_replied',
        ]);
        $this->assertDatabaseMissing('notifications', ['user_id' => $this->parentB->id]);
    }

    // ==================== DUPLICATE PREVENTION ====================

    public function test_single_payment_submission_creates_one_logical_notification_per_admin(): void
    {
        Storage::fake('local');

        $invoice = $this->makeInvoice($this->parentModelA);

        $sent = [];
        $this->bindFcm(function ($method, $url, $options) use (&$sent) {
            if (isset($options['json']['message']['token'])) {
                $sent[] = $options['json']['message']['token'];
            }
            return ['status' => 200, 'body' => '{"name":"ok"}'];
        });

        $file = UploadedFile::fake()->create('proof.pdf', 100, 'application/pdf');

        $this->withHeader('Authorization', 'Bearer '.$this->parentToken($this->parentA))
            ->postJson('/api/v1/parent/payments', [
                'invoice_id' => $invoice->id,
                'amount' => $invoice->total,
                'proof_file' => $file,
            ])
            ->assertCreated();

        // Exactly one DB notification per admin.
        $this->assertSame(1, Notification::where('user_id', $this->admin->id)
            ->where('type', 'payment_submitted')->count());
        $this->assertSame(1, Notification::where('user_id', $this->adminMaster->id)
            ->where('type', 'payment_submitted')->count());
    }

    // ==================== AUTHORIZATION ====================

    public function test_parent_cannot_read_invoice_of_another_parent(): void
    {
        $invoice = $this->makeInvoice($this->parentModelA);

        // Parent B tries to read Parent A's invoice -> 403.
        $this->withHeader('Authorization', 'Bearer '.$this->parentToken($this->parentB))
            ->getJson("/api/v1/parent/invoices/{$invoice->id}")
            ->assertForbidden();
    }

    public function test_parent_cannot_read_payment_of_another_parent(): void
    {
        $invoice = $this->makeInvoice($this->parentModelA);
        $payment = Payment::create([
            'invoice_id' => $invoice->id,
            'amount' => $invoice->total,
            'status' => 'pending',
        ]);

        $this->withHeader('Authorization', 'Bearer '.$this->parentToken($this->parentB))
            ->getJson("/api/v1/parent/payments/{$payment->id}/status")
            ->assertForbidden();
    }

    public function test_parent_cannot_read_feedback_of_another_parent(): void
    {
        Feedback::create([
            'parent_id' => $this->parentModelA->id,
            'subject' => 'Private feedback',
            'message' => 'Hanya untuk admin.',
            'status' => 'pending',
        ]);

        $res = $this->withHeader('Authorization', 'Bearer '.$this->parentToken($this->parentB))
            ->getJson('/api/v1/parent/feedback');

        $res->assertOk();
        $this->assertCount(0, $res->json('data.data'));
    }

    // ==================== HELPERS ====================

    private function makeInvoice(ParentModel $parent): Invoice
    {
        return Invoice::create([
            'invoice_number' => 'INV-'.uniqid(),
            'child_id' => $parent->children()->first()->id,
            'package_id' => $this->package->id,
            'parent_id' => $parent->id,
            'subtotal' => 800000,
            'discount' => 0,
            'total' => 800000,
            'due_date' => now()->addDays(14),
            'status' => 'pending',
        ]);
    }
}