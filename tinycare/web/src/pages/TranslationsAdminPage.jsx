import { useState, useEffect, useMemo, useRef } from 'react';
import { useTranslation } from 'react-i18next';
import { translationsAPI, unwrapList } from '../services/api';
import { invalidateRemoteTranslations } from '../services/translationService';
import { useAuth } from '../context/AuthContext';

/**
 * Admin "Bahasa & Terjemahan" (Translation Management) page.
 *
 * Accessible ONLY to admin_master. Shows every system-controlled key with its
 * Indonesian and English wording side by side, plus fill status. Admin can
 * inline-edit either wording (VALUE only — keys are immutable) and can fill
 * a missing locale via POST /admin/translations. Changes take effect on the
 * clients after their next fetch/reload (no realtime).
 */

const PER_PAGE = 50;

export default function TranslationsAdminPage() {
  const { t } = useTranslation();
  const { user } = useAuth();
  const isMaster = user?.role === 'admin_master';

  const [rows, setRows] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [search, setSearch] = useState('');
  const [searchInput, setSearchInput] = useState('');
  const [localeFilter, setLocaleFilter] = useState('');
  const [page, setPage] = useState(1);
  const [lastPage, setLastPage] = useState(1);
  const [savingId, setSavingId] = useState(null);
  const [toast, setToast] = useState(null);

  // editing state: { id, locale, value } for existing rows, or { key, locale, value, isNew } for fills
  const [editing, setEditing] = useState(null);

  const toastTimer = useRef(null);
  const showToast = (type, message) => {
    setToast({ type, message });
    clearTimeout(toastTimer.current);
    toastTimer.current = setTimeout(() => setToast(null), 3500);
  };

  useEffect(() => { if (isMaster) load(); }, [page, search, localeFilter, isMaster]);

  async function load() {
    setLoading(true);
    setError('');
    try {
      const params = { page, per_page: PER_PAGE };
      if (search) params.search = search;
      if (localeFilter) params.locale = localeFilter;
      const res = await translationsAPI.list(params);
      const paginated = res.data.data;
      setRows(paginated.data || []);
      setLastPage(paginated.last_page || 1);
    } catch (err) {
      setError(err.response?.data?.message || t('Gagal memuat data terjemahan.'));
    } finally {
      setLoading(false);
    }
  }

  const stats = useMemo(() => {
    const idRows = rows.filter((r) => r.locale === 'id').length;
    const enRows = rows.filter((r) => r.locale === 'en').length;
    return { id: idRows, en: enRows, total: rows.length };
  }, [rows]);

  function startEdit(row, locale) {
    if (!isMaster) return;
    setEditing({ id: row.id, locale, value: row.value, key: row.key });
  }

  function startFill(key, locale) {
    if (!isMaster) return;
    setEditing({ key, locale, value: '', isNew: true });
  }

  function cancelEdit() {
    setEditing(null);
  }

  async function saveEdit() {
    if (!editing) return;
    const value = editing.value.trim();
    if (!value) {
      showToast('error', t('Nilai terjemahan tidak boleh kosong.'));
      return;
    }
    setSavingId(editing.id || editing.key);
    try {
      if (editing.isNew) {
        await translationsAPI.addMissingLocale({ key: editing.key, locale: editing.locale, value });
      } else {
        await translationsAPI.update(editing.id, { value });
      }
      // Server-side catalogs changed: drop the local overlay cache so the
      // next load/reload fetches fresh wording.
      invalidateRemoteTranslations();
      showToast('success', t('Terjemahan berhasil disimpan.'));
      setEditing(null);
      await load();
    } catch (err) {
      showToast('error', err.response?.data?.message || t('Gagal menyimpan terjemahan.'));
    } finally {
      setSavingId(null);
    }
  }

  // Group rows by key: the backend paginates key+locale pairs; pair them up
  // for the KEY | INDONESIA | ENGLISH | STATUS table.
  const grouped = useMemo(() => {
    const byKey = new Map();
    for (const row of rows) {
      if (!byKey.has(row.key)) byKey.set(row.key, {});
      byKey.get(row.key)[row.locale] = row;
    }
    const list = [...byKey.entries()].map(([key, pair]) => ({
      key,
      id: pair.id || null,
      en: pair.en || null,
      complete: Boolean(pair.id && pair.en),
    }));
    // When filtering by locale, keep only keys matching that locale.
    if (localeFilter) {
      return list.filter((item) => (localeFilter === 'id' ? item.id : item.en));
    }
    return list;
  }, [rows, localeFilter]);

  if (!isMaster) {
    return (
      <div className="p-6">
        <h1 className="text-xl font-bold" style={{ color: 'var(--color-text)' }}>{t('Akses Ditolak')}</h1>
        <p style={{ color: 'var(--color-text-muted)' }}>{t('Hanya admin_master yang dapat mengelola terjemahan.')}</p>
      </div>
    );
  }

  return (
    <div style={{ padding: '24px', maxWidth: 1200, margin: '0 auto' }}>
      <div style={{ marginBottom: 16 }}>
        <h1 style={{ fontSize: 20, fontWeight: 700, color: 'var(--color-text)' }}>{t('Bahasa & Terjemahan')}</h1>
        <p style={{ fontSize: 13, color: 'var(--color-text-muted)' }}>
          {t('Kelola wording system UI dan notifikasi. Perubahan terlihat setelah reload/refetch client.')}
        </p>
      </div>

      {/* Filters */}
      <div style={{ display: 'flex', gap: 8, flexWrap: 'wrap', marginBottom: 16 }}>
        <form
          onSubmit={(e) => { e.preventDefault(); setPage(1); setSearch(searchInput.trim()); }}
          style={{ flex: '1 1 240px', minWidth: 220 }}
        >
          <input
            value={searchInput}
            onChange={(e) => setSearchInput(e.target.value)}
            placeholder={t('Cari key atau teks...')}
            style={{
              width: '100%', padding: '8px 12px', fontSize: 13, borderRadius: 'var(--radius-sm)',
              border: '1px solid var(--color-border)', background: 'var(--color-surface)', color: 'var(--color-text)',
            }}
          />
        </form>
        <div style={{ display: 'flex', gap: 4 }}>
          {[['', t('Semua')], ['id', t('Indonesia')], ['en', t('English')]].map(([val, label]) => (
            <button
              key={val || 'all'}
              onClick={() => { setPage(1); setLocaleFilter(val); }}
              style={{
                padding: '7px 12px', fontSize: 12, fontWeight: 600, borderRadius: 'var(--radius-sm)',
                border: '1px solid var(--color-border)', cursor: 'pointer',
                background: localeFilter === val ? 'var(--color-primary)' : 'var(--color-surface)',
                color: localeFilter === val ? '#fff' : 'var(--color-text)',
              }}
            >
              {label}
            </button>
          ))}
        </div>
      </div>

      {toast && (
        <div style={{
          marginBottom: 12, padding: '10px 14px', fontSize: 13, borderRadius: 'var(--radius-sm)',
          background: toast.type === 'success' ? 'var(--color-success-light, #e6f6ec)' : '#fdecec',
          color: toast.type === 'success' ? '#1a7f4b' : '#b42318',
        }}>
          {toast.message}
        </div>
      )}

      {error && (
        <div style={{ marginBottom: 12, padding: '10px 14px', fontSize: 13, color: '#b42318' }}>
          {error} <button onClick={load} style={{ textDecoration: 'underline' }}>{t('Coba Lagi')}</button>
        </div>
      )}

      {/* Table */}
      <div style={{ border: '1px solid var(--color-border)', borderRadius: 'var(--radius-sm)', overflow: 'hidden' }}>
        <div style={{
          display: 'grid', gridTemplateColumns: '1.2fr 1.3fr 1.3fr 110px 150px', gap: 8,
          padding: '10px 12px', background: 'var(--color-bg)', fontSize: 11, fontWeight: 700,
          color: 'var(--color-text-muted)', textTransform: 'uppercase', letterSpacing: '0.04em',
        }}>
          <span>Key</span>
          <span>{t('Indonesia')}</span>
          <span>{t('English')}</span>
          <span>{t('Status')}</span>
          <span>{t('Aksi')}</span>
        </div>

        {loading && (
          <div style={{ padding: 24, textAlign: 'center', color: 'var(--color-text-muted)', fontSize: 13 }}>{t('Memuat')}...</div>
        )}

        {!loading && grouped.length === 0 && (
          <div style={{ padding: 24, textAlign: 'center', color: 'var(--color-text-muted)', fontSize: 13 }}>{t('Tidak ada data')}</div>
        )}

        {!loading && grouped.map((item) => (
          <div
            key={item.key}
            style={{
              display: 'grid', gridTemplateColumns: '1.2fr 1.3fr 1.3fr 110px 150px', gap: 8,
              padding: '10px 12px', borderTop: '1px solid var(--color-border)', alignItems: 'center',
              background: 'var(--color-surface)',
            }}
          >
            <span style={{ fontSize: 12, fontFamily: 'monospace', color: 'var(--color-text)', wordBreak: 'break-all' }}>{item.key}</span>

            {/* Indonesia cell */}
            <TranslationCell
              item={item}
              locale="id"
              row={item.id}
              editing={editing}
              setEditing={setEditing}
              savingId={savingId}
              saveEdit={saveEdit}
              cancelEdit={cancelEdit}
              startEdit={startEdit}
              startFill={startFill}
              t={t}
            />

            {/* English cell */}
            <TranslationCell
              item={item}
              locale="en"
              row={item.en}
              editing={editing}
              setEditing={setEditing}
              savingId={savingId}
              saveEdit={saveEdit}
              cancelEdit={cancelEdit}
              startEdit={startEdit}
              startFill={startFill}
              t={t}
            />

            {/* Status */}
            <span style={{ fontSize: 11, fontWeight: 600, color: item.complete ? '#1a7f4b' : '#b45309' }}>
              {item.complete ? t('Lengkap') : t('Belum Lengkap')}
            </span>

            {/* Action hint */}
            <span style={{ fontSize: 11, color: 'var(--color-text-muted)' }}>
              {isMaster ? t('Klik teks untuk mengedit') : t('Hanya lihat')}
            </span>
          </div>
        ))}
      </div>

      {/* Pagination */}
      {!loading && lastPage > 1 && (
        <div style={{ display: 'flex', gap: 8, justifyContent: 'center', alignItems: 'center', padding: 16 }}>
          <button
            disabled={page <= 1}
            onClick={() => setPage((p) => Math.max(1, p - 1))}
            style={{ padding: '6px 12px', fontSize: 12, border: '1px solid var(--color-border)', borderRadius: 6, background: 'var(--color-surface)', color: 'var(--color-text)', cursor: page <= 1 ? 'not-allowed' : 'pointer' }}
          >
            ← {t('Sebelumnya')}
          </button>
          <span style={{ fontSize: 12, color: 'var(--color-text-muted)' }}>{page} / {lastPage}</span>
          <button
            disabled={page >= lastPage}
            onClick={() => setPage((p) => Math.min(lastPage, p + 1))}
            style={{ padding: '6px 12px', fontSize: 12, border: '1px solid var(--color-border)', borderRadius: 6, background: 'var(--color-surface)', color: 'var(--color-text)', cursor: page >= lastPage ? 'not-allowed' : 'pointer' }}
          >
            {t('Selanjutnya')} →
          </button>
        </div>
      )}
    </div>
  );
}

