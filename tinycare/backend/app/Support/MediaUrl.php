<?php

namespace App\Support;

use Illuminate\Support\Facades\URL;

/**
 * Generates signed stream URLs for private files.
 *
 * Hostinger's WAF/mod_security blocks direct requests to
 * /storage/*.jpg requests ("Invalid source image"), so files stored in the
 * private local disk are streamed through a dedicated route whose URL does
 * not end with an image extension. The real path is base64url-encoded and
 * the URL is signed with an expiry.
 */
class MediaUrl
{
    public static function temporary(string $path): string
    {
        $encoded = rtrim(strtr(base64_encode($path), '+/', '-_'), '=');

        return URL::temporarySignedRoute(
            'media.stream',
            now()->addMinutes(30),
            ['file' => $encoded]
        );
    }

    public static function decode(string $encoded): ?string
    {
        $path = base64_decode(strtr($encoded, '-_', '+/'), true);

        if ($path === false || $path === '') {
            return null;
        }

        return $path;
    }
}