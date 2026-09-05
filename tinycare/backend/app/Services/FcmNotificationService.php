<?php

namespace App\Services;

use App\Models\FcmToken;
use App\Models\Child;
use App\Models\Notification;
use GuzzleHttp\Client as GuzzleClient;
use Illuminate\Support\Facades\Log;

/**
 * Centralized Firebase Cloud Messaging (FCM) HTTP v1 sender.
 *
 * Responsibilities:
 *  - resolve and send to a user's FCM tokens (multiple device support)
 *  - build + refresh OAuth2 access tokens from a service-account JWT (RS256/openssl)
 *  - detect and delete invalid/unregistered tokens without failing other tokens
 *  - log send diagnostics safely (never secrets/private keys)
 *  - never throw out of a send so the main request does not crash
 */
class FcmNotificationService
{
    private GuzzleClient $http;

    /**
     * Injectable HTTP transport (used by tests to fake the network).
     */
    private $transport;

    /**
     * Global static transport override — used by tests to inject a mock
     * callable that is visible inside the HTTP kernel where app() may
     * resolve a different container scope.
     */
    private static $staticTransport;

    /**
     * Set a global transport override (callable).
     * Pass null to clear.
     */
    public static function setStaticTransport(?callable $transport): void
    {
        self::$staticTransport = $transport;
    }

    /**
     * Cached/forced access token (used by tests to bypass JWT signing).
     */
    private ?string $forcedAccessToken = null;

    /**
     * Cache the OAuth2 access token for the lifetime of a request.
     */
    private ?string $cachedAccessToken = null;

    /**
     * Force a specific access token — primarily used by tests to skip the
     * OAuth2 token exchange / JWT signing.
     */
    public function setAccessToken(?string $token): void
    {
        $this->forcedAccessToken = $token;
    }

    private const SEND_URL = 'https://fcm.googleapis.com/v1/projects/%s/messages:send';
    private const TOKEN_URL = 'https://oauth2.googleapis.com/token';

    public function __construct(?GuzzleClient $http = null, ?callable $transport = null)
    {
        $this->http = $http ?? new GuzzleClient(['timeout' => 10, 'http_errors' => false]);
        $this->transport = $transport;
    }

    /**
     * Whether real credentials are configured.
     */
    public function isConfigured(): bool
    {
        return (bool) config('services.firebase.project_id')
            && (bool) config('services.firebase.client_email')
            && (bool) config('services.firebase.private_key');
    }

    /**
     * Send a notification to every active FCM token of a user.
     *
     * @param  array{title: string, body: string, link?: string, data?: array}  $payload
     * @return array{success: int, failed: int}
     */
    public function sendToUser(?int $userId, string $title, string $body, ?string $link = null, array $data = []): array
    {
        if (! $userId) {
            return ['success' => 0, 'failed' => 0];
        }

        $tokens = FcmToken::where('user_id', $userId)->get();

        return $this->sendToTokens($tokens, $title, $body, $link, $data);
    }

