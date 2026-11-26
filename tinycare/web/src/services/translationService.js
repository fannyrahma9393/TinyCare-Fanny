import api from './api';
import i18n from '../i18n';

/**
 * Remote translation overlay service.
 *
 * Fetches the key => value catalog from the backend (DB, admin-editable) and
 * merges it ON TOP of the static i18next bundles (`src/locales/partials/*`).
 * The static bundles are never modified or removed — they remain the fallback
 * whenever a key has no remote override or the API is unreachable.
 *
 * Priority: remote DB value > static locale bundle > static Indonesian > key.
 *
 * Cache: localStorage per locale with a 1-hour TTL, so a network failure or
 * offline state never breaks the UI (stale cache is still applied).
 */

const CACHE_KEY = 'tinycare-remote-translations';
const CACHE_TTL_MS = 60 * 60 * 1000; // 1 hour
const SUPPORTED = ['id', 'en'];

function readCache() {
  try {
    return JSON.parse(localStorage.getItem(CACHE_KEY) || '{}') || {};
  } catch {
    return {};
  }
}

function writeCacheEntry(locale, translations) {
  try {
    const cache = readCache();
    cache[locale] = { fetchedAt: Date.now(), translations: translations || {} };
    localStorage.setItem(CACHE_KEY, JSON.stringify(cache));
  } catch {
    // storage unavailable (private mode etc.) — overlay still works in memory
  }
}

/** Merge a remote map over the static bundle for one locale. */
function applyOverlay(locale, translations) {
  if (!translations || typeof translations !== 'object') return;
  // deep=true, overwrite=true: remote values WIN over identical static keys,
  // but keys that only exist statically are kept as fallback.
  i18n.addResourceBundle(locale, 'translation', translations, true, true);
}

function isFresh(entry) {
  return Boolean(entry && entry.fetchedAt && Date.now() - entry.fetchedAt < CACHE_TTL_MS);
}

/**
 * Fetch the catalog for one locale and apply it as an overlay.
 * Falls back to stale cache, then to the untouched static bundle.
 */
async function loadLocale(locale, { force = false } = {}) {
  const cached = readCache()[locale];

  if (!force && isFresh(cached)) {
    applyOverlay(locale, cached.translations);
    return { locale, ok: true, source: 'cache' };
  }

  try {
    const res = await api.get('/translations', { params: { locale } });
    const translations = res?.data?.data?.translations || {};
    applyOverlay(locale, translations);
    writeCacheEntry(locale, translations);
    return { locale, ok: true, source: 'network' };
  } catch {
    // API unavailable: keep whatever static catalog exists; apply stale cache
    // if present so previously-fetched admin wording still shows.
    if (cached?.translations) applyOverlay(locale, cached.translations);
    return { locale, ok: false, source: cached ? 'stale-cache' : 'static' };
  }
}

/**
 * Load remote overlays for every supported locale (called once at app start).
 * Both locales are preloaded so the LanguageSwitcher shows remote wording
 * immediately after switching, without an extra round-trip.
 */
export async function loadRemoteTranslations({ force = false } = {}) {
  const results = await Promise.all(SUPPORTED.map((locale) => loadLocale(locale, { force })));
  // Force react-i18next to re-render consumers after bundles changed.
  try {
    i18n.emit('languageChanged', i18n.language);
  } catch {
    // rendering refresh is best-effort; static UI still works
  }
  return results;
}

/** Drop the localStorage cache (used after admin edits, before manual reload). */
export function invalidateRemoteTranslations() {
  try {
    localStorage.removeItem(CACHE_KEY);
  } catch {
    // ignore
  }
}
