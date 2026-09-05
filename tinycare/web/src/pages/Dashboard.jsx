import { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import api from '../services/api';
import { useAuth } from '../context/AuthContext';

export default function Dashboard() {
  const [stats, setStats] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const { user } = useAuth();
  const navigate = useNavigate();

  async function loadDashboard() {
    try {
      const res = await api.get('/admin/dashboard');
      setStats(res.data.data);
    } catch {
      setError('Gagal memuat dashboard');
    } finally {
      setLoading(false);
    }
  }

  useEffect(() => { loadDashboard(); }, []);

  const s = stats?.statistics || {};

  const getGreeting = () => {
    const hour = new Date().getHours();
    if (hour < 12) return 'Selamat pagi';
    if (hour < 17) return 'Selamat siang';
    return 'Selamat malam';
  };

  const formatCurrency = (v) => {
    if (!v) return 'Rp 0';
    return new Intl.NumberFormat('id-ID', { style: 'currency', currency: 'IDR', maximumFractionDigits: 0 }).format(v);
  };

  const statCards = [
    { label: 'Total Anak', value: s.total_children || 0, icon: 'child', accent: 'var(--color-primary)', to: '/children' },
    { label: 'Total Orang Tua', value: s.total_parents || 0, icon: 'users', accent: 'var(--color-success)', to: '/users?filter=parent' },
    { label: 'Pengguna Menunggu', value: s.pending_parents ?? 0, icon: 'pending', accent: 'var(--color-warning)', to: '/users?filter=pending' },
    { label: 'Informasi Anak', value: s.total_child_information || 0, icon: 'info', accent: 'var(--color-info)', to: '/child-information' },
    { label: 'Invoice Pending', value: s.pending_invoices || 0, icon: 'invoice', accent: 'var(--color-warning)', to: '/invoices?filter=pending' },
    { label: 'Total Pendapatan', value: formatCurrency(s.total_revenue), icon: 'revenue', accent: 'var(--color-accent)', to: '/payments' },
  ];

  if (loading) {
    return (
      <div className="tc-loading-screen">
        <div className="tc-spinner tc-spinner-lg"></div>
        <p>Memuat dashboard...</p>
      </div>
    );
  }

  if (error) {
    return (
      <div className="tc-error-state">
        <div className="tc-error-state-icon">
          <svg width="28" height="28" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8"><circle cx="12" cy="12" r="10"/><line x1="12" y1="8" x2="12" y2="12"/><line x1="12" y1="16" x2="12.01" y2="16"/></svg>
        </div>
        <p className="tc-empty-state-title">{error}</p>
        <button onClick={loadDashboard} className="tc-btn tc-btn-secondary tc-btn-sm" style={{ marginTop: '12px' }}>Coba Lagi</button>
      </div>
    );
  }

  const statIcon = (name, color) => {
    const s = { width: 18, height: 18, viewBox: '0 0 24 24', fill: 'none', stroke: color, strokeWidth: 1.8, strokeLinecap: 'round', strokeLinejoin: 'round' };
    switch (name) {
      case 'child': return <svg {...s}><circle cx="12" cy="8" r="4"/><path d="M5 20c0-4 3.5-7 7-7s7 3 7 7"/></svg>;
      case 'users': return <svg {...s}><path d="M17 21v-2a4 4 0 00-4-4H5a4 4 0 00-4 4v2"/><circle cx="9" cy="7" r="4"/><path d="M23 21v-2a4 4 0 00-3-3.87"/><path d="M16 3.13a4 4 0 010 7.75"/></svg>;
      case 'check': return <svg {...s}><path d="M9 11l3 3L22 4"/><path d="M21 12v7a2 2 0 01-2 2H5a2 2 0 01-2-2V5a2 2 0 012-2h11"/></svg>;
      case 'info': return <svg {...s}><circle cx="12" cy="12" r="10"/><line x1="12" y1="16" x2="12" y2="12"/><line x1="12" y1="8" x2="12.01" y2="8"/></svg>;
      case 'pending': return <svg {...s}><circle cx="12" cy="12" r="10"/><polyline points="12 6 12 12 16 14"/></svg>;
      case 'invoice': return <svg {...s}><path d="M14 2H6a2 2 0 00-2 2v16a2 2 0 002 2h12a2 2 0 002-2V8z"/><polyline points="14 2 14 8 20 8"/><line x1="9" y1="13" x2="15" y2="13"/><line x1="9" y1="17" x2="15" y2="17"/></svg>;
      case 'revenue': return <svg {...s}><line x1="12" y1="1" x2="12" y2="23"/><path d="M17 5H9.5a3.5 3.5 0 000 7h5a3.5 3.5 0 010 7H6"/></svg>;
      default: return null;
    }
  };

  const cardStyle = () => ({
    display: 'block',
    textDecoration: 'none',
    color: 'inherit',
    cursor: 'pointer',
    border: '1px solid var(--color-border-light)',
    borderRadius: 'var(--radius-2xl)',
    background: 'var(--color-surface)',
    padding: '20px',
    boxShadow: 'var(--shadow-sm)',
    transition: 'transform 0.2s ease, box-shadow 0.2s ease, border-color 0.2s ease',
  });

  return (
    <div>
      {/* Hero Greeting */}
      <div style={{
        padding: '28px 32px',
        background: 'var(--color-primary-subtle)',
        borderRadius: 'var(--radius-2xl)',
        border: '1px solid var(--color-primary-lighter)',
        marginBottom: '28px',
      }}>
        <h1 style={{ fontSize: '24px', fontWeight: '700', marginBottom: '4px', letterSpacing: '-0.02em' }}>
          {getGreeting()}, {user?.name?.split(' ')[0]}
        </h1>
        <p style={{ fontSize: '14px', color: 'var(--color-text-secondary)', lineHeight: 1.5 }}>
          Berikut ringkasan TinyCare hari ini.
        </p>
      </div>

      {/* Stat Cards */}
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(200px, 1fr))', gap: '16px', marginBottom: '28px' }}>
        {statCards.map((card) => (
          <button
            key={card.label}
            onClick={() => navigate(card.to)}
            className="tc-card tc-card-hover"
            style={{ ...cardStyle(), textAlign: 'left', width: '100%', fontFamily: 'inherit' }}
            aria-label={`Lihat ${card.label}`}
            title={`Lihat ${card.label}`}
          >
            <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: '12px' }}>
              <p style={{ fontSize: '12px', fontWeight: '500', color: 'var(--color-text-muted)' }}>{card.label}</p>
              <div style={{
                width: '32px', height: '32px', borderRadius: 'var(--radius-md)',
                background: `color-mix(in srgb, ${card.accent} 10%, transparent)`,
                display: 'flex', alignItems: 'center', justifyContent: 'center',
              }}>
                {statIcon(card.icon, card.accent)}
              </div>
            </div>
            <p style={{ fontSize: '26px', fontWeight: '700', lineHeight: 1 }}>{card.value}</p>
          </button>
        ))}
      </div>

      {/* Content Grid */}
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(360px, 1fr))', gap: '20px' }}>
        {/* Recent Daily Stories */}
        <div className="tc-card" style={{ padding: '24px' }}>
          <h2 style={{ fontSize: '14px', fontWeight: '700', marginBottom: '16px', letterSpacing: '-0.01em' }}>Cerita Hari Ini</h2>
          {stats?.recent_daily_stories?.length > 0 ? (
            <div style={{ display: 'flex', flexDirection: 'column', gap: '8px' }}>
              {stats.recent_daily_stories.map((story) => (
                <div key={story.id} style={{
                  display: 'flex', alignItems: 'flex-start', gap: '12px',
                  padding: '12px', borderRadius: 'var(--radius-lg)', background: 'var(--color-bg-alt)',
                }}>
                  <div style={{
                    width: '34px', height: '34px', borderRadius: 'var(--radius-full)',
                    background: 'var(--color-primary-lighter)',
                    display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0,
                  }}>
                    <span style={{ color: 'var(--color-primary)', fontWeight: '700', fontSize: '12px' }}>
                      {story.child?.name?.charAt(0)}
                    </span>
                  </div>
                  <div style={{ minWidth: 0 }}>
                    <p style={{ fontSize: '13px', fontWeight: '600' }}>{story.child?.name}</p>
                    <p style={{ fontSize: '12px', color: 'var(--color-text-muted)', marginTop: '2px' }} className="tc-truncate">
                      {story.summary || story.mood}
                    </p>
                  </div>
                </div>
              ))}
            </div>
          ) : (
            <div className="tc-empty-state" style={{ padding: '24px 16px' }}>
              <p className="tc-empty-state-desc">Belum ada cerita hari ini.</p>
            </div>
          )}
        </div>

        {/* Recent Child Information */}
        <div className="tc-card" style={{ padding: '24px' }}>
          <h2 style={{ fontSize: '14px', fontWeight: '700', marginBottom: '16px', letterSpacing: '-0.01em' }}>Informasi Anak Terbaru</h2>
          {stats?.recent_child_information?.length > 0 ? (
            <div style={{ display: 'flex', flexDirection: 'column', gap: '8px' }}>
              {stats.recent_child_information.map((info) => (
                <div key={info.id} style={{
                  display: 'flex', alignItems: 'flex-start', gap: '12px',
                  padding: '12px', borderRadius: 'var(--radius-lg)', background: 'var(--color-bg-alt)',
                }}>
                  <div style={{
                    width: '34px', height: '34px', borderRadius: 'var(--radius-md)',
                    background: 'var(--color-info-bg)',
                    display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0,
                  }}>
                    <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="var(--color-info)" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                      <circle cx="12" cy="12" r="10"/><line x1="12" y1="16" x2="12" y2="12"/><line x1="12" y1="8" x2="12.01" y2="8"/>
                    </svg>
                  </div>
                  <div style={{ minWidth: 0 }}>
                    <p style={{ fontSize: '13px', fontWeight: '600' }}>{info.child?.name}</p>
                    <p style={{ fontSize: '12px', color: 'var(--color-text-muted)', marginTop: '2px' }} className="tc-truncate">
                      {info.title || info.type}
                    </p>
                  </div>
                </div>
              ))}
            </div>
          ) : (
            <div className="tc-empty-state" style={{ padding: '24px 16px' }}>
              <p className="tc-empty-state-desc">Belum ada informasi anak.</p>
            </div>
          )}
        </div>

        {/* Recent Feedback */}
        <div className="tc-card" style={{ padding: '24px' }}>
          <h2 style={{ fontSize: '14px', fontWeight: '700', marginBottom: '16px', letterSpacing: '-0.01em' }}>Feedback Terbaru</h2>
          {stats?.recent_feedback?.length > 0 ? (
            <div style={{ display: 'flex', flexDirection: 'column', gap: '8px' }}>
              {stats.recent_feedback.map((fb) => (
                <div key={fb.id} style={{
                  padding: '12px', borderRadius: 'var(--radius-lg)', background: 'var(--color-bg-alt)',
                }}>
                  <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: '4px' }}>
                    <p style={{ fontSize: '13px', fontWeight: '600' }}>{fb.subject || 'Feedback'}</p>
                    {fb.rating && <span style={{ color: 'var(--color-accent)', fontSize: '12px' }}>{'★'.repeat(fb.rating)}{'☆'.repeat(5 - fb.rating)}</span>}
                  </div>
                  <p style={{ fontSize: '12px', color: 'var(--color-text-muted)' }} className="tc-truncate">{fb.message}</p>
                </div>
              ))}
            </div>
          ) : (
            <div className="tc-empty-state" style={{ padding: '24px 16px' }}>
              <p className="tc-empty-state-desc">Belum ada feedback.</p>
            </div>
          )}
        </div>
      </div>
    </div>
  );
}
