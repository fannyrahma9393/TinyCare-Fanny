import { createContext, useContext, useState, useEffect } from 'react';
import { authAPI } from '../services/api';

const AuthContext = createContext(null);

function sanitizeUser(data) {
  if (!data || typeof data !== 'object') return null;
  return {
    id: data.id,
    name: String(data.name || '').replace(/<[^>]*>/g, '').trim(),
    email: String(data.email || '').trim(),
    role: String(data.role || '').trim(),
    status: String(data.status || '').trim(),
  };
}

function getInitialUser() {
  try {
    const token = localStorage.getItem('token');
    const savedUser = localStorage.getItem('user');
    if (token && savedUser) {
      const parsed = JSON.parse(savedUser);
      return sanitizeUser(parsed);
    }
  } catch {
    // ignore parse error
  }
  return null;
}

export function AuthProvider({ children }) {
  const [user, setUser] = useState(getInitialUser);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const token = localStorage.getItem('token');
    if (!token) {
      setLoading(false);
      return;
    }

    authAPI.me()
      .then((response) => {
        const userData = response.data.data;
        const freshUser = sanitizeUser(userData);
        if (freshUser) {
          localStorage.setItem('user', JSON.stringify(freshUser));
          setUser(freshUser);
        } else {
          localStorage.removeItem('token');
          localStorage.removeItem('user');
          setUser(null);
        }
      })
      .catch(() => {
        localStorage.removeItem('token');
        localStorage.removeItem('user');
        setUser(null);
      })
      .finally(() => setLoading(false));
  }, []);

  const login = async (email, password) => {
    const payload = { email, password };

    const response = await authAPI.login(payload);
    const { data } = response.data;

    const sanitizedUser = sanitizeUser(data.user);
    localStorage.setItem('token', data.token);
    localStorage.setItem('user', JSON.stringify(sanitizedUser));
    setUser(sanitizedUser);

    return data;
  };

  const logout = async () => {
    try {
      await authAPI.logout();
    } catch {
      // Ignore error, just clear local state
    }
    localStorage.removeItem('token');
    localStorage.removeItem('user');
    setUser(null);
  };

  const isAdmin = user?.role === 'admin' || user?.role === 'admin_master';
  const isAdminMaster = user?.role === 'admin_master';

  return (
    <AuthContext.Provider value={{ user, login, logout, loading, isAdmin, isAdminMaster }}>
      {children}
    </AuthContext.Provider>
  );
}

// eslint-disable-next-line react/only-export-components
export function useAuth() {
  const context = useContext(AuthContext);
  if (!context) {
    throw new Error('useAuth must be used within an AuthProvider');
  }
  return context;
}
