import { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { parentAPI } from '../../services/api';
import { useAuth } from '../../context/AuthContext';
import ChildPhoto from '../../components/ChildPhoto';
import { useTranslation } from 'react-i18next';

export default function ParentDashboard() {
  const { t } = useTranslation();
  const [data, setData] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const { user } = useAuth();
  const navigate = useNavigate();

  useEffect(() => {
    parentAPI.dashboard()
      .then((res) => setData(res.data.data))
      .catch((err) => {
        setError(err.response?.data?.message || t('Gagal memuat dashboard.'));
      })
      .finally(() => setLoading(false));
  }, []);

  if (loading) {
    return (
      <div className="tc-loading-screen">
        <div className="tc-spinner tc-spinner-lg"></div>
        <p>{t('Memuat dashboard...')}</p>
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
        <button onClick={() => window.location.reload()} className="tc-btn tc-btn-secondary tc-btn-sm" style={{ marginTop: '12px' }}>{t('Coba Lagi')}</button>
      </div>
    );
  }

  if (!data) {
    return (
      <div className="tc-empty-state">
        <p className="tc-empty-state-desc">{t('Data tidak tersedia.')}</p>
      </div>
    );
  }

  const children = data.children || [];
  const pendingInvoices = data.pending_invoices || [];
  const announcements = data.announcements || [];
  const upcomingEvents = data.upcoming_events || [];
  const childInformation = data.child_information || [];

  const formatCurrency = (v) => new Intl.NumberFormat('id-ID', { style: 'currency', currency: 'IDR', maximumFractionDigits: 0 }).format(v);

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
          {t('Halo, {{name}}', { name: user?.name?.split(' ')[0] })}
        </h1>
        <p style={{ fontSize: '14px', color: 'var(--color-text-secondary)', lineHeight: 1.5 }}>
          {t('Pantau perkembangan si kecil dengan mudah.')}
        </p>
      </div>

      {/* Summary Cards */}
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(180px, 1fr))', gap: '14px', marginBottom: '28px' }}>
        <div className="tc-card tc-card-hover" style={{ padding: '18px' }}>
          <p style={{ fontSize: '11px', fontWeight: '600', color: 'var(--color-text-muted)', textTransform: 'uppercase', letterSpacing: '0.05em', marginBottom: '8px' }}>{t('Anak')}</p>
          <p style={{ fontSize: '28px', fontWeight: '700', lineHeight: 1 }}>{children.length}</p>
        </div>
        <div className="tc-card tc-card-hover" style={{ padding: '18px' }}>
          <p style={{ fontSize: '11px', fontWeight: '600', color: 'var(--color-text-muted)', textTransform: 'uppercase', letterSpacing: '0.05em', marginBottom: '8px' }}>{t('Tagihan Pending')}</p>
          <p style={{ fontSize: '28px', fontWeight: '700', lineHeight: 1, color: pendingInvoices.length > 0 ? 'var(--color-warning)' : 'inherit' }}>{pendingInvoices.length}</p>
        </div>
        <div className="tc-card tc-card-hover" style={{ padding: '18px' }}>
          <p style={{ fontSize: '11px', fontWeight: '600', color: 'var(--color-text-muted)', textTransform: 'uppercase', letterSpacing: '0.05em', marginBottom: '8px' }}>{t('Pengumuman')}</p>
          <p style={{ fontSize: '28px', fontWeight: '700', lineHeight: 1 }}>{announcements.length}</p>
        </div>
        <div className="tc-card tc-card-hover" style={{ padding: '18px' }}>
          <p style={{ fontSize: '11px', fontWeight: '600', color: 'var(--color-text-muted)', textTransform: 'uppercase', letterSpacing: '0.05em', marginBottom: '8px' }}>{t('Jadwal')}</p>
          <p style={{ fontSize: '28px', fontWeight: '700', lineHeight: 1 }}>{upcomingEvents.length}</p>
        </div>
      </div>

      {/* Children Cards */}
      {children.length > 0 && (
        <div style={{ marginBottom: '28px' }}>
          <h2 style={{ fontSize: '15px', fontWeight: '700', marginBottom: '14px', letterSpacing: '-0.01em' }}>{t('Anak Saya')}</h2>
          <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(300px, 1fr))', gap: '14px' }}>
            {children.map((child) => (
              <div
                key={child.id}
                className="tc-card tc-card-interactive"
                style={{ padding: '20px', cursor: 'pointer' }}
                onClick={() => navigate(`/parent/children/${child.id}`)}
              >
                <div style={{ display: 'flex', alignItems: 'center', gap: '14px', marginBottom: '14px' }}>
                  <ChildPhoto child={child} width={48} alt={child.name} />
                  <div>
                    <h3 style={{ fontSize: '15px', fontWeight: '600' }}>{child.name}</h3>
                    <p style={{ fontSize: '12px', color: 'var(--color-text-muted)' }}>
                      {child.gender === 'male' ? t('Laki-laki') : t('Perempuan')}
                      {child.birth_date ? ` · ${new Date(child.birth_date).toLocaleDateString('id-ID', { year: 'numeric', month: 'short' })}` : ''}
                    </p>
                  </div>
                </div>

                {child.active_package && (
                  <div style={{
                    padding: '10px', borderRadius: 'var(--radius-md)',
                    background: 'var(--color-success-bg)', marginBottom: '8px',
                  }}>
                    <p style={{ fontSize: '12px', fontWeight: '600', color: 'var(--color-success)' }}>{child.active_package.name}</p>
                    <p style={{ fontSize: '11px', color: 'var(--color-text-muted)' }}>{t('Berlaku s/d {{date}}', { date: new Date(child.active_package.end_date).toLocaleDateString('id-ID') })}</p>
                  </div>
                )}

                {child.today_attendance && (
                  <div style={{ display: 'flex', alignItems: 'center', gap: '8px', marginBottom: '8px' }}>
                    <span className="tc-badge tc-badge-success">{t('Hadir')}</span>
                    {child.today_attendance.check_in_time && (
                      <span style={{ fontSize: '12px', color: 'var(--color-text-muted)' }}>{t('Masuk: {{time}}', { time: child.today_attendance.check_in_time })}</span>
                    )}
                  </div>
                )}

                {child.today_story && (
                  <div style={{
                    padding: '10px', borderRadius: 'var(--radius-md)',
                    background: 'var(--color-bg-alt)',
                  }}>
                    <p style={{ fontSize: '12px', color: 'var(--color-text-secondary)' }}>
                      {child.today_story.summary || `Mood: ${child.today_story.mood}`}
                    </p>
                  </div>
                )}

                <div style={{
                  marginTop: '12px', display: 'flex', alignItems: 'center', gap: '4px',
                  fontSize: '12px', fontWeight: '500', color: 'var(--color-primary)',
                }}>
                  {t('Lihat Detail')}
                  <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                    <polyline points="9 18 15 12 9 6"/>
                  </svg>
                </div>
              </div>
            ))}
          </div>
        </div>
      )}

      {children.length === 0 && (
        <div className="tc-card" style={{ marginBottom: '28px' }}>
          <div className="tc-empty-state">
            <div className="tc-empty-state-icon">
              <svg width="28" height="28" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8"><circle cx="12" cy="8" r="4"/><path d="M5 20c0-4 3.5-7 7-7s7 3 7 7"/></svg>
            </div>
            <p className="tc-empty-state-title">{t('Belum ada data anak')}</p>
            <p className="tc-empty-state-desc">{t('Data akan muncul ketika anak sudah terdaftar di daycare.')}</p>
          </div>
        </div>
      )}

      {/* Child Information Section */}
      {childInformation.length > 0 && (
        <div style={{ marginBottom: '28px' }}>
          <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: '14px' }}>
            <h2 style={{ fontSize: '15px', fontWeight: '700', letterSpacing: '-0.01em' }}>{t('Informasi Anak')}</h2>
            <button
              onClick={() => navigate('/parent/information')}
              className="tc-btn tc-btn-ghost tc-btn-sm"
              style={{ fontSize: '12px' }}
            >
              {t('Lihat Semua')}
            </button>
          </div>
          <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(300px, 1fr))', gap: '14px' }}>
            {childInformation.slice(0, 3).map((info) => (
              <div
                key={info.id}
                className="tc-card tc-card-interactive"
                style={{ padding: '16px', cursor: 'pointer' }}
                onClick={() => navigate('/parent/information')}
              >
                <div style={{ display: 'flex', alignItems: 'center', gap: '10px', marginBottom: '10px' }}>
                  <div style={{
                    width: '32px', height: '32px', borderRadius: 'var(--radius-md)',
                    background: 'var(--color-info-bg)',
                    display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0,
                  }}>
                    <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="var(--color-info)" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                      <circle cx="12" cy="12" r="10"/><line x1="12" y1="16" x2="12" y2="12"/><line x1="12" y1="8" x2="12.01" y2="8"/>
                    </svg>
                  </div>
                  <div>
                    <p style={{ fontSize: '13px', fontWeight: '600' }}>{info.child?.name}</p>
                    <p style={{ fontSize: '11px', color: 'var(--color-text-muted)' }}>{info.type}</p>
                  </div>
                </div>
                <p style={{ fontSize: '13px', color: 'var(--color-text-secondary)' }} className="tc-truncate">{info.title || info.content}</p>
              </div>
            ))}
          </div>
        </div>
      )}

      {/* Two Column: Invoices + Events */}
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(340px, 1fr))', gap: '20px' }}>
        {/* Pending Invoices */}
        {pendingInvoices.length > 0 && (
          <div className="tc-card" style={{ padding: '20px' }}>
            <h2 style={{ fontSize: '14px', fontWeight: '700', marginBottom: '14px', letterSpacing: '-0.01em' }}>{t('Invoice Pending')}</h2>
            <div style={{ display: 'flex', flexDirection: 'column', gap: '8px' }}>
              {pendingInvoices.map((inv) => (
                <div key={inv.id} style={{
                  display: 'flex', alignItems: 'center', justifyContent: 'space-between',
                  padding: '12px', borderRadius: 'var(--radius-md)', background: 'var(--color-warning-bg)',
                  cursor: 'pointer', transition: 'opacity 0.2s',
                }}
                onClick={() => navigate(`/parent/invoices/${inv.id}`)}
                onMouseEnter={(e) => e.currentTarget.style.opacity = '0.8'}
                onMouseLeave={(e) => e.currentTarget.style.opacity = '1'}
                >
                  <div>
                    <p style={{ fontSize: '13px', fontWeight: '600' }}>{inv.invoice_number}</p>
                    <p style={{ fontSize: '12px', color: 'var(--color-text-muted)' }}>
                      {inv.child?.name} · {t('Jatuh tempo: {{date}}', { date: new Date(inv.due_date).toLocaleDateString('id-ID') })}
                    </p>
                  </div>
                  <span style={{ fontSize: '14px', fontWeight: '700', color: 'var(--color-warning)' }}>
                    {formatCurrency(inv.total)}
                  </span>
                </div>
              ))}
            </div>
          </div>
        )}

        {/* Upcoming Events */}
        {upcomingEvents.length > 0 && (
          <div className="tc-card" style={{ padding: '20px' }}>
            <h2 style={{ fontSize: '14px', fontWeight: '700', marginBottom: '14px', letterSpacing: '-0.01em' }}>{t('Jadwal Mendatang')}</h2>
            <div style={{ display: 'flex', flexDirection: 'column', gap: '8px' }}>
              {upcomingEvents.map((event) => (
                <div key={event.id} style={{
                  display: 'flex', alignItems: 'flex-start', gap: '12px',
                  padding: '12px', borderRadius: 'var(--radius-md)', background: 'var(--color-info-bg)',
                  cursor: 'pointer', transition: 'opacity 0.2s',
                }}
                onClick={() => navigate('/parent/events')}
                onMouseEnter={(e) => e.currentTarget.style.opacity = '0.8'}
                onMouseLeave={(e) => e.currentTarget.style.opacity = '1'}
                >
                  <div style={{
                    width: '32px', height: '32px', borderRadius: 'var(--radius-md)',
                    background: 'var(--color-surface)', flexShrink: 0,
                    display: 'flex', alignItems: 'center', justifyContent: 'center',
                  }}>
                    <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="var(--color-info)" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                      <rect x="3" y="4" width="18" height="18" rx="2"/><line x1="16" y1="2" x2="16" y2="6"/><line x1="8" y1="2" x2="8" y2="6"/><line x1="3" y1="10" x2="21" y2="10"/>
                    </svg>
                  </div>
                  <div>
                    <p style={{ fontSize: '13px', fontWeight: '600' }}>{event.title}</p>
                    <p style={{ fontSize: '12px', color: 'var(--color-text-muted)' }}>{event.date} · {event.start_time || '-'}</p>
                  </div>
                </div>
              ))}
            </div>
          </div>
        )}

        {/* Recent Announcements */}
        {announcements.length > 0 && (
          <div className="tc-card" style={{ padding: '20px' }}>
            <h2 style={{ fontSize: '14px', fontWeight: '700', marginBottom: '14px', letterSpacing: '-0.01em' }}>{t('Pengumuman')}</h2>
            <div style={{ display: 'flex', flexDirection: 'column', gap: '8px' }}>
              {announcements.slice(0, 3).map((ann) => (
                <div key={ann.id} style={{
                  padding: '12px', borderRadius: 'var(--radius-md)', background: 'var(--color-bg-alt)',
                  cursor: 'pointer', transition: 'opacity 0.2s',
                }}
                onClick={() => navigate('/parent/announcements')}
                onMouseEnter={(e) => e.currentTarget.style.opacity = '0.8'}
                onMouseLeave={(e) => e.currentTarget.style.opacity = '1'}
                >
                  <p style={{ fontSize: '13px', fontWeight: '600', marginBottom: '4px' }}>{ann.title}</p>
                  <p style={{ fontSize: '12px', color: 'var(--color-text-secondary)', lineHeight: '1.5' }} className="tc-truncate">{ann.content}</p>
                </div>
              ))}
            </div>
          </div>
        )}
      </div>
    </div>
  );
}
