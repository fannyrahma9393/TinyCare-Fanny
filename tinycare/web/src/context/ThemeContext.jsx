import { createContext, useContext, useState, useEffect, useCallback } from 'react';

const ThemeContext = createContext(null);

const THEME_KEY = 'tinycare-theme';

function getSystemTheme() {
  if (typeof window === 'undefined') return 'light';
  return window.matchMedia('(prefers-color-scheme: dark)').matches ? 'dark' : 'light';
}

function getStoredTheme() {
  if (typeof window === 'undefined') return 'system';
  return localStorage.getItem(THEME_KEY) || 'system';
}

export function ThemeProvider({ children }) {
  const [themeMode, setThemeMode] = useState(getStoredTheme);

  const resolvedTheme = themeMode === 'system' ? getSystemTheme() : themeMode;

  useEffect(() => {
    const root = document.documentElement;
    root.classList.remove('light', 'dark');
    root.classList.add(resolvedTheme);
    root.setAttribute('data-theme', resolvedTheme);
  }, [resolvedTheme]);

  useEffect(() => {
    if (themeMode !== 'system') return;
    const mq = window.matchMedia('(prefers-color-scheme: dark)');
    const handler = () => {
      const root = document.documentElement;
      const sys = mq.matches ? 'dark' : 'light';
      root.classList.remove('light', 'dark');
      root.classList.add(sys);
      root.setAttribute('data-theme', sys);
    };
    mq.addEventListener('change', handler);
    return () => mq.removeEventListener('change', handler);
  }, [themeMode]);

  useEffect(() => {
    localStorage.setItem(THEME_KEY, themeMode);
  }, [themeMode]);

  const setTheme = useCallback((mode) => setThemeMode(mode), []);

  return (
    <ThemeContext.Provider value={{ theme: resolvedTheme, themeMode, setTheme }}>
      {children}
    </ThemeContext.Provider>
  );
}

// eslint-disable-next-line react/only-export-components
export function useTheme() {
  const ctx = useContext(ThemeContext);
  if (!ctx) throw new Error('useTheme must be used within ThemeProvider');
  return ctx;
}
