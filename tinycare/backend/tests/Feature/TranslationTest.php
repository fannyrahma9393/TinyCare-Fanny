<?php

namespace Tests\Feature;

use App\Models\Role;
use App\Models\Translation;
use App\Models\User;
use App\Support\TransKey;
use Illuminate\Database\QueryException;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Cache;
use Tests\TestCase;

class TranslationTest extends TestCase
{
    use RefreshDatabase;

    private User $adminMaster;

    private User $admin;

    protected function setUp(): void
    {
        parent::setUp();

        $masterRole = Role::firstOrCreate(['name' => 'admin_master'], ['description' => 'Admin Master']);
        $adminRole = Role::firstOrCreate(['name' => 'admin'], ['description' => 'Admin']);
        Role::firstOrCreate(['name' => 'parent'], ['description' => 'Parent']);

        $this->adminMaster = User::create([
            'name' => 'Master',
            'email' => 'master@test.com',
            'password' => bcrypt('password123'),
            'role_id' => $masterRole->id,
            'status' => 'active',
        ]);

        $this->admin = User::create([
            'name' => 'Admin',
            'email' => 'admin@test.com',
            'password' => bcrypt('password123'),
            'role_id' => $adminRole->id,
            'status' => 'active',
        ]);
    }

    // 1. GET Indonesian
    public function test_public_index_returns_indonesian_catalog(): void
    {
        Translation::create(['key' => 'Simpan', 'locale' => 'id', 'value' => 'Simpan']);

        $res = $this->getJson('/api/v1/translations?locale=id');

        $res->assertOk()
            ->assertJsonPath('success', true)
            ->assertJsonPath('data.locale', 'id')
            ->assertJsonPath('data.translations.Simpan', 'Simpan');
    }

    // 2. GET English
    public function test_public_index_returns_english_catalog(): void
    {
        Translation::create(['key' => 'Simpan', 'locale' => 'en', 'value' => 'Save']);

        $res = $this->getJson('/api/v1/translations?locale=en');

        $res->assertOk()
            ->assertJsonPath('data.locale', 'en')
            ->assertJsonPath('data.translations.Simpan', 'Save');
    }

    // 3. Invalid locale rejected
    public function test_public_index_rejects_unsupported_locale(): void
    {
        $this->getJson('/api/v1/translations?locale=fr')->assertStatus(422);
    }

    // 10. Response format contains the translations map
    public function test_response_format_contains_locale_and_map(): void
    {
        $res = $this->getJson('/api/v1/translations?locale=id');

        $res->assertOk()
            ->assertJsonStructure([
                'success',
                'data' => ['locale', 'translations'],
            ]);
    }

    // 4. admin_master can update
    public function test_admin_master_can_update_translation_value(): void
    {
        $row = Translation::create(['key' => 'Simpan', 'locale' => 'id', 'value' => 'Simpan']);

        $this->actingAs($this->adminMaster, 'sanctum')
            ->putJson("/api/v1/admin/translations/{$row->id}", ['value' => 'Simpan Perubahan'])
            ->assertOk()
            ->assertJsonPath('success', true)
            ->assertJsonPath('data.value', 'Simpan Perubahan');

        $this->assertDatabaseHas('translations', [
            'key' => 'Simpan',
            'locale' => 'id',
            'value' => 'Simpan Perubahan',
        ]);
    }

    // 5. admin (non-master) cannot update
    public function test_regular_admin_cannot_update_translation(): void
    {
        $row = Translation::create(['key' => 'Simpan', 'locale' => 'id', 'value' => 'Simpan']);

        $this->actingAs($this->admin, 'sanctum')
            ->putJson("/api/v1/admin/translations/{$row->id}", ['value' => 'X'])
            ->assertStatus(403);
    }

    // 6. Unauthenticated cannot update
    public function test_unauthenticated_cannot_update_translation(): void
    {
        $row = Translation::create(['key' => 'Simpan', 'locale' => 'id', 'value' => 'Simpan']);

        $this->putJson("/api/v1/admin/translations/{$row->id}", ['value' => 'X'])
            ->assertStatus(401);
    }

    // 7. Duplicate key+locale is rejected at the database level
    public function test_duplicate_key_and_locale_is_rejected(): void
    {
        Translation::create(['key' => 'Simpan', 'locale' => 'id', 'value' => 'Simpan']);

        $this->expectException(QueryException::class);

        Translation::create(['key' => 'Simpan', 'locale' => 'id', 'value' => 'Simpan Duplikat']);
    }

