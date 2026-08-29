<?php

namespace Tests\Feature;

use App\Models\Admin;
use App\Models\Child;
use App\Models\Invoice;
use App\Models\Package;
use App\Models\ParentModel;
use App\Models\Payment;
use App\Models\Role;
use App\Models\User;
use App\Services\Payment\PaymentService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Storage;
use Tests\TestCase;

class PaymentFlowTest extends TestCase
{
    use RefreshDatabase;

    private User $admin;

    private User $parentUser;

    private ParentModel $parent;

    private Child $child;

    private Package $package;

    private Invoice $pendingInvoice;

    protected function setUp(): void
    {
        parent::setUp();

        config(['services.tinycare.admin_access_code' => 'TEST-ADMIN-CODE']);
        config(['services.payment.provider' => 'manual_transfer']);

        // Create admin
        $adminRole = Role::firstOrCreate(['name' => 'admin'], ['description' => 'Admin']);
        $this->admin = User::create([
            'name' => 'Admin Test',
            'email' => 'admin@test.com',
            'password' => bcrypt('password123'),
            'role_id' => $adminRole->id,
            'status' => 'active',
        ]);
        Admin::create(['user_id' => $this->admin->id, 'position' => 'Manager']);

        // Create parent
        $parentRole = Role::firstOrCreate(['name' => 'parent'], ['description' => 'Parent']);
        $this->parentUser = User::create([
            'name' => 'Parent Test',
            'email' => 'parent@test.com',
            'password' => bcrypt('password123'),
            'role_id' => $parentRole->id,
            'status' => 'active',
        ]);
        $this->parent = ParentModel::create(['user_id' => $this->parentUser->id]);

        // Create child
        $this->child = Child::create([
            'name' => 'Anak Test',
            'birth_date' => '2023-01-15',
            'gender' => 'male',
            'status' => 'active',
        ]);
        $this->child->parents()->attach($this->parent->id);

        // Create package
        $this->package = Package::create([
            'name' => 'Paket Premium',
            'price' => 800000,
            'duration_days' => 30,
            'status' => 'active',
        ]);

        // Create pending invoice
        $this->pendingInvoice = Invoice::create([
            'invoice_number' => 'INV-202608-TEST01',
            'child_id' => $this->child->id,
            'package_id' => $this->package->id,
            'parent_id' => $this->parent->id,
            'subtotal' => 800000,
            'discount' => 0,
            'total' => 800000,
            'due_date' => now()->addDays(14),
            'status' => 'pending',
        ]);
    }

    private function parentToken(): string
    {
        return $this->parentUser->createToken('parent-token')->plainTextToken;
    }

    private function adminToken(): string
    {
        return $this->admin->createToken('admin-token')->plainTextToken;
    }

    /**
     * Helper: create another parent with ParentModel for ownership tests.
     */
    private function createOtherParent(): User
    {
        $role = Role::firstOrCreate(['name' => 'parent'], ['description' => 'Parent']);
        $user = User::create([
            'name' => 'Other Parent',
            'email' => 'other@test.com',
            'password' => bcrypt('password123'),
            'role_id' => $role->id,
            'status' => 'active',
        ]);
        ParentModel::create(['user_id' => $user->id]);

        return $user;
    }

    // ==================== INITIATE PAYMENT TESTS ====================

    public function test_parent_can_initiate_payment(): void
    {
        $response = $this->withHeader('Authorization', 'Bearer '.$this->parentToken())
            ->postJson("/api/v1/parent/invoices/{$this->pendingInvoice->id}/pay", [
                'payment_method' => 'bank_transfer',
            ]);

        $response->assertOk()
            ->assertJson([
                'success' => true,
                'data' => [
                    'va_number' => '8888000001',
                    'bank_name' => 'Bank BCA',
                    'amount' => 800000,
                    'status' => 'pending',
                ],
            ]);

        $this->assertDatabaseHas('payments', [
            'invoice_id' => $this->pendingInvoice->id,
            'status' => 'pending',
            'gateway_provider' => 'manual_transfer',
        ]);
    }

    public function test_payment_creates_transaction_id(): void
    {
        $this->withHeader('Authorization', 'Bearer '.$this->parentToken())
            ->postJson("/api/v1/parent/invoices/{$this->pendingInvoice->id}/pay")
            ->assertOk();

        $payment = Payment::where('invoice_id', $this->pendingInvoice->id)->first();
        $this->assertNotNull($payment->transaction_id);
        $this->assertStringStartsWith('TXN-', $payment->transaction_id);
    }

