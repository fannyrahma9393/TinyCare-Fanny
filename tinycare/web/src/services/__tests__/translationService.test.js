import { describe, it, expect, vi, beforeEach } from 'vitest';

// Mock the axios instance used by the service.
vi.mock('../api', () => ({ default: { get: vi.fn() } }));

import api from '../api';
import { loadRemoteTranslations, invalidateRemoteTranslations } from '../translationService';
import i18n from '../../i18n';

function resetBundles() {
  i18n.removeResourceBundle('id', 'translation');
  i18n.removeResourceBundle('en', 'translation');
  // Restore the static catalogs after removal.
  // eslint-disable-next-line global-require
  const resources = require('../../locales').default;
  i18n.addResourceBundle('id', 'translation', resources.id, true, true);
  i18n.addResourceBundle('en', 'translation', resources.en, true, true);
}

describe('translationService', () => {
  beforeEach(() => {
    vi.clearAllMocks();
    localStorage.clear();
    resetBundles();
  });

  it('applies remote overlay over static catalog', async () => {
    api.get.mockResolvedValue({ data: { data: { locale: 'id', translations: { Simpan: 'Simpan Perubahan' } } } });

    await loadRemoteTranslations({ force: true });

    expect(i18n.t('Simpan', { lng: 'id' })).toBe('Simpan Perubahan');
  });

  it('keeps static fallback when a key has no remote value', async () => {
    api.get.mockResolvedValue({ data: { data: { locale: 'id', translations: {} } } });

    await loadRemoteTranslations({ force: true });

    expect(i18n.t('Simpan', { lng: 'id' })).toBe('Simpan');
  });

  it('falls back to static catalog when API is unavailable', async () => {
    api.get.mockRejectedValue(new Error('network down'));

    const results = await loadRemoteTranslations({ force: true });

    expect(results.every((r) => r.ok === false)).toBe(true);
    // UI must still render the static wording — never blank.
    expect(i18n.t('Simpan', { lng: 'id' })).toBe('Simpan');
    expect(i18n.t('Simpan', { lng: 'en' })).toBe('Save');
  });

  it('uses stale cache when API is unavailable after a successful fetch', async () => {
    api.get.mockResolvedValueOnce({ data: { data: { locale: 'id', translations: { Simpan: 'Simpan dari Cache' } } } });
    await loadRemoteTranslations({ force: true });

    resetBundles();
    api.get.mockRejectedValue(new Error('network down'));
    await loadRemoteTranslations({ force: true });

    expect(i18n.t('Simpan', { lng: 'id' })).toBe('Simpan dari Cache');
  });

  it('serves from cache without a network call while fresh', async () => {
    api.get.mockResolvedValue({ data: { data: { locale: 'id', translations: { Simpan: 'Cached' } } } });
    await loadRemoteTranslations({ force: true });
    expect(api.get).toHaveBeenCalledTimes(2); // id + en

    api.get.mockClear();
    await loadRemoteTranslations(); // not forced -> cache hit
    expect(api.get).not.toHaveBeenCalled();
    expect(i18n.t('Simpan', { lng: 'id' })).toBe('Cached');
  });

  it('invalidateRemoteTranslations clears the localStorage cache', async () => {
    api.get.mockResolvedValue({ data: { data: { locale: 'id', translations: {} } } });
    await loadRemoteTranslations({ force: true });

    invalidateRemoteTranslations();

    expect(localStorage.getItem('tinycare-remote-translations')).toBeNull();
  });
});