    // 8. Missing translation falls back safely
    public function test_trans_key_falls_back_when_missing(): void
    {
        Cache::flush();

        // Key absent from DB -> caller fallback is used, never a raw key.
        $this->assertSame(
            'Tagihan Baru',
            TransKey::t('notif.invoice.created.title', [], 'Tagihan Baru')
        );

        // No fallback provided -> the key itself (still no crash).
        $this->assertSame('notif.unknown.key', TransKey::t('notif.unknown.key'));
    }

    public function test_trans_key_uses_db_value_and_placeholders(): void
    {
        Cache::flush();
        Translation::create([
            'key' => 'notif.invoice.created',
            'locale' => 'id',
            'value' => 'Tagihan baru untuk {child_name}: {package_name}',
        ]);

        $rendered = TransKey::t('notif.invoice.created', [
            'child_name' => 'Budi',
            'package_name' => 'Paket Harian',
        ], 'fallback');

        $this->assertSame('Tagihan baru untuk Budi: Paket Harian', $rendered);
    }

    // 9. Cache is invalidated after an admin update
    public function test_cache_is_invalidated_after_update(): void
    {
        Cache::flush();
        $row = Translation::create(['key' => 'Simpan', 'locale' => 'en', 'value' => 'Save']);

        // Prime the cache through the public API.
        $this->getJson('/api/v1/translations?locale=en')
            ->assertOk()
            ->assertJsonPath('data.translations.Simpan', 'Save');
        $this->assertTrue(Cache::has('translations:en'));

        $this->actingAs($this->adminMaster, 'sanctum')
            ->putJson("/api/v1/admin/translations/{$row->id}", ['value' => 'Save Changes'])
            ->assertOk();

        $this->assertFalse(Cache::has('translations:en'));

        // Fresh fetch reflects the update.
        $this->getJson('/api/v1/translations?locale=en')
            ->assertOk()
            ->assertJsonPath('data.translations.Simpan', 'Save Changes');
    }

    // 11. Key cannot be changed (only `value` is accepted)
    public function test_key_cannot_be_changed(): void
    {
        $row = Translation::create(['key' => 'Simpan', 'locale' => 'id', 'value' => 'Simpan']);

        $this->actingAs($this->adminMaster, 'sanctum')
            ->putJson("/api/v1/admin/translations/{$row->id}", [
                'key' => 'Hacked.Key',
                'value' => 'Simpan Perubahan',
            ])
            ->assertOk();

        $this->assertDatabaseHas('translations', ['id' => $row->id, 'key' => 'Simpan']);
        $this->assertDatabaseMissing('translations', ['key' => 'Hacked.Key']);
    }

    // 12. Locale cannot be changed to an unsupported one
    public function test_locale_cannot_be_changed_to_unsupported(): void
    {
        $row = Translation::create(['key' => 'Simpan', 'locale' => 'id', 'value' => 'Simpan']);

        // Unsupported locale value fails validation.
        $this->actingAs($this->adminMaster, 'sanctum')
            ->putJson("/api/v1/admin/translations/{$row->id}", [
                'value' => 'X',
                'locale' => 'fr',
            ])
            ->assertStatus(422);

        // Even a *supported* different locale is rejected (immutable).
        $this->actingAs($this->adminMaster, 'sanctum')
            ->putJson("/api/v1/admin/translations/{$row->id}", [
                'value' => 'X',
                'locale' => 'en',
            ])
            ->assertStatus(422);

        $this->assertDatabaseHas('translations', ['id' => $row->id, 'locale' => 'id']);
    }

    // Admin list requires authentication
    public function test_admin_index_requires_authentication(): void
    {
        $this->getJson('/api/v1/admin/translations')->assertStatus(401);
    }

    // Admin list allows search
    public function test_admin_index_supports_search(): void
    {
        Translation::create(['key' => 'Simpan', 'locale' => 'en', 'value' => 'Save']);
        Translation::create(['key' => 'Batal', 'locale' => 'en', 'value' => 'Cancel']);

        $this->actingAs($this->adminMaster, 'sanctum')
            ->getJson('/api/v1/admin/translations?search=Save')
            ->assertOk()
            ->assertJsonFragment(['key' => 'Simpan'])
            ->assertJsonMissing(['key' => 'Batal']);
    }
}
