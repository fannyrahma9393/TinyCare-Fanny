import { useState } from 'react';
import { Link } from 'react-router-dom';
import { useTranslation } from 'react-i18next';
import { authAPI } from '../services/api';
import LanguageSwitcher from '../components/LanguageSwitcher';

function EyeIcon({ visible }) {
  return visible ? (
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

export default function Register() {
  const [form, setForm] = useState({
    name: '', email: '', phone: '', password: '', password_confirmation: '', address: '',
  });
  const [showPassword, setShowPassword] = useState(false);
  const [showConfirm, setShowConfirm] = useState(false);
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);
  const [success, setSuccess] = useState(false);
  const { t } = useTranslation();

  const handleChange = (e) => {
    setForm({ ...form, [e.target.name]: e.target.value });
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    setError('');

    if (form.password !== form.password_confirmation) {
      setError(t('Password dan konfirmasi password tidak cocok.'));
      return;
    }

    setLoading(true);
    try {
      await authAPI.registerParent(form);
      setSuccess(true);
    } catch (err) {
      const errors = err.response?.data?.errors;
      const message = err.response?.data?.message;
      if (errors) {
        const first = Object.values(errors)[0];
        setError(Array.isArray(first) ? first[0] : first);
      } else {
        setError(message || t('Registrasi gagal. Silakan coba lagi.'));
      }
    } finally {
      setLoading(false);
    }
  };

  const inputStyle = {
    width: '100%', padding: '12px 16px', fontSize: '14px', borderRadius: '12px',
    border: '1.5px solid var(--color-border)', background: 'var(--color-surface)',
    color: 'var(--color-text)', outline: 'none', boxSizing: 'border-box',
  };

  const eyeBtnStyle = {
    position: 'absolute', right: '12px', top: '50%', transform: 'translateY(-50%)',
    background: 'none', border: 'none', cursor: 'pointer', color: 'var(--color-text-muted)',
    padding: '4px', display: 'flex', alignItems: 'center', justifyContent: 'center',
  };

  if (success) {
    return (
      <div style={{ minHeight: '100vh', display: 'flex', alignItems: 'center', justifyContent: 'center', background: 'var(--color-bg)', padding: '24px' }}>
        <div style={{
          position: 'absolute', top: '20px', right: '20px',
          display: 'flex', gap: '8px', alignItems: 'center',
        }}>
          <LanguageSwitcher />
        </div>
        <div style={{ maxWidth: '420px', width: '100%', textAlign: 'center' }}>
          <div style={{
            width: '72px', height: '72px', borderRadius: '20px',
            background: 'var(--color-success-bg)', display: 'flex',
            alignItems: 'center', justifyContent: 'center', margin: '0 auto 24px',
          }}>
            <svg width="32" height="32" viewBox="0 0 24 24" fill="none" stroke="var(--color-success)" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
              <path d="M22 11.08V12a10 10 0 11-5.93-9.14"/><polyline points="22 4 12 14.01 9 11.01"/>
            </svg>
          </div>
          <h2 style={{ fontSize: '22px', fontWeight: '700', marginBottom: '10px', color: 'var(--color-text)' }}>{t('Registrasi Berhasil!')}</h2>
          <p style={{ fontSize: '14px', color: 'var(--color-text-secondary)', lineHeight: '1.6', marginBottom: '28px' }}>
            {t('Akun Anda telah dibuat dan ')}<strong>{t('menunggu persetujuan admin')}</strong>{t('. Anda akan dapat login setelah akun disetujui.')}
          </p>
          <Link to="/login" style={{
            display: 'inline-block', padding: '12px 28px', borderRadius: '12px',
            background: 'var(--color-primary)', color: 'white', fontSize: '14px',
            fontWeight: '600', textDecoration: 'none',
          }}>
            {t('Kembali ke Login')}
          </Link>
        </div>
      </div>
    );
  }

  return (
    <div style={{ minHeight: '100vh', display: 'flex', alignItems: 'center', justifyContent: 'center', background: 'var(--color-bg)', padding: '24px' }}>
      <div style={{
        position: 'absolute', top: '20px', right: '20px',
        display: 'flex', gap: '8px', alignItems: 'center',
      }}>
        <LanguageSwitcher />
      </div>
      <div style={{ maxWidth: '440px', width: '100%' }}>
        <div style={{ textAlign: 'center', marginBottom: '32px' }}>
          <div style={{
            width: '64px', height: '64px', borderRadius: '18px',
            background: 'var(--color-primary)', display: 'flex',
            alignItems: 'center', justifyContent: 'center', margin: '0 auto 16px',
            boxShadow: '0 6px 24px rgba(74,140,111,0.25)',
          }}>
            <svg width="28" height="28" viewBox="0 0 32 32" fill="none">
              <path d="M16 28s-11-7.2-11-15.2C5 9.2 7.2 7 10 7c1.8 0 3.4 1 4 2.5C14.6 8 16.2 7 18 7c2.8 0 5 2.2 5 5.8C23 20.8 16 28 16 28z" fill="white"/>
            </svg>
          </div>
          <h1 style={{ fontSize: '24px', fontWeight: '700', color: 'var(--color-text)', marginBottom: '6px' }}>{t('Daftar Akun Orang Tua')}</h1>
          <p style={{ fontSize: '14px', color: 'var(--color-text-secondary)' }}>{t('Buat akun untuk memantau si kecil')}</p>
        </div>

        <div style={{
          padding: '32px', borderRadius: '16px',
          background: 'var(--color-surface)', border: '1px solid var(--color-border)',
          boxShadow: '0 4px 16px rgba(0,0,0,0.04)',
        }}>
          {error && (
            <div style={{
              padding: '12px 16px', background: 'var(--color-error-bg)',
              border: '1px solid var(--color-error)', borderRadius: '12px',
              color: 'var(--color-error)', fontSize: '13px', marginBottom: '20px',
            }}>
              {error}
            </div>
          )}

          <form onSubmit={handleSubmit}>
            <div style={{ marginBottom: '16px' }}>
              <label style={{ display: 'block', fontSize: '13px', fontWeight: '600', color: 'var(--color-text)', marginBottom: '6px' }}>{t('Nama Lengkap *')}</label>
              <input type="text" name="name" value={form.name} onChange={handleChange} style={inputStyle} placeholder={t('Masukkan nama lengkap')} required />
            </div>
            <div style={{ marginBottom: '16px' }}>
              <label style={{ display: 'block', fontSize: '13px', fontWeight: '600', color: 'var(--color-text)', marginBottom: '6px' }}>{t('Email *')}</label>
              <input type="email" name="email" value={form.email} onChange={handleChange} style={inputStyle} placeholder="email@contoh.com" required />
            </div>
            <div style={{ marginBottom: '16px' }}>
              <label style={{ display: 'block', fontSize: '13px', fontWeight: '600', color: 'var(--color-text)', marginBottom: '6px' }}>{t('Nomor HP')}</label>
              <input type="tel" name="phone" value={form.phone} onChange={handleChange} style={inputStyle} placeholder="081234567890" />
            </div>
            <div style={{ marginBottom: '16px' }}>
              <label style={{ display: 'block', fontSize: '13px', fontWeight: '600', color: 'var(--color-text)', marginBottom: '6px' }}>{t('Password *')}</label>
              <div style={{ position: 'relative' }}>
                <input type={showPassword ? 'text' : 'password'} name="password" value={form.password} onChange={handleChange} style={{ ...inputStyle, paddingRight: '44px' }} placeholder={t('Min. 8 karakter')} required minLength="8" />
                <button type="button" onClick={() => setShowPassword(!showPassword)} style={eyeBtnStyle} aria-label={showPassword ? t('Sembunyikan password') : t('Perlihatkan password')}>
                  <EyeIcon visible={showPassword} />
                </button>
              </div>
            </div>
            <div style={{ marginBottom: '16px' }}>
              <label style={{ display: 'block', fontSize: '13px', fontWeight: '600', color: 'var(--color-text)', marginBottom: '6px' }}>{t('Konfirmasi Password *')}</label>
              <div style={{ position: 'relative' }}>
                <input type={showConfirm ? 'text' : 'password'} name="password_confirmation" value={form.password_confirmation} onChange={handleChange} style={{ ...inputStyle, paddingRight: '44px' }} placeholder={t('Ulangi kata sandi')} required minLength="8" />
                <button type="button" onClick={() => setShowConfirm(!showConfirm)} style={eyeBtnStyle} aria-label={showConfirm ? t('Sembunyikan password') : t('Perlihatkan password')}>
                  <EyeIcon visible={showConfirm} />
                </button>
              </div>
            </div>
            <div style={{ marginBottom: '24px' }}>
              <label style={{ display: 'block', fontSize: '13px', fontWeight: '600', color: 'var(--color-text)', marginBottom: '6px' }}>{t('Alamat')}</label>
              <input type="text" name="address" value={form.address} onChange={handleChange} style={inputStyle} placeholder={t('Opsional')} />
            </div>
            <button type="submit" disabled={loading} style={{
              width: '100%', padding: '13px 20px', fontSize: '14px', fontWeight: '600',
              borderRadius: '12px', border: 'none', background: 'var(--color-primary)',
              color: 'white', cursor: loading ? 'not-allowed' : 'pointer',
              opacity: loading ? 0.7 : 1, transition: 'all 0.2s',
            }}>
              {loading ? t('Mendaftar...') : t('Daftar')}
            </button>
          </form>

          <p style={{ textAlign: 'center', marginTop: '20px', fontSize: '13px', color: 'var(--color-text-muted)' }}>
            {t('Sudah punya akun?')} <Link to="/login" style={{ color: 'var(--color-primary)', fontWeight: '600', textDecoration: 'none' }}>{t('Masuk')}</Link>
          </p>
        </div>
      </div>
    </div>
  );
}