    /**
     * Notify every ACTIVE parent of a child: create an in-app Database
     * notification AND send an FCM push to all of that parent's devices.
     *
     * Targeting is scoped tightly to the parents linked to $child — other
     * parents are never notified. An FCM failure never throws and never aborts
     * the caller: this method only reports the outcome.
     *
     * @param  array{type: string, title: string, message: string, data?: array}  $notif
     * @param  int|null  $onlyParentId  when set, notify only this parent (must belong to the child)
     * @return array{targeted_parents: int, fcm_sent: int, fcm_failed: int, fcm_configured: bool}
     */
    public function notifyChildParents(Child $child, array $notif, string $pushTitle, string $pushBody, ?string $pushLink = null, array $pushData = [], ?int $onlyParentId = null): array
    {
        $parents = $child->parents()->with('user')->get();
        if ($onlyParentId !== null) {
            $parents = $parents->filter(fn ($p) => (int) $p->id === (int) $onlyParentId);
        }

        $targetedParents = 0;
        $fcmSent = 0;
        $fcmFailed = 0;

        foreach ($parents as $parent) {
            if (! $parent->user || $parent->user->status !== 'active') {
                continue;
            }

            Notification::create([
                'user_id' => $parent->user->id,
                'type' => $notif['type'] ?? 'child_information',
                'title' => $notif['title'] ?? '',
                'message' => $notif['message'] ?? '',
                'link' => $notif['link'] ?? '/parent/information',
                'data' => $notif['data'] ?? [],
            ]);

            $targetedParents++;

            $result = $this->sendToUser($parent->user->id, $pushTitle, $pushBody, $pushLink, $pushData);

            $fcmSent += $result['success'];
            $fcmFailed += $result['failed'];
        }

        return [
            'targeted_parents' => $targetedParents,
            'fcm_sent' => $fcmSent,
            'fcm_failed' => $fcmFailed,
            'fcm_configured' => $this->isConfigured(),
        ];
    }

    /**
     * Send a notification to a collection of tokens, handling multi-device and
     * invalid-token cleanup per token.
     *
     * @param  iterable<FcmToken>  $tokens
     */
    public function sendToTokens(iterable $tokens, string $title, string $body, ?string $link = null, array $data = []): array
    {
        $result = ['success' => 0, 'failed' => 0];

        foreach ($tokens as $tokenRow) {
            if ($tokenRow->token) {
                $ok = $this->sendToToken($tokenRow, $title, $body, $link, $data);
                $result[$ok ? 'success' : 'failed']++;
            }
        }

        Log::info('FCM send finished', [
            'success' => $result['success'],
            'failed' => $result['failed'],
        ]);

        return $result;
    }

    /**
     * Send a single message to one stored token, deleting it when invalid.
     */
    public function sendToToken(FcmToken $tokenRow, string $title, string $body, ?string $link = null, array $data = []): bool
    {
        if (! $tokenRow->token) {
            return false;
        }

        if (! $this->isConfigured()) {
            Log::info('FCM send skipped (not configured) — token registered but no Firebase credentials', [
                'user_id' => $tokenRow->user_id,
                'token_id' => $tokenRow->id,
            ]);

            return true;
        }

        Log::info('FCM send started', [
            'user_id' => $tokenRow->user_id,
            'token_id' => $tokenRow->id,
        ]);

        try {
            $accessToken = $this->accessToken();

            $message = [
                'message' => [
                    'token' => $tokenRow->token,
                    'notification' => [
                        'title' => $title,
                        'body' => $body,
                    ],
                    'data' => array_merge([
                        'link' => $link ?? '',
                    ], $data),
                    'webpush' => $link ? [
                        'fcm_options' => [
                            'link' => $link,
                        ],
                    ] : [],
                ],
            ];

            $url = sprintf(self::SEND_URL, config('services.firebase.project_id'));

            $response = $this->performRequest('POST', $url, [
                'json' => $message,
                'headers' => [
                    'Authorization' => 'Bearer '.$accessToken,
                    'Content-Type' => 'application/json; UTF-8',
                ],
            ]);

            $status = $response['status'] ?? 0;
            $bodyText = $response['body'] ?? '';

            if ($status >= 200 && $status < 300) {
                Log::info('FCM send success', [
                    'token_id' => $tokenRow->id,
                    'status' => $status,
                ]);

                return true;
            }

            // Unregistered / invalid token -> clean it up (multi-device must not
            // fail because one device is gone).
            if ($this->isUnregisteredError($status, $bodyText)) {
                Log::warning('FCM token invalid — removing', [
                    'token_id' => $tokenRow->id,
                    'user_id' => $tokenRow->user_id,
                ]);
                $tokenRow->delete();
            } else {
                Log::error('FCM send failed', [
                    'token_id' => $tokenRow->id,
                    'status' => $status,
                    'body' => $this->truncate($bodyText),
                ]);
            }

            return false;
        } catch (\Throwable $e) {
            Log::error('FCM send exception', [
                'token_id' => $tokenRow->id,
                'error' => $e->getMessage(),
            ]);

            return false;
        }
    }