    public function test_payment_stores_gateway_response(): void
    {
        $this->withHeader('Authorization', 'Bearer '.$this->parentToken())
            ->postJson("/api/v1/parent/invoices/{$this->pendingInvoice->id}/pay")
            ->assertOk();

        $payment = Payment::where('invoice_id', $this->pendingInvoice->id)->first();
        $this->assertNotNull($payment->gateway_response);
        $this->assertEquals('8888000001', $payment->gateway_response['va_number']);
        $this->assertArrayHasKey('instructions', $payment->gateway_response);
    }

    public function test_initiate_payment_returns_instructions(): void
    {
        $response = $this->withHeader('Authorization', 'Bearer '.$this->parentToken())
            ->postJson("/api/v1/parent/invoices/{$this->pendingInvoice->id}/pay");

        $response->assertOk()
            ->assertJsonStructure([
                'data' => ['va_number', 'bank_name', 'account_name', 'amount', 'total_with_code', 'instructions'],
            ]);

        $instructions = $response->json('data.instructions');
        $this->assertArrayHasKey('ATM', $instructions);
        $this->assertArrayHasKey('Mobile Banking', $instructions);
    }

    // ==================== DUPLICATE PREVENTION TESTS ====================

    public function test_duplicate_payment_returns_existing(): void
    {
        $this->withHeader('Authorization', 'Bearer '.$this->parentToken())
            ->postJson("/api/v1/parent/invoices/{$this->pendingInvoice->id}/pay")
            ->assertOk();

        $this->withHeader('Authorization', 'Bearer '.$this->parentToken())
            ->postJson("/api/v1/parent/invoices/{$this->pendingInvoice->id}/pay")
            ->assertOk()
            ->assertJsonPath('data.already_pending', true);

        $this->assertEquals(1, Payment::where('invoice_id', $this->pendingInvoice->id)->count());
    }

    // ==================== PAID INVOICE TESTS ====================

    public function test_cannot_initiate_payment_for_paid_invoice(): void
    {
        $this->pendingInvoice->update(['status' => 'paid']);

        $this->withHeader('Authorization', 'Bearer '.$this->parentToken())
            ->postJson("/api/v1/parent/invoices/{$this->pendingInvoice->id}/pay")
            ->assertStatus(422)
            ->assertJson(['success' => false, 'message' => 'Invoice tidak dapat dibayar saat ini.']);
    }

    public function test_cannot_initiate_payment_for_failed_invoice(): void
    {
        $this->pendingInvoice->update(['status' => 'failed']);

        $this->withHeader('Authorization', 'Bearer '.$this->parentToken())
            ->postJson("/api/v1/parent/invoices/{$this->pendingInvoice->id}/pay")
            ->assertStatus(422);
    }

    public function test_cannot_initiate_payment_for_cancelled_invoice(): void
    {
        $this->pendingInvoice->update(['status' => 'cancelled']);

        $this->withHeader('Authorization', 'Bearer '.$this->parentToken())
            ->postJson("/api/v1/parent/invoices/{$this->pendingInvoice->id}/pay")
            ->assertStatus(422);
    }

    // ==================== OWNERSHIP TESTS ====================

    public function test_parent_cannot_initiate_payment_for_other_parent_invoice(): void
    {
        $other = $this->createOtherParent();

        $this->withHeader('Authorization', 'Bearer '.$other->createToken('t')->plainTextToken)
            ->postJson("/api/v1/parent/invoices/{$this->pendingInvoice->id}/pay")
            ->assertForbidden()
            ->assertJson(['success' => false, 'message' => 'Tidak memiliki akses ke invoice ini.']);
    }

    public function test_parent_cannot_view_other_parent_invoice(): void
    {
        $other = $this->createOtherParent();

        $this->withHeader('Authorization', 'Bearer '.$other->createToken('t')->plainTextToken)
            ->getJson("/api/v1/parent/invoices/{$this->pendingInvoice->id}")
            ->assertForbidden();
    }

    // ==================== CHECK STATUS TESTS ====================

    public function test_parent_can_check_payment_status(): void
    {
        $payment = Payment::create([
            'invoice_id' => $this->pendingInvoice->id,
            'amount' => 800000,
            'status' => 'pending',
            'transaction_id' => 'TXN-TEST123',
            'gateway_provider' => 'manual_transfer',
        ]);

        $this->withHeader('Authorization', 'Bearer '.$this->parentToken())
            ->getJson("/api/v1/parent/payments/{$payment->id}/status")
            ->assertOk()
            ->assertJson(['success' => true, 'data' => ['status' => 'pending', 'paid' => false]]);
    }

