import { useTranslation } from 'react-i18next';
import { setAppLanguage, getAppLanguage } from '../i18n';

export default function LanguageSwitcher({ dark = false }) {
  const { i18n, t } = useTranslation();
  const lang = getAppLanguage();

  return (
    <select
      value={lang}
      onChange={(e) => setAppLanguage(e.target.value)}
      aria-label={t('Bahasa')}
      style={{
        padding: '6px 8px',
        fontSize: '12px',
        fontWeight: '600',
        borderRadius: 'var(--radius-sm)',
        border: dark ? '1px solid var(--color-border)' : '1px solid var(--color-border)',
        background: dark ? 'var(--color-surface)' : 'var(--color-surface)',
        color: 'var(--color-text)',
        cursor: 'pointer',
      }}
      onMouseDown={(e) => e.stopPropagation()}
    >
      <option value="id">🇮🇩 Indonesia</option>
      <option value="en">🇬🇧 English</option>
    </select>
  );
}