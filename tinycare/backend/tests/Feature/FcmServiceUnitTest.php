<?php

namespace Tests\Feature;

use App\Models\FcmToken;
use App\Models\User;
use App\Services\FcmNotificationService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class FcmServiceUnitTest extends TestCase
{
    use RefreshDatabase;

    public function test_static_transport_is_called_for_send_to_user(): void
    {
        $user = User::create(['name' => 'Test', 'email' => 't@t.com', 'password' => bcrypt('x'), 'role_id' => 1, 'status' => 'active']);
        FcmToken::create(['user_id' => $user->id, 'token' => 'tok-1', 'platform' => 'web', 'last_used_at' => now()]);

        config(['services.firebase.project_id' => 'test-project']);
        config(['services.firebase.client_email' => 'test@test.iam.gserviceaccount.com']);
        config(['services.firebase.private_key' => 'test-key']);

        $service = app(FcmNotificationService::class);
        $service->setAccessToken('fake-access-token');
        $this->assertTrue($service->isConfigured());

        $seen = [];
        $service->setStaticTransport(function ($method, $url, $options) use (&$seen) {
            if (isset($options['json']['message']['token'])) {
                $seen[] = $options['json']['message']['token'];
            }
            return ['status' => 200, 'body' => '{"name":"ok"}'];
        });

        $result = $service->sendToUser($user->id, 'Title', 'Body', '/link');

        $this->assertEquals(['success' => 1, 'failed' => 0], $result);
        $this->assertEquals(['tok-1'], $seen);
        $service->setStaticTransport(null);
    }

    public function test_unconfigured_service_skips_sending(): void
    {
        FcmNotificationService::setStaticTransport(null);
        config(['services.firebase.project_id' => null]);
        config(['services.firebase.client_email' => null]);
        config(['services.firebase.private_key' => null]);

        $user = User::create(['name' => 'Test', 'email' => 't@t.com', 'password' => bcrypt('x'), 'role_id' => 1, 'status' => 'active']);
        FcmToken::create(['user_id' => $user->id, 'token' => 'tok-1', 'platform' => 'web', 'last_used_at' => now()]);

        $service = app(FcmNotificationService::class);
        $this->assertFalse($service->isConfigured());

        $result = $service->sendToUser($user->id, 'Title', 'Body');
        // Even when not configured, it returns success (skips sending gracefully)
        $this->assertEquals(1, $result['success']);
        $service->setStaticTransport(null);
    }
}