    public function test_check_status_shows_verified_after_admin_verify(): void
    {
        $payment = Payment::create([
            'invoice_id' => $this->pendingInvoice->id,
            'amount' => 800000,
            'status' => 'verified',
            'paid_at' => now(),
            'verified_by' => $this->admin->id,
            'verified_at' => now(),
        ]);

        $this->withHeader('Authorization', 'Bearer '.$this->parentToken())
            ->getJson("/api/v1/parent/payments/{$payment->id}/status")
            ->assertOk()
            ->assertJsonPath('data.paid', true)
            ->assertJsonPath('data.status', 'verified');
    }

    // ==================== INVOICE DETAIL TESTS ====================

    public function test_parent_can_get_invoice_detail(): void
    {
        $this->withHeader('Authorization', 'Bearer '.$this->parentToken())
            ->getJson("/api/v1/parent/invoices/{$this->pendingInvoice->id}")
            ->assertOk()
            ->assertJson([
                'success' => true,
                'data' => ['invoice_number' => 'INV-202608-TEST01', 'status' => 'pending', 'total' => 800000],
            ])
            ->assertJsonStructure(['data' => ['child', 'package']]);
    }

    public function test_parent_can_get_invoice_payments(): void
    {
        Payment::create(['invoice_id' => $this->pendingInvoice->id, 'amount' => 800000, 'status' => 'pending']);

        $response = $this->withHeader('Authorization', 'Bearer '.$this->parentToken())
            ->getJson("/api/v1/parent/invoices/{$this->pendingInvoice->id}/payments");

        $response->assertOk()->assertJson(['success' => true]);
        $this->assertCount(1, $response->json('data'));
    }

    // ==================== ADMIN VERIFY / REJECT TESTS ====================

    public function test_admin_can_verify_payment(): void
    {
        $payment = Payment::create([
            'invoice_id' => $this->pendingInvoice->id,
            'amount' => 800000,
            'status' => 'pending',
        ]);

        $this->withHeader('Authorization', 'Bearer '.$this->adminToken())
            ->postJson("/api/v1/admin/payments/{$payment->id}/verify")
            ->assertOk()
            ->assertJson(['success' => true, 'message' => 'Pembayaran berhasil diverifikasi.']);

        $payment->refresh();
        $this->assertEquals('verified', $payment->status);
        $this->assertNotNull($payment->paid_at);

        $this->pendingInvoice->refresh();
        $this->assertEquals('paid', $this->pendingInvoice->status);
    }

    public function test_admin_can_reject_payment(): void
    {
        $payment = Payment::create([
            'invoice_id' => $this->pendingInvoice->id,
            'amount' => 800000,
            'status' => 'pending',
        ]);

        $this->withHeader('Authorization', 'Bearer '.$this->adminToken())
            ->postJson("/api/v1/admin/payments/{$payment->id}/reject", ['reason' => 'Bukti tidak jelas'])
            ->assertOk()
            ->assertJson(['success' => true, 'message' => 'Pembayaran ditolak.']);

        $payment->refresh();
        $this->assertEquals('rejected', $payment->status);

        $this->pendingInvoice->refresh();
        $this->assertEquals('pending', $this->pendingInvoice->status);
    }

    public function test_cannot_verify_already_verified_payment(): void
    {
        $payment = Payment::create([
            'invoice_id' => $this->pendingInvoice->id,
            'amount' => 800000,
            'status' => 'verified',
        ]);

        $this->withHeader('Authorization', 'Bearer '.$this->adminToken())
            ->postJson("/api/v1/admin/payments/{$payment->id}/verify")
            ->assertStatus(400)
            ->assertJson(['success' => false, 'message' => 'Pembayaran sudah diproses.']);
    }

    public function test_cannot_reject_already_rejected_payment(): void
    {
        $payment = Payment::create([
            'invoice_id' => $this->pendingInvoice->id,
            'amount' => 800000,
            'status' => 'rejected',
        ]);

        $this->withHeader('Authorization', 'Bearer '.$this->adminToken())
            ->postJson("/api/v1/admin/payments/{$payment->id}/reject")
            ->assertStatus(400);
    }

    // ==================== PROOF UPLOAD TESTS ====================

    public function test_parent_can_submit_payment_proof(): void
    {
        Storage::fake('local');
        $file = UploadedFile::fake()->create('proof.pdf', 100, 'application/pdf');

        $this->withHeader('Authorization', 'Bearer '.$this->parentToken())
            ->postJson('/api/v1/parent/payments', [
                'invoice_id' => $this->pendingInvoice->id,
                'amount' => 800000,
                'payment_method' => 'bank_transfer',
                'proof_file' => $file,
            ])
            ->assertCreated()
            ->assertJson(['success' => true]);

        $this->assertDatabaseHas('payments', [
            'invoice_id' => $this->pendingInvoice->id,
            'status' => 'pending',
        ]);
    }

