import { useState, useEffect } from 'react';
import { authAPI } from '../services/api';
import { useAuth } from '../context/AuthContext';

export default function Profile() {
  const { user, logout } = useAuth();
  const [profile, setProfile] = useState(user);
  const [loadingProfile, setLoadingProfile] = useState(true);
  const [formData, setFormData] = useState({ current_password: '', password: '', password_confirmation: '' });
  const [submitting, setSubmitting] = useState(false);
  const [toast, setToast] = useState(null);
  const [showPassword, setShowPassword] = useState(false);

  useEffect(() => {
    authAPI.me()
      .then((meRes) => setProfile(meRes.data.data))
      .catch(() => {})
      .finally(() => setLoadingProfile(false));
  }, []);

  const handleChangePassword = async (e) => {
    e.preventDefault();
    setSubmitting(true);
    setToast(null);
    try {
      const res = await authAPI.changePassword({
        current_password: formData.current_password,
        password: formData.password,
        password_confirmation: formData.password_confirmation,
      });
      setToast({ type: 'success', message: res.data.message || 'Password berhasil diubah.' });
      setFormData({ current_password: '', password: '', password_confirmation: '' });
    } catch (err) {
      const msg = err.response?.data?.message;
      const errors = err.response?.data?.errors;
      const detail = errors ? Object.values(errors).flat().join(', ') : null;
      setToast({ type: 'error', message: detail || msg || 'Gagal mengubah password.' });
    } finally {
      setSubmitting(false);
    }
  };

  if (loadingProfile) {
    return <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'center', height: '300px' }}><div className="tc-spinner"></div></div>;
  }

  const p = profile || user;

  return (
    <div>
      <div className="tc-page-header">
        <h1>Profil</h1>
        <p>Informasi akun dan keamanan Anda</p>
      </div>

      {toast && (
        <div className={`tc-toast tc-toast-${toast.type}`} style={{ marginBottom: '16px' }}>
          {toast.message}
        </div>
      )}

      {/* Profile Card */}
      <div className="tc-card" style={{ padding: '32px', marginBottom: '20px', textAlign: 'center' }}>
        <div style={{
          width: '80px', height: '80px', borderRadius: '50%',
          background: 'var(--color-primary-lighter)', display: 'flex',
          alignItems: 'center', justifyContent: 'center', margin: '0 auto 16px',
        }}>
          <span style={{ color: 'var(--color-primary)', fontWeight: '700', fontSize: '32px' }}>
            {p?.name?.charAt(0) || '?'}
          </span>
        </div>
        <h2 style={{ fontSize: '20px', fontWeight: '700', marginBottom: '4px' }}>{p?.name || '-'}</h2>
        <p style={{ fontSize: '14px', color: 'var(--color-text-secondary)', marginBottom: '12px' }}>{p?.email || '-'}</p>
        <span className={p?.role === 'admin_master' ? 'tc-badge tc-badge-primary' : 'tc-badge tc-badge-info'}>
          {p?.role === 'admin_master' ? 'Admin Master' : 'Admin'}
        </span>
      </div>

      {/* Account Info */}
      <div className="tc-card" style={{ padding: '24px' }}>
        <h3 style={{ fontSize: '15px', fontWeight: '700', marginBottom: '16px' }}>Informasi Akun</h3>
        <div style={{ display: 'flex', flexDirection: 'column', gap: '12px' }}>
          {[
            { label: 'Nama', value: p?.name || '-' },
            { label: 'Email', value: p?.email || '-' },
            { label: 'Nomor HP', value: p?.phone || '-' },
            { label: 'Role', value: p?.role === 'admin_master' ? 'Admin Master' : 'Admin' },
            { label: 'Status', value: p?.status === 'active' ? 'Aktif' : (p?.status || '-') },
          ].map((item) => (
            <div key={item.label} style={{
              display: 'flex', justifyContent: 'space-between', padding: '10px 0',
              borderBottom: '1px solid var(--color-border-light)',
            }}>
              <span style={{ fontSize: '13px', color: 'var(--color-text-muted)' }}>{item.label}</span>
              <span style={{ fontSize: '13px', fontWeight: '500' }}>{item.value}</span>
            </div>
          ))}
        </div>
      </div>

      {/* Change Password */}
      <div className="tc-card" style={{ padding: '24px', marginTop: '16px' }}>
        <h3 style={{ fontSize: '15px', fontWeight: '700', marginBottom: '4px' }}>Ubah Password</h3>
        <p style={{ fontSize: '13px', color: 'var(--color-text-muted)', marginBottom: '16px' }}>
          Gunakan minimal 8 karakter untuk password baru.
        </p>
        <form onSubmit={handleChangePassword} style={{ display: 'flex', flexDirection: 'column', gap: '14px', maxWidth: '440px' }}>
          <div>
            <label className="tc-label">Password Lama *</label>
            <input
              type={showPassword ? 'text' : 'password'}
              value={formData.current_password}
              onChange={(e) => setFormData({ ...formData, current_password: e.target.value })}
              className="tc-input"
              placeholder="Masukkan password lama"
              required
              autoComplete="current-password"
            />
          </div>
          <div>
            <label className="tc-label">Password Baru *</label>
            <input
              type={showPassword ? 'text' : 'password'}
              value={formData.password}
              onChange={(e) => setFormData({ ...formData, password: e.target.value })}
              className="tc-input"
              placeholder="Minimal 8 karakter"
              required
              minLength={8}
              autoComplete="new-password"
            />
          </div>
          <div>
            <label className="tc-label">Konfirmasi Password Baru *</label>
            <input
              type={showPassword ? 'text' : 'password'}
              value={formData.password_confirmation}
              onChange={(e) => setFormData({ ...formData, password_confirmation: e.target.value })}
              className="tc-input"
              placeholder="Ulangi password baru"
              required
              minLength={8}
              autoComplete="new-password"
            />
          </div>
          <div style={{ display: 'flex', alignItems: 'center', gap: '8px', fontSize: '13px', color: 'var(--color-text-muted)' }}>
            <input
              type="checkbox"
              id="show-pass"
              checked={showPassword}
              onChange={(e) => setShowPassword(e.target.checked)}
              style={{ accentColor: 'var(--color-primary)' }}
            />
            <label htmlFor="show-pass" style={{ cursor: 'pointer' }}>Tampilkan password</label>
          </div>
          <div style={{ marginTop: '4px' }}>
            <button type="submit" disabled={submitting} className="tc-btn tc-btn-primary" style={{ width: '100%' }}>
              {submitting ? 'Menyimpan...' : 'Ubah Password'}
            </button>
          </div>
          {toast && (
            <p style={{ fontSize: '13px', fontWeight: '500', color: toast.type === 'success' ? 'var(--color-success)' : 'var(--color-error)' }}>
              {toast.message}
            </p>
          )}
        </form>
      </div>

      {/* Logout Button */}
      <div style={{ marginTop: '24px' }}>
        <button onClick={logout} className="tc-btn tc-btn-secondary" style={{ width: '100%', color: 'var(--color-error)' }}>
          Keluar
        </button>
      </div>
    </div>
  );
}