import { describe, it, expect, vi, beforeEach } from 'vitest';
import { render, screen, fireEvent, waitFor } from '@testing-library/react';
import TranslationsAdminPage from '../TranslationsAdminPage';

vi.mock('../../services/api', () => ({
  translationsAPI: {
    list: vi.fn(),
    update: vi.fn(),
    addMissingLocale: vi.fn(),
  },
  unwrapList: (res) => res?.data?.data ?? [],
}));

vi.mock('../../services/translationService', () => ({
  invalidateRemoteTranslations: vi.fn(),
}));

vi.mock('../../context/AuthContext', () => ({
  useAuth: vi.fn(),
}));

import { translationsAPI } from '../../services/api';
import { useAuth } from '../../context/AuthContext';

function mockResponse(rows, lastPage = 1) {
  return { data: { data: { data: rows, last_page: lastPage, current_page: 1 } } };
}

const row = (id, key, locale, value) => ({ id, key, locale, value });

describe('TranslationsAdminPage', () => {
  beforeEach(() => {
    vi.clearAllMocks();
    useAuth.mockReturnValue({ user: { role: 'admin_master' } });
  });

  it('renders key table with both locales and complete status', async () => {
    translationsAPI.list.mockResolvedValue(
      mockResponse([
        row(1, 'Simpan', 'id', 'Simpan'),
        row(2, 'Simpan', 'en', 'Save'),
      ]),
    );

    render(<TranslationsAdminPage />);

    const idCell = await screen.findByTestId('trans-value-Simpan-id');
    const enCell = await screen.findByTestId('trans-value-Simpan-en');
    expect(idCell).toHaveTextContent('Simpan');
    expect(enCell).toHaveTextContent('Save');
    expect(screen.getByText(/Lengkap/i)).toBeInTheDocument();
  });

  it('shows incomplete status when English is missing and offers fill', async () => {
    translationsAPI.list.mockResolvedValue(
      mockResponse([row(1, 'Simpan', 'id', 'Simpan')]),
    );

    render(<TranslationsAdminPage />);

    await waitFor(() => expect(screen.getByText(/Belum Lengkap/i)).toBeInTheDocument());
    expect(screen.getByTestId('trans-fill-Simpan-en')).toBeInTheDocument();
  });

  it('saves an edited translation via update API', async () => {
    translationsAPI.list
      .mockResolvedValueOnce(mockResponse([row(1, 'Simpan', 'id', 'Simpan'), row(2, 'Simpan', 'en', 'Save')]))
      .mockResolvedValueOnce(mockResponse([row(1, 'Simpan', 'id', 'Simpan Disimpan'), row(2, 'Simpan', 'en', 'Save')]));

    translationsAPI.update.mockResolvedValue({ data: { success: true } });

    render(<TranslationsAdminPage />);
    const cell = await screen.findByTestId('trans-value-Simpan-id');

    fireEvent.click(cell);

    const textarea = await screen.findByTestId('trans-input');
    fireEvent.change(textarea, { target: { value: 'Simpan Disimpan' } });
    fireEvent.click(screen.getByTestId('trans-save'));

    await waitFor(() => expect(translationsAPI.update).toHaveBeenCalledWith(1, { value: 'Simpan Disimpan' }));
    expect(await screen.findByText(/Terjemahan berhasil disimpan/i)).toBeInTheDocument();
  });

  it('fills a missing English translation via addMissingLocale API', async () => {
    translationsAPI.list
      .mockResolvedValueOnce(mockResponse([row(1, 'Simpan', 'id', 'Simpan')]))
      .mockResolvedValueOnce(mockResponse([row(1, 'Simpan', 'id', 'Simpan'), row(2, 'Simpan', 'en', 'Save Now')]));

    translationsAPI.addMissingLocale.mockResolvedValue({ data: { success: true } });

    render(<TranslationsAdminPage />);
    const fill = await screen.findByTestId('trans-fill-Simpan-en');

    fireEvent.click(fill);

    const textarea = await screen.findByTestId('trans-input');
    fireEvent.change(textarea, { target: { value: 'Save Now' } });
    fireEvent.click(screen.getByTestId('trans-save'));

    await waitFor(() => expect(translationsAPI.addMissingLocale).toHaveBeenCalledWith({ key: 'Simpan', locale: 'en', value: 'Save Now' }));
  });

  it('rejects empty values without calling the API', async () => {
    translationsAPI.list.mockResolvedValue(
      mockResponse([row(1, 'Simpan', 'id', 'Simpan'), row(2, 'Simpan', 'en', 'Save')]),
    );

    render(<TranslationsAdminPage />);
    const cell = await screen.findByTestId('trans-value-Simpan-id');

    fireEvent.click(cell);
    const textarea = await screen.findByTestId('trans-input');
    fireEvent.change(textarea, { target: { value: '   ' } });
    fireEvent.click(screen.getByTestId('trans-save'));

    await waitFor(() => expect(screen.getByText(/tidak boleh kosong/i)).toBeInTheDocument());
    expect(translationsAPI.update).not.toHaveBeenCalled();
  });

  it('shows access denied for non admin_master', async () => {
    useAuth.mockReturnValue({ user: { role: 'admin' } });

    render(<TranslationsAdminPage />);

    expect(await screen.findByText(/Akses Ditolak/i)).toBeInTheDocument();
    expect(translationsAPI.list).not.toHaveBeenCalled();
  });
});
