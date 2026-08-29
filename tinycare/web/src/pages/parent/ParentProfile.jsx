import { useState, useEffect } from 'react';
import { parentAPI, authAPI } from '../../services/api';
import { useAuth } from '../../context/AuthContext';

export default function ParentProfile() {
  const { user, logout } = useAuth();
  const [profile, setProfile] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error] = useState('');

  useEffect(() => {
    parentAPI.children()
      .then(() => {
        authAPI.me()
          .then((meRes) => {
            setProfile(meRes.data.data);
            setLoading(false);
          })
          .catch(() => {
            setProfile(user);
            setLoading(false);
          });
      })
      .catch(() => {
        setProfile(user);
        setLoading(false);
      });
  }, [user]);

  if (loading) return <div className="tc-loading-screen"><div className="tc-spinner tc-spinner-lg"></div><p>Memuat profil...</p></div>;

  if (error) return (
    <div className="tc-error-state">
      <div className="tc-error-state-icon">
        <svg width="28" height="28" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8"><circle cx="12" cy="12" r="10"/><line x1="12" y1="8" x2="12" y2="12"/><line x1="12" y1="16" x2="12.01" y2="16"/></svg>
      </div>
      <p className="tc-empty-state-title">{error}</p>
      <button onClick={() => window.location.reload()} className="tc-btn tc-btn-secondary tc-btn-sm" style={{ marginTop: '12px' }}>Coba Lagi</button>
    </div>
  );

  const p = profile || user;

  return (
    <div>
      <div className="tc-page-header">
        <h1>Profil</h1>
        <p>Informasi akun Anda</p>
      </div>

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
        <span className="tc-badge tc-badge-success">Orang Tua</span>
      </div>

      {/* Account Info */}
      <div className="tc-card" style={{ padding: '24px' }}>
        <h3 style={{ fontSize: '15px', fontWeight: '700', marginBottom: '16px' }}>Informasi Akun</h3>
        <div style={{ display: 'flex', flexDirection: 'column', gap: '12px' }}>
          {[
            { label: 'Nama', value: p?.name || '-' },
            { label: 'Email', value: p?.email || '-' },
            { label: 'Nomor HP', value: p?.phone || '-' },
            { label: 'Role', value: 'Orang Tua' },
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

      {/* App Info */}
      <div className="tc-card" style={{ padding: '24px', marginTop: '16px' }}>
        <h3 style={{ fontSize: '15px', fontWeight: '700', marginBottom: '16px' }}>Tentang Aplikasi</h3>
        <div style={{ display: 'flex', flexDirection: 'column', gap: '12px' }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', padding: '10px 0' }}>
            <span style={{ fontSize: '13px', color: 'var(--color-text-muted)' }}>Aplikasi</span>
            <span style={{ fontSize: '13px', fontWeight: '500' }}>TinyCare</span>
          </div>
          <div style={{ display: 'flex', justifyContent: 'space-between', padding: '10px 0' }}>
            <span style={{ fontSize: '13px', color: 'var(--color-text-muted)' }}>Versi</span>
            <span style={{ fontSize: '13px', fontWeight: '500' }}>1.0.0</span>
          </div>
        </div>
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
