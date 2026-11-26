<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Translation;
use App\Support\TransKey;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Cache;

/**
 * Translation management API.
 *
 *  - Public read:  GET /api/v1/translations?locale=id|en   (client overlay source, cached)
 *  - Admin read:   GET /api/v1/admin/translations          (admin + admin_master, paginated + search)
 *  - Admin write:  PUT /api/v1/admin/translations/{translation}  (admin_master ONLY)
 *
 * Keys are system-controlled: they can never be created, renamed or deleted
 * through this API. Admins may only reword the VALUE for a supported locale
 * (`id` / `en`). Every write invalidates the translation cache so the next
 * client fetch (and server-generated notification render) sees fresh data.
 */
class TranslationController extends Controller
{
    /**
     * Public: key => value catalog for one locale. Consumed by Web + Mobile
     * as the remote overlay on top of their static catalogs.
     */
    public function index(Request $request): JsonResponse
    {
        $locale = $request->query('locale', config('tinycare.trans_notif_locale', 'id'));

        if (! in_array($locale, (array) config('tinycare.supported_locales', ['id', 'en']), true)) {
            return response()->json([
                'success' => false,
                'message' => 'Locale tidak didukung. Gunakan id atau en.',
            ], 422);
        }

        $translations = TransKey::catalog($locale);

        return response()->json([
            'success' => true,
            'data' => [
                'locale' => $locale,
                'translations' => $translations,
            ],
        ]);
    }

    /**
     * Admin (admin + admin_master): paginated key list with both locales so
     * the management table can show Indonesia & English side by side.
     * Query params: ?search=&locale=&page=&per_page=
     */
    public function adminIndex(Request $request): JsonResponse
    {
        $search = trim((string) $request->query('search', ''));
        $localeFilter = $request->query('locale');

        $rows = Translation::query()
            ->when($search !== '', function ($q) use ($search) {
                $q->where(function ($qq) use ($search) {
                    $qq->where('key', 'like', "%{$search}%")
                        ->orWhere('value', 'like', "%{$search}%");
                });
            })
            ->when($localeFilter && in_array($localeFilter, ['id', 'en'], true), fn ($q) => $q->where('locale', $localeFilter))
            ->orderBy('key')
            ->orderBy('locale')
            ->paginate($request->per_page ?? 50);

        return response()->json([
            'success' => true,
            'data' => $rows,
        ]);
    }

    /**
     * Admin (admin_master ONLY): fill the value for a (key, locale) pair that
     * has no row yet (e.g. "English belum diisi"). Keys are system-controlled:
     * the key must ALREADY exist in another locale, so brand-new keys cannot
     * be invented through the API.
     */
    public function adminStore(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'key' => 'required|string|max:191',
            'locale' => 'required|in:id,en',
            'value' => 'required|string|max:2000',
        ]);

        $keyExists = Translation::where('key', $validated['key'])->exists();
        if (! $keyExists) {
            return response()->json([
                'success' => false,
                'message' => 'Key tidak dikenal. Key terjemahan dikelola oleh aplikasi.',
            ], 422);
        }

        $translation = Translation::firstOrCreate(
            ['key' => $validated['key'], 'locale' => $validated['locale']],
            ['value' => $validated['value']]
        );

        TransKey::flush();

        return response()->json([
            'success' => true,
            'message' => 'Terjemahan berhasil ditambahkan.',
            'data' => $translation,
        ], 201);
    }

    /**
     * Admin (admin_master ONLY): reword the value of one (key, locale) row.
     * Key and locale are immutable here — a mismatching payload is rejected.
     */
    public function adminUpdate(Request $request, Translation $translation): JsonResponse
    {
        $validated = $request->validate([
            'value' => 'required|string|max:2000',
            'locale' => 'sometimes|in:id,en',
        ]);

        if (isset($validated['locale']) && $validated['locale'] !== $translation->locale) {
            return response()->json([
                'success' => false,
                'message' => 'Locale tidak boleh diubah.',
            ], 422);
        }

        $translation->update([
            'value' => $validated['value'],
        ]);

        // Cache invalidation: drop both locale catalogs to keep the public
        // API and server-generated notifications consistent immediately.
        TransKey::flush();

        return response()->json([
            'success' => true,
            'message' => 'Terjemahan berhasil diperbarui.',
            'data' => $translation->fresh(),
        ]);
    }
}
