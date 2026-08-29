import { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuth } from '../context/AuthContext';
import { useTheme } from '../context/ThemeContext';

function EyeIcon({ passwordHidden }) {
  // Icon shows the ACTION that will happen on tap:
  // passwordHidden=true  -> show open eye (action: "show password")
  // passwordHidden=false -> show crossed eye (action: "hide password")
  return passwordHidden ? (
    <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round">
      <path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z"/>
      <circle cx="12" cy="12" r="3"/>
    </svg>
  ) : (
    <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round">
      <path d="M17.94 17.94A10.07 10.07 0 0112 20c-7 0-11-8-11-8a18.45 18.45 0 015.06-5.94M9.9 4.24A9.12 9.12 0 0112 4c7 0 11 8 11 8a18.5 18.5 0 01-2.16 3.19m-6.72-1.07a3 3 0 11-4.24-4.24"/>
      <line x1="1" y1="1" x2="23" y2="23"/>
    </svg>
  );
}

export default function Login() {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [adminAccessCode, setAdminAccessCode] = useState('');
  const [showPassword, setShowPassword] = useState(false);
  const [showAccessCode, setShowAccessCode] = useState(false);
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);
  const { login } = useAuth();
  const navigate = useNavigate();
  const { theme, setTheme } = useTheme();

  const handleSubmit = async (e) => {
    e.preventDefault();
    setError('');
    setLoading(true);

    try {
      const data = await login(email, password, adminAccessCode || undefined);

      // Role-based redirect
      if (data.user.role === 'admin' || data.user.role === 'admin_master') {
        navigate('/dashboard');
      } else if (data.user.role === 'parent') {
        navigate('/parent');
      } else {
        setError(`Role "${data.user.role}" tidak memiliki akses ke aplikasi ini.`);
        localStorage.removeItem('token');
        localStorage.removeItem('user');
      }
    } catch (err) {
      const errors = err.response?.data?.errors;
      const message = err.response?.data?.message;

      if (errors?.admin_access_code) {
        setError(Array.isArray(errors.admin_access_code) ? errors.admin_access_code[0] : errors.admin_access_code);
      } else if (errors?.email) {
        setError(Array.isArray(errors.email) ? errors.email[0] : errors.email);
      } else {
        setError(message || 'Login gagal. Periksa email dan password.');
      }
    } finally {
      setLoading(false);
    }
  };

  const inputWrap = {
    position: 'relative',
  };

  const inputStyle = {
    width: '100%',
    padding: '12px 16px',
    fontSize: '14px',
    borderRadius: '12px',
    border: '1.5px solid var(--color-border)',
    background: 'var(--color-surface)',
    color: 'var(--color-text)',
    outline: 'none',
    transition: 'border-color 0.2s, box-shadow 0.2s',
    boxSizing: 'border-box',
  };

  const eyeBtnStyle = {
    position: 'absolute',
    right: '12px',
    top: '50%',
    transform: 'translateY(-50%)',
    background: 'none',
    border: 'none',
    cursor: 'pointer',
    color: 'var(--color-text-muted)',
    padding: '4px',
    display: 'flex',
    alignItems: 'center',
    justifyContent: 'center',
  };

  return (
    <div className="login-page" style={{
      minHeight: '100vh',
      display: 'flex',
      background: 'var(--color-bg)',
    }}>
      {/* Left Side - Brand */}
      <div className="login-brand" style={{
        flex: '1',
        display: 'flex',
        flexDirection: 'column',
        justifyContent: 'center',
        alignItems: 'center',
        padding: '48px',
        background: 'linear-gradient(135deg, var(--color-primary-lighter) 0%, var(--color-bg) 100%)',
        borderRight: '1px solid var(--color-border)',
        position: 'relative',
        overflow: 'hidden',
      }}>
        <div style={{
          position: 'absolute', top: '-80px', right: '-80px',
          width: '300px', height: '300px', borderRadius: '50%',
          background: 'var(--color-primary)', opacity: '0.06',
        }} />
        <div style={{
          position: 'absolute', bottom: '-60px', left: '-60px',
          width: '200px', height: '200px', borderRadius: '50%',
          background: 'var(--color-primary)', opacity: '0.04',
        }} />

        <div style={{ maxWidth: '380px', textAlign: 'center', position: 'relative', zIndex: 1 }}>
          <div style={{
            width: '80px', height: '80px', borderRadius: '22px',
            background: 'var(--color-primary)',
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            margin: '0 auto 32px',
            boxShadow: '0 8px 32px rgba(74,140,111,0.25)',
          }}>
            <svg width="40" height="40" viewBox="0 0 32 32" fill="none">
              <path d="M16 28s-11-7.2-11-15.2C5 9.2 7.2 7 10 7c1.8 0 3.4 1 4 2.5C14.6 8 16.2 7 18 7c2.8 0 5 2.2 5 5.8C23 20.8 16 28 16 28z" fill="white"/>
            </svg>
          </div>

          <h1 style={{
            fontSize: '32px', fontWeight: '800',
            color: 'var(--color-text)', marginBottom: '10px',
            letterSpacing: '-0.03em',
          }}>
            TinyCare
          </h1>
          <p style={{
            fontSize: '16px', color: 'var(--color-text-secondary)',
            lineHeight: '1.6', marginBottom: '40px',
          }}>
            Care that feels personal.
          </p>

          <div style={{
            display: 'flex', gap: '28px', justifyContent: 'center',
          }}>
            {[
              { icon: '🔒', label: 'Secure' },
              { icon: '💚', label: 'Caring' },
              { icon: '📊', label: 'Insightful' },
            ].map((item) => (
              <div key={item.label} style={{ textAlign: 'center' }}>
                <div style={{ fontSize: '22px', marginBottom: '6px' }}>{item.icon}</div>
                <p style={{ fontSize: '12px', color: 'var(--color-text-muted)', fontWeight: '500' }}>{item.label}</p>
              </div>
            ))}
          </div>
        </div>
      </div>

      {/* Right Side - Login Form */}
      <div style={{
        flex: '1',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        padding: '48px',
        position: 'relative',
      }}>
        {/* Theme Toggle */}
        <button
          onClick={() => setTheme(theme === 'dark' ? 'light' : 'dark')}
          style={{
            position: 'absolute', top: '20px', right: '20px',
            padding: '8px', borderRadius: '10px',
            border: '1.5px solid var(--color-border)',
            background: 'var(--color-surface)',
            color: 'var(--color-text-secondary)',
            cursor: 'pointer',
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            width: '38px', height: '38px',
            transition: 'all 0.2s',
          }}
          title={theme === 'dark' ? 'Switch to Light' : 'Switch to Dark'}
        >
          {theme === 'dark' ? (
            <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
              <circle cx="12" cy="12" r="5"/><line x1="12" y1="1" x2="12" y2="3"/><line x1="12" y1="21" x2="12" y2="23"/><line x1="4.22" y1="4.22" x2="5.64" y2="5.64"/><line x1="18.36" y1="18.36" x2="19.78" y2="19.78"/><line x1="1" y1="12" x2="3" y2="12"/><line x1="21" y1="12" x2="23" y2="12"/><line x1="4.22" y1="19.78" x2="5.64" y2="18.36"/><line x1="18.36" y1="5.64" x2="19.78" y2="4.22"/>
            </svg>
          ) : (
            <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
              <path d="M21 12.79A9 9 0 1111.21 3 7 7 0 0021 12.79z"/>
            </svg>
          )}
        </button>

        <div style={{ width: '100%', maxWidth: '380px' }}>
          {/* Mobile Logo */}
          <div className="login-mobile-logo" style={{
            display: 'none',
            textAlign: 'center',
            marginBottom: '32px',
          }}>
            <div style={{
              width: '60px', height: '60px', borderRadius: '18px',
              background: 'var(--color-primary)',
              display: 'flex', alignItems: 'center', justifyContent: 'center',
              margin: '0 auto 16px',
              boxShadow: '0 6px 24px rgba(74,140,111,0.25)',
            }}>
              <svg width="30" height="30" viewBox="0 0 32 32" fill="none">
                <path d="M16 28s-11-7.2-11-15.2C5 9.2 7.2 7 10 7c1.8 0 3.4 1 4 2.5C14.6 8 16.2 7 18 7c2.8 0 5 2.2 5 5.8C23 20.8 16 28 16 28z" fill="white"/>
              </svg>
            </div>
            <h1 style={{ fontSize: '26px', fontWeight: '800', color: 'var(--color-text)' }}>TinyCare</h1>
          </div>

          <div>
            <h2 style={{
              fontSize: '24px', fontWeight: '700',
              marginBottom: '6px', color: 'var(--color-text)',
            }}>Masuk</h2>
            <p style={{
              fontSize: '14px', color: 'var(--color-text-secondary)',
              marginBottom: '32px',
            }}>Masukkan akun Anda untuk melanjutkan</p>
          </div>

          {error && (
            <div style={{
              padding: '12px 16px',
              background: 'var(--color-error-bg)',
              border: '1px solid var(--color-error)',
              borderRadius: '12px',
              color: 'var(--color-error)',
              fontSize: '13px',
              marginBottom: '20px',
              display: 'flex',
              alignItems: 'flex-start',
              gap: '10px',
              lineHeight: '1.5',
            }}>
              <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" style={{ flexShrink: 0, marginTop: '1px' }}>
                <circle cx="12" cy="12" r="10"/>
                <line x1="12" y1="8" x2="12" y2="12"/>
                <line x1="12" y1="16" x2="12.01" y2="16"/>
              </svg>
              {error}
            </div>
          )}

          <form onSubmit={handleSubmit}>
            <div style={{ marginBottom: '18px' }}>
              <label style={{ display: 'block', fontSize: '13px', fontWeight: '600', color: 'var(--color-text)', marginBottom: '6px' }}>Email</label>
              <input
                type="email"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                style={inputStyle}
                placeholder="email@tinycare.com"
                required
                autoComplete="email"
                onFocus={(e) => { e.target.style.borderColor = 'var(--color-primary)'; e.target.style.boxShadow = '0 0 0 3px rgba(74,140,111,0.12)'; }}
                onBlur={(e) => { e.target.style.borderColor = 'var(--color-border)'; e.target.style.boxShadow = 'none'; }}
              />
            </div>

            <div style={{ marginBottom: '18px' }}>
              <label style={{ display: 'block', fontSize: '13px', fontWeight: '600', color: 'var(--color-text)', marginBottom: '6px' }}>Password</label>
              <div style={inputWrap}>
                <input
                  type={showPassword ? 'text' : 'password'}
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                  style={{ ...inputStyle, paddingRight: '44px' }}
                  placeholder="••••••••"
                  required
                  autoComplete="current-password"
                  onFocus={(e) => { e.target.style.borderColor = 'var(--color-primary)'; e.target.style.boxShadow = '0 0 0 3px rgba(74,140,111,0.12)'; }}
                  onBlur={(e) => { e.target.style.borderColor = 'var(--color-border)'; e.target.style.boxShadow = 'none'; }}
                />
                <button
                  type="button"
                  onClick={() => setShowPassword(!showPassword)}
                  style={eyeBtnStyle}
                  aria-label={showPassword ? 'Sembunyikan password' : 'Perlihatkan password'}
                  title={showPassword ? 'Sembunyikan password' : 'Perlihatkan password'}
                >
                  <EyeIcon passwordHidden={!showPassword} />
                </button>
              </div>
            </div>

            <div style={{ marginBottom: '28px' }}>
              <label style={{ display: 'block', fontSize: '13px', fontWeight: '600', color: 'var(--color-text)', marginBottom: '6px' }}>Kode Akses Admin</label>
              <div style={inputWrap}>
                <input
                  type={showAccessCode ? 'text' : 'password'}
                  value={adminAccessCode}
                  onChange={(e) => setAdminAccessCode(e.target.value)}
                  style={{ ...inputStyle, paddingRight: '44px' }}
                  placeholder="Masukkan kode akses admin"
                  autoComplete="off"
                  onFocus={(e) => { e.target.style.borderColor = 'var(--color-primary)'; e.target.style.boxShadow = '0 0 0 3px rgba(74,140,111,0.12)'; }}
                  onBlur={(e) => { e.target.style.borderColor = 'var(--color-border)'; e.target.style.boxShadow = 'none'; }}
                />
                <button
                  type="button"
                  onClick={() => setShowAccessCode(!showAccessCode)}
                  style={eyeBtnStyle}
                  aria-label={showAccessCode ? 'Sembunyikan kode akses' : 'Perlihatkan kode akses'}
                  title={showAccessCode ? 'Sembunyikan kode akses' : 'Perlihatkan kode akses'}
                >
                  <EyeIcon passwordHidden={!showAccessCode} />
                </button>
              </div>
              <p style={{ fontSize: '12px', color: 'var(--color-text-muted)', marginTop: '6px' }}>
                Kosongkan jika Anda masuk sebagai orang tua.
              </p>
            </div>

            <button
              type="submit"
              disabled={loading}
              style={{
                width: '100%',
                padding: '13px 20px',
                fontSize: '14px',
                fontWeight: '600',
                borderRadius: '12px',
                border: 'none',
                background: 'var(--color-primary)',
                color: 'white',
                cursor: loading ? 'not-allowed' : 'pointer',
                opacity: loading ? 0.7 : 1,
                transition: 'all 0.2s',
                boxShadow: '0 4px 12px rgba(74,140,111,0.25)',
              }}
            >
              {loading ? (
                <span style={{ display: 'flex', alignItems: 'center', gap: '8px', justifyContent: 'center' }}>
                  <div className="tc-spinner" style={{ width: '18px', height: '18px', borderWidth: '2px' }}></div>
                  Memproses...
                </span>
              ) : (
                'Masuk'
              )}
            </button>
          </form>

          <p style={{ textAlign: 'center', marginTop: '20px', fontSize: '13px', color: 'var(--color-text-muted)' }}>
            Belum punya akun? <a href="/register" style={{ color: 'var(--color-primary)', fontWeight: '600', textDecoration: 'none' }}>Daftar</a>
          </p>

          <p style={{
            textAlign: 'center',
            color: 'var(--color-text-muted)',
            fontSize: '12px',
            marginTop: '36px',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            gap: '6px',
          }}>
            <svg width="14" height="14" viewBox="0 0 32 32" fill="var(--color-text-muted)">
              <path d="M16 28s-11-7.2-11-15.2C5 9.2 7.2 7 10 7c1.8 0 3.4 1 4 2.5C14.6 8 16.2 7 18 7c2.8 0 5 2.2 5 5.8C23 20.8 16 28 16 28z"/>
            </svg>
            TinyCare — Secure & Caring
          </p>
        </div>
      </div>

      <style>{`
        @media (max-width: 768px) {
          .login-brand { display: none !important; }
          .login-mobile-logo { display: block !important; }
        }
      `}</style>
    </div>
  );
}
