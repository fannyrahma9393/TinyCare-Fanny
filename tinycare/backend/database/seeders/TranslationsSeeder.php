<?php

namespace Database\Seeders;

use App\Models\Translation;
use App\Support\TransKey;
use Illuminate\Database\Seeder;

/**
 * Seeds the `translations` table with a BASELINE generated from the static
 * client catalogs (Web `src/locales/partials/*` + Mobile `lib/l10n/partials/*`)
 * plus the `notif.*` system-notification keys.
 *
 * Rules:
 *  - Idempotent + non-destructive: existing rows are NEVER overwritten
 *    (firstOrCreate on key+locale). Re-running only fills gaps.
 *  - For UI strings the Indonesian value equals the key itself (the existing
 *    clients use the Indonesian source text as the key), so `locale=id`
 *    rows are passthrough — they exist so the admin can also reword the
 *    Indonesian wording from the Translation Management page.
 *  - Client static catalogs remain untouched and keep working as fallback.
 */
class TranslationsSeeder extends Seeder
{
    public function run(): void
    {
        $path = database_path('seeders/data/translations-baseline.json');

        if (! is_file($path)) {
            $this->command?->warn('translations-baseline.json not found — skipping baseline seed.');

            return;
        }

        $payload = json_decode((string) file_get_contents($path), true);
        $rows = $payload['rows'] ?? [];

        $created = 0;

        foreach ($rows as $row) {
            $key = (string) $row['key'];

            if ($key === '') {
                continue;
            }

            // Indonesian baseline (passthrough of the key for UI strings).
            $existed = Translation::where('key', $key)->where('locale', 'id')->exists();
            if (! $existed) {
                Translation::create(['key' => $key, 'locale' => 'id', 'value' => (string) $row['id']]);
                $created++;
            }

            // English baseline.
            if (array_key_exists('en', $row) && $row['en'] !== null && $row['en'] !== '') {
                $existed = Translation::where('key', $key)->where('locale', 'en')->exists();
                if (! $existed) {
                    Translation::create(['key' => $key, 'locale' => 'en', 'value' => (string) $row['en']]);
                    $created++;
                }
            }
        }

        // Baseline content changed -> invalidate catalogs so clients receive
        // the baseline immediately.
        TransKey::flush();

        $this->command?->info("Translations baseline seeded ({$created} rows created, existing rows preserved).");
    }
}