    public function test_proof_upload_rejects_wrong_amount(): void
    {
        Storage::fake('local');
        $file = UploadedFile::fake()->create('proof.pdf', 100, 'application/pdf');

        $this->withHeader('Authorization', 'Bearer '.$this->parentToken())
            ->postJson('/api/v1/parent/payments', [
                'invoice_id' => $this->pendingInvoice->id,
                'amount' => 500000,
                'payment_method' => 'bank_transfer',
                'proof_file' => $file,
            ])
            ->assertStatus(400)
            ->assertJson(['success' => false, 'message' => 'Jumlah pembayaran harus sesuai dengan total invoice.']);
    }

    public function test_proof_upload_rejects_invalid_file(): void
    {
        $file = UploadedFile::fake()->create('malware.exe', 100, 'application/x-msdownload');

        $this->withHeader('Authorization', 'Bearer '.$this->parentToken())
            ->postJson('/api/v1/parent/payments', [
                'invoice_id' => $this->pendingInvoice->id,
                'amount' => 800000,
                'proof_file' => $file,
            ])
            ->assertUnprocessable()
            ->assertJsonValidationErrors('proof_file');
    }

    public function test_proof_upload_rejects_file_over_5mb(): void
    {
        $file = UploadedFile::fake()->create('large.pdf', 6000, 'application/pdf');

        $this->withHeader('Authorization', 'Bearer '.$this->parentToken())
            ->postJson('/api/v1/parent/payments', [
                'invoice_id' => $this->pendingInvoice->id,
                'amount' => 800000,
                'proof_file' => $file,
            ])
            ->assertUnprocessable()
            ->assertJsonValidationErrors('proof_file');
    }

    // ==================== EDGE CASE TESTS ====================

    public function test_unauthenticated_user_cannot_initiate_payment(): void
    {
        $this->postJson("/api/v1/parent/invoices/{$this->pendingInvoice->id}/pay")
            ->assertUnauthorized();
    }

    public function test_admin_cannot_initiate_parent_payment(): void
    {
        $this->withHeader('Authorization', 'Bearer '.$this->adminToken())
            ->postJson("/api/v1/parent/invoices/{$this->pendingInvoice->id}/pay")
            ->assertForbidden();
    }

    public function test_verify_marks_invoice_as_paid(): void
    {
        $payment = Payment::create([
            'invoice_id' => $this->pendingInvoice->id,
            'amount' => 800000,
            'status' => 'pending',
        ]);

        $this->assertEquals('pending', $this->pendingInvoice->status);

        $this->withHeader('Authorization', 'Bearer '.$this->adminToken())
            ->postJson("/api/v1/admin/payments/{$payment->id}/verify")
            ->assertOk();

        $this->pendingInvoice->refresh();
        $this->assertEquals('paid', $this->pendingInvoice->status);
    }

    public function test_invoice_cannot_be_paid_twice(): void
    {
        Payment::create([
            'invoice_id' => $this->pendingInvoice->id,
            'amount' => 800000,
            'status' => 'verified',
            'paid_at' => now(),
        ]);
        $this->pendingInvoice->update(['status' => 'paid']);

        $this->withHeader('Authorization', 'Bearer '.$this->parentToken())
            ->postJson("/api/v1/parent/invoices/{$this->pendingInvoice->id}/pay")
            ->assertStatus(422)
            ->assertJson(['success' => false, 'message' => 'Invoice tidak dapat dibayar saat ini.']);

        $this->assertEquals(1, Payment::where('invoice_id', $this->pendingInvoice->id)->count());
    }

    public function test_parent_cannot_submit_proof_for_paid_invoice(): void
    {
        $this->pendingInvoice->update(['status' => 'paid']);

        Storage::fake('local');
        $file = UploadedFile::fake()->create('proof.pdf', 100, 'application/pdf');

        $this->withHeader('Authorization', 'Bearer '.$this->parentToken())
            ->postJson('/api/v1/parent/payments', [
                'invoice_id' => $this->pendingInvoice->id,
                'amount' => 800000,
                'proof_file' => $file,
            ])
            ->assertStatus(400)
            ->assertJson(['success' => false, 'message' => 'Invoice tidak dapat dibayar.']);
    }