    /**
     * Obtain (or reuse cached) OAuth2 access token for the service account.
     */
    public function accessToken(): string
    {
        if ($this->forcedAccessToken !== null) {
            return $this->forcedAccessToken;
        }

        if ($this->cachedAccessToken !== null) {
            return $this->cachedAccessToken;
        }

        $jwt = $this->createJwt();

        $response = $this->performRequest('POST', self::TOKEN_URL, [
            'form_params' => [
                'grant_type' => 'urn:ietf:params:oauth:grant-type:jwt-bearer',
                'assertion' => $jwt,
            ],
        ]);

        $status = $response['status'] ?? 0;
        $body = $response['body'] ?? '';

        if ($status < 200 || $status >= 300) {
            Log::error('FCM: failed to obtain access token', [
                'status' => $status,
                'body' => $this->truncate($body),
            ]);
            throw new \RuntimeException('FCM access token request failed');
        }

        $decoded = json_decode($body, true);
        $this->cachedAccessToken = $decoded['access_token'] ?? '';

        return $this->cachedAccessToken;
    }

    /**
     * Build an RS256-signed JWT using the service-account private key (openssl).
     */
    public function createJwt(): string
    {
        $clientEmail = config('services.firebase.client_email');
        $privateKey = $this->normalizePrivateKey((string) config('services.firebase.private_key'));

        $now = time();
        $header = ['alg' => 'RS256', 'typ' => 'JWT'];
        $claims = [
            'iss' => $clientEmail,
            'scope' => config('services.firebase.scope'),
            'aud' => self::TOKEN_URL,
            'iat' => $now,
            'exp' => $now + 3600,
        ];

        $encodedHeader = $this->base64UrlEncode(json_encode($header));
        $encodedClaims = $this->base64UrlEncode(json_encode($claims));
        $signingInput = $encodedHeader.'.'.$encodedClaims;

        $signature = '';
        $sign = openssl_sign($signingInput, $signature, $privateKey, OPENSSL_ALGO_SHA256);

        if (! $sign) {
            Log::error('FCM: failed to sign JWT with service-account key');
            throw new \RuntimeException('FCM JWT signing failed');
        }

        return $signingInput.'.'.$this->base64UrlEncode($signature);
    }

    /**
     * The private key in .env is often single-quoted with literal "\n" characters.
     * Normalize "\n" to actual newlines so openssl can parse the PEM.
     */
    private function normalizePrivateKey(string $key): string
    {
        return str_replace('\\n', "\n", $key);
    }

    private function base64UrlEncode(string $data): string
    {
        return rtrim(strtr(base64_encode($data), '+/', '-_'), '=');
    }

    private function isUnregisteredError(int $status, string $body): bool
    {
        if ($status === 404) {
            return true;
        }

        return (bool) preg_match('/UNREGISTERED|NOT_FOUND|registration-token-not-found/i', $body);
    }

    /**
     * Route the actual HTTP call through the transport when test-injected,
     * otherwise through Guzzle.
     *
     * @return array{status: int, body: string}
     */
    private function performRequest(string $method, string $url, array $options): array
    {
        $transport = self::$staticTransport ?? $this->transport;

        if ($transport) {
            return call_user_func($transport, $method, $url, $options);
        }

        $response = $this->http->request($method, $url, $options);

        return [
            'status' => $response->getStatusCode(),
            'body' => (string) $response->getBody(),
        ];
    }

    private function truncate(string $value, int $max = 500): string
    {
        if (mb_strlen($value) <= $max) {
            return $value;
        }

        return mb_substr($value, 0, $max).'...';
    }
}