function TranslationCell({ item, locale, row, editing, setEditing, savingId, saveEdit, cancelEdit, startEdit, startFill, t }) {
  const isEditing = editing && editing.isNew === undefined && editing.id === row?.id && editing.locale === locale;
  const isFilling = editing && editing.isNew && editing.key === item.key && editing.locale === locale;
  const busy = savingId === (row?.id) || (editing?.isNew && savingId === editing?.key);

  if (isEditing || isFilling) {
    return (
      <div style={{ display: 'flex', gap: 4, alignItems: 'flex-start' }}>
        <textarea
          autoFocus
          data-testid="trans-input"
          value={editing.value}
          onChange={(e) => setEditing({ ...editing, value: e.target.value })}
          onKeyDown={(e) => {
            if (e.key === 'Escape') cancelEdit();
            if (e.key === 'Enter' && (e.ctrlKey || e.metaKey)) saveEdit();
          }}
          rows={2}
          style={{
            flex: 1, padding: '6px 8px', fontSize: 12, borderRadius: 'var(--radius-sm)',
            border: '1px solid var(--color-primary)', background: 'var(--color-surface)', color: 'var(--color-text)', resize: 'vertical',
          }}
        />
        <div style={{ display: 'flex', flexDirection: 'column', gap: 2 }}>
          <button
            data-testid="trans-save"
            onClick={saveEdit}
            disabled={busy}
            style={{ padding: '4px 8px', fontSize: 11, fontWeight: 600, borderRadius: 4, border: 'none', background: 'var(--color-primary)', color: '#fff', cursor: busy ? 'wait' : 'pointer' }}
          >
            {busy ? t('Menyimpan...') : t('Simpan')}
          </button>
          <button
            data-testid="trans-cancel"
            onClick={cancelEdit}
            style={{ padding: '4px 8px', fontSize: 11, borderRadius: 4, border: '1px solid var(--color-border)', background: 'transparent', color: 'var(--color-text-muted)', cursor: 'pointer' }}
          >
            {t('Batal')}
          </button>
        </div>
      </div>
    );
  }

  if (!row) {
    return (
      <button
        data-testid={`trans-fill-${item.key}-${locale}`}
        onClick={() => startFill(item.key, locale)}
        style={{
          width: '100%', textAlign: 'left', padding: '4px 8px', fontSize: 12, borderRadius: 4,
          border: '1px dashed var(--color-border)', background: 'transparent', color: 'var(--color-text-muted)',
          cursor: 'pointer', fontStyle: 'italic',
        }}
      >
        + {t('Belum diisi')}
      </button>
    );
  }

  return (
    <button
      data-testid={`trans-value-${item.key}-${locale}`}
      onClick={() => startEdit(row, locale)}
      title={t('Klik untuk mengedit')}
      style={{
        width: '100%', textAlign: 'left', padding: '4px 8px', fontSize: 12, borderRadius: 4,
        border: '1px solid transparent', background: 'transparent', color: 'var(--color-text)', cursor: 'pointer',
      }}
    >
      {row.value || '—'}
    </button>
  );
}
