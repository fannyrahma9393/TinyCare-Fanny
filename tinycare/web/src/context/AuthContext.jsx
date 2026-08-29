import { createContext, useContext, useState, useEffect } from 'react';
import { authAPI } from '../services/api';

const AuthContext = createContext(null);

function getInitialUser() {
  try {
    const token = localStorage.getItem('token');
    const savedUser = localStorage.getItem('user');
    if (token && savedUser) return JSON.parse(savedUser);
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
        const freshUser = {
          id: userData.id,
          name: userData.name,
          email: userData.email,
          role: userData.role,
          status: userData.status,
        };
        localStorage.setItem('user', JSON.stringify(freshUser));
        setUser(freshUser);
      })
      .catch(() => {
        localStorage.removeItem('token');
        localStorage.removeItem('user');
        setUser(null);
      })
      .finally(() => setLoading(false));
  }, []);

  const login = async (email, password, adminAccessCode) => {
    const payload = { email, password };
    if (adminAccessCode) {
      payload.admin_access_code = adminAccessCode;
    }

    const response = await authAPI.login(payload);
    const { data } = response.data;

    localStorage.setItem('token', data.token);
    localStorage.setItem('user', JSON.stringify(data.user));
    setUser(data.user);

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
