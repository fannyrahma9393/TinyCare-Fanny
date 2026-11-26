<?php

namespace App\Support;

use App\Models\Translation;
use Illuminate\Support\Facades\Cache;

/**
 * Translate a SYSTEM-GENERATED string (notification titles/bodies) using the
 * `translations` DB table as the source, with a mandatory safe fallback.
 *
 * Design rules:
 *  - If the key exists in the DB for the locale, the DB value wins (admins
 *    can reword notification text without a deploy).
 *  - If the key is missing (fresh DB, seeder not run), the caller-provided
 *    Indonesian fallback is returned so behaviour is identical to the
 *    previous hardcoded text — notifications can never render a raw key.
 *  - Placeholders use `{name}` and are replaced from the $replace map.
 *  - The cache key mirrors the public API cache (`translations:{locale}`)
 *    so an admin update invalidates both in one call.
 */
class TransKey
{
    /**
     * Render a translated string for server-generated text.
     *
     * @param  string  $key       stable translation key, e.g. `notif.invoice.created`
     * @param  array<string, string>  $replace   placeholder replacements (`{child_name}` => ...)
     * @param  string|null  $fallback  Indonesian text used when the key is absent from the DB
     * @param  string|null  $locale    recipient locale; null = config('tinycare.trans_notif_locale')
     */
    public static function t(string $key, array $replace = [], ?string $fallback = null, ?string $locale = null): string
    {
        $locale = $locale ?: (string) config('tinycare.trans_notif_locale', 'id');
        $catalog = self::catalog($locale);

        $text = $catalog[$key] ?? null;

        if ($text === null || $text === '') {
            // Safe fallback: keep the exact pre-existing wording. When a
            // fallback is not provided, degrade to the key itself rather
            // than throwing.
            $text = $fallback ?? $key;
        }

        foreach ($replace as $name => $value) {
            $text = str_replace('{'.$name.'}', (string) $value, $text);
        }

        return $text;
    }

    /**
     * Cached key => value catalog for one locale (same cache slot as the API).
     *
     * @return array<string, string>
     */
    public static function catalog(string $locale): array
    {
        $ttl = (int) config('tinycare.translations_cache_ttl', 3600);

        return Cache::remember("translations:{$locale}", $ttl, function () use ($locale) {
            return Translation::query()
                ->where('locale', $locale)
                ->pluck('value', 'key')
                ->all();
        });
    }

    /**
     * Invalidate the cached catalog for one locale (or all supported locales).
     */
    public static function flush(?string $locale = null): void
    {
        $locales = $locale ? [$locale] : (array) config('tinycare.supported_locales', ['id', 'en']);

        foreach ($locales as $loc) {
            Cache::forget("translations:{$loc}");
        }
    }
}
