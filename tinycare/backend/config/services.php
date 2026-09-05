<?php

return [

    /*
    |--------------------------------------------------------------------------
    | Third Party Services
    |--------------------------------------------------------------------------
    |
    | This file is for storing the credentials for third party services such
    | as Resend, Postmark, AWS, and more. This file provides the de facto
    | location for this type of information, allowing packages to have
    | a conventional file to locate the various service credentials.
    |
    */

    'postmark' => [
        'key' => env('POSTMARK_API_KEY'),
    ],

    'resend' => [
        'key' => env('RESEND_API_KEY'),
    ],

    'ses' => [
        'key' => env('AWS_ACCESS_KEY_ID'),
        'secret' => env('AWS_SECRET_ACCESS_KEY'),
        'region' => env('AWS_DEFAULT_REGION', 'us-east-1'),
    ],

    'slack' => [
        'notifications' => [
            'bot_user_oauth_token' => env('SLACK_BOT_USER_OAUTH_TOKEN'),
            'channel' => env('SLACK_BOT_USER_DEFAULT_CHANNEL'),
        ],
    ],

    'tinycare' => [
        'admin_access_code' => env('TINYCARE_ADMIN_ACCESS_CODE'),
    ],

    'payment' => [
        'provider' => env('PAYMENT_PROVIDER', 'manual_transfer'),
        'server_key' => env('PAYMENT_SERVER_KEY'),
        'client_key' => env('PAYMENT_CLIENT_KEY'),
        'merchant_id' => env('PAYMENT_MERCHANT_ID'),
        'is_sandbox' => env('PAYMENT_IS_SANDBOX', true),
        'webhook_secret' => env('PAYMENT_WEBHOOK_SECRET'),
    ],

    /*
    |--------------------------------------------------------------------------
    | Firebase Cloud Messaging (FCM)
    |--------------------------------------------------------------------------
    |
    | FCM HTTP v1 sender built on Guzzle (already a Laravel dependency) using a
    | Google service-account JWT. Credentials are provided via environment
    | variables and are NEVER committed. When credentials are absent, messages
    | are logged instead of sent so the request never crashes.
    |
    */
    'firebase' => [
        'project_id' => env('FIREBASE_PROJECT_ID'),
        'client_email' => env('FIREBASE_CLIENT_EMAIL'),
        'private_key' => env('FIREBASE_PRIVATE_KEY'),
        'scope' => 'https://www.googleapis.com/auth/firebase.messaging',
    ],

];