    public function test_admin_cannot_verify_rejected_payment(): void
    {
        $payment = Payment::create([
            'invoice_id' => $this->pendingInvoice->id,
            'amount' => 800000,
            'status' => 'rejected',
        ]);

        $this->withHeader('Authorization', 'Bearer '.$this->adminToken())
            ->postJson("/api/v1/admin/payments/{$payment->id}/verify")
            ->assertStatus(400)
            ->assertJson(['success' => false, 'message' => 'Pembayaran sudah diproses.']);
    }

    // ==================== WEBHOOK TESTS ====================

    public function test_webhook_endpoint_exists(): void
    {
        $this->postJson('/api/v1/payments/webhook', [
            'order_id' => 'nonexistent',
            'transaction_status' => 'settlement',
        ])
            ->assertOk()
            ->assertJson(['success' => true]);
    }

    // ==================== PAYMENT SERVICE UNIT TESTS ====================

    public function test_payment_service_creates_correct_va_number(): void
    {
        $service = new PaymentService;
        $result = $service->initiatePayment($this->pendingInvoice);

        $expectedVa = '8888'.str_pad($this->pendingInvoice->id, 6, '0', STR_PAD_LEFT);
        $this->assertEquals($expectedVa, $result['va_number']);
    }

    public function test_payment_service_calculates_unique_digit(): void
    {
        $service = new PaymentService;
        $result = $service->initiatePayment($this->pendingInvoice);

        $uniqueDigit = $this->pendingInvoice->total % 10;
        $this->assertEquals($this->pendingInvoice->total + $uniqueDigit, $result['total_with_code']);
    }

    public function test_payment_service_sets_paid_at_on_verify(): void
    {
        $payment = Payment::create([
            'invoice_id' => $this->pendingInvoice->id,
            'amount' => 800000,
            'status' => 'pending',
        ]);

        $service = new PaymentService;
        $service->verifyPayment($payment, $this->admin->id);

        $payment->refresh();
        $this->assertNotNull($payment->paid_at);
        $this->assertTrue($payment->paid_at->isPast());
    }

    public function test_payment_model_has_gateway_fields(): void
    {
        $payment = Payment::create([
            'invoice_id' => $this->pendingInvoice->id,
            'amount' => 800000,
            'status' => 'pending',
            'transaction_id' => 'TXN-TEST123',
            'gateway_provider' => 'manual_transfer',
            'gateway_response' => ['va_number' => '8888000001', 'bank_name' => 'BCA'],
        ]);

        $this->assertEquals('TXN-TEST123', $payment->transaction_id);
        $this->assertEquals('manual_transfer', $payment->gateway_provider);
        $this->assertEquals('8888000001', $payment->gateway_response['va_number']);
    }

    // ==================== FULL FLOW INTEGRATION TEST ====================

    public function test_full_payment_flow_end_to_end(): void
    {
        $service = new PaymentService;

        // Step 1: Parent initiates payment via API
        $response1 = $this->withHeader('Authorization', 'Bearer '.$this->parentToken())
            ->postJson("/api/v1/parent/invoices/{$this->pendingInvoice->id}/pay");
        $response1->assertOk();
        $paymentId = $response1->json('data.payment_id');
        $this->assertNotNull($paymentId);

        // Step 2: Parent checks status → pending
        $this->withHeader('Authorization', 'Bearer '.$this->parentToken())
            ->getJson("/api/v1/parent/payments/{$paymentId}/status")
            ->assertOk()
            ->assertJsonPath('data.paid', false);

        // Step 3: Parent views invoice → still pending
        $this->withHeader('Authorization', 'Bearer '.$this->parentToken())
            ->getJson("/api/v1/parent/invoices/{$this->pendingInvoice->id}")
            ->assertOk()
            ->assertJsonPath('data.status', 'pending');

        // Step 4: Admin verifies via service
        $payment = Payment::find($paymentId);
        $this->assertNotNull($payment);
        $service->verifyPayment($payment, $this->admin->id);

        // Step 5: Parent checks status → paid
        $this->withHeader('Authorization', 'Bearer '.$this->parentToken())
            ->getJson("/api/v1/parent/payments/{$paymentId}/status")
            ->assertOk()
            ->assertJsonPath('data.paid', true);

        // Step 6: Invoice is now paid
        $this->pendingInvoice->refresh();
        $this->assertEquals('paid', $this->pendingInvoice->status);

        // Step 7: Cannot pay again
        $this->withHeader('Authorization', 'Bearer '.$this->parentToken())
            ->postJson("/api/v1/parent/invoices/{$this->pendingInvoice->id}/pay")
            ->assertStatus(422);
    }
}
