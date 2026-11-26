<?php

return [

    /*
    |--------------------------------------------------------------------------
    | Server-generated Notification Locale
    |--------------------------------------------------------------------------
    |
    | Locale used when rendering SYSTEM-GENERATED notification text (FCM push
    | titles/bodies and in-app notification rows) via App\Support\TransKey.
    |
    | `users.locale` is intentionally NOT introduced in this phase, so the
    | backend does not know each recipient's device language. The default is
    | Bahasa Indonesia ('id'). When a per-user locale is added later, the
    | helper already accepts an explicit $locale argument — pass the
    | recipient's locale at each call site without changing the design.
    |
    */

    'trans_notif_locale' => env('TRANS_NOTIF_LOCALE', 'id'),

    /*
    |--------------------------------------------------------------------------
    | Supported Client Locales
    |--------------------------------------------------------------------------
    |
    | The only locales accepted by the translations API and writable through
    | the admin endpoints.
    |
    */

    'supported_locales' => ['id', 'en'],

    /*
    |--------------------------------------------------------------------------
    | Translation Cache TTL (seconds)
    |--------------------------------------------------------------------------
    */

    'translations_cache_ttl' => 3600,

];
