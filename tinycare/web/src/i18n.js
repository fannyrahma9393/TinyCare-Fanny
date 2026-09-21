import i18n from 'i18next';
import { initReactI18next } from 'react-i18next';
import resources from './locales/index.js';

const LOCALE_KEY = 'tinycare-lang';

function getInitialLanguage() {
  if (typeof window === 'undefined') return 'id';
  try {
    return window.localStorage.getItem(LOCALE_KEY) || 'id';
  } catch {
    return 'id';
  }
}

i18n.use(initReactI18next).init({
  resources,
  lng: getInitialLanguage(),
  fallbackLng: 'id',
  interpolation: {
    escapeValue: false,
  },
  react: {
    useSuspense: false,
  },
});

export function setAppLanguage(locale) {
  if (typeof window !== 'undefined') {
    try {
      window.localStorage.setItem(LOCALE_KEY, locale);
    } catch {
      // ignore storage errors
    }
  }
  i18n.changeLanguage(locale);
}

export function getAppLanguage() {
  return i18n.language || 'id';
}

export default i18n;