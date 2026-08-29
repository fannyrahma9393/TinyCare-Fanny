import { useState, useEffect } from 'react';
import api from '../services/api';
import { useAuth } from '../context/AuthContext';

export default function Dashboard() {
  const [stats, setStats] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const { user } = useAuth();

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
    { label: 'Total Anak', value: s.total_children || 0, icon: 'child', accent: 'var(--color-primary)' },
    { label: 'Hadir Hari Ini', value: `${s.today_present || 0} / ${s.today_attendance || 0}`, icon: 'check', accent: 'var(--color-success)' },
    { label: 'Invoice Pending', value: s.pending_invoices || 0, icon: 'pending', accent: 'var(--color-warning)' },
    { label: 'Total Pendapatan', value: formatCurrency(s.total_revenue), icon: 'revenue', accent: 'var(--color-accent)' },
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
      case 'check': return <svg {...s}><path d="M9 11l3 3L22 4"/><path d="M21 12v7a2 2 0 01-2 2H5a2 2 0 01-2-2V5a2 2 0 012-2h11"/></svg>;
      case 'pending': return <svg {...s}><circle cx="12" cy="12" r="10"/><polyline points="12 6 12 12 16 14"/></svg>;
      case 'revenue': return <svg {...s}><line x1="12" y1="1" x2="12" y2="23"/><path d="M17 5H9.5a3.5 3.5 0 000 7h5a3.5 3.5 0 010 7H6"/></svg>;
      default: return null;
    }
  };

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
          <div key={card.label} className="tc-card tc-card-hover" style={{ padding: '20px' }}>
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
          </div>
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

        {/* Upcoming Events */}
        <div className="tc-card" style={{ padding: '24px' }}>
          <h2 style={{ fontSize: '14px', fontWeight: '700', marginBottom: '16px', letterSpacing: '-0.01em' }}>Jadwal Mendatang</h2>
          {stats?.upcoming_events?.length > 0 ? (
            <div style={{ display: 'flex', flexDirection: 'column', gap: '8px' }}>
              {stats.upcoming_events.map((event) => (
                <div key={event.id} style={{
                  display: 'flex', alignItems: 'flex-start', gap: '12px',
                  padding: '12px', borderRadius: 'var(--radius-lg)', background: 'var(--color-bg-alt)',
                }}>
                  <div style={{
                    width: '34px', height: '34px', borderRadius: 'var(--radius-md)',
                    background: 'var(--color-info-bg)',
                    display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0,
                  }}>
                    <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="var(--color-info)" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                      <rect x="3" y="4" width="18" height="18" rx="2"/><line x1="16" y1="2" x2="16" y2="6"/><line x1="8" y1="2" x2="8" y2="6"/><line x1="3" y1="10" x2="21" y2="10"/>
                    </svg>
                  </div>
                  <div style={{ minWidth: 0 }}>
                    <p style={{ fontSize: '13px', fontWeight: '600' }}>{event.title}</p>
                    <p style={{ fontSize: '12px', color: 'var(--color-text-muted)', marginTop: '2px' }}>
                      {event.date} · {event.start_time || '-'}
                    </p>
                  </div>
                </div>
              ))}
            </div>
          ) : (
            <div className="tc-empty-state" style={{ padding: '24px 16px' }}>
              <p className="tc-empty-state-desc">Tidak ada jadwal mendatang.</p>
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
