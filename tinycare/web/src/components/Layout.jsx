import { useState, useEffect } from 'react';
import { Link, useLocation, useNavigate } from 'react-router-dom';
import { useTranslation } from 'react-i18next';
import { useAuth } from '../context/AuthContext';
import { useTheme } from '../context/ThemeContext';
import LanguageSwitcher from './LanguageSwitcher';

function getMenuSections(t) {
  return [
    {
      label: 'Overview',
      items: [
        { name: 'Dashboard', path: '/dashboard', icon: 'dashboard' },
      ],
    },
    {
      label: t('Anak'),
      items: [
        { name: t('Anak'), path: '/children', icon: 'child' },
        { name: t('Orang Tua'), path: '/parents', icon: 'parent' },
        { name: 'Daily Story', path: '/daily-stories', icon: 'story' },
        { name: t('Aktivitas'), path: '/activities', icon: 'activity' },
        { name: t('Perkembangan'), path: '/development', icon: 'development' },
        { name: t('Informasi Anak'), path: '/child-information', icon: 'info' },
      ],
    },
    {
      label: t('Keuangan'),
      items: [
        { name: t('Paket'), path: '/packages', icon: 'package' },
        { name: t('Voucher'), path: '/vouchers', icon: 'voucher' },
        { name: 'Invoice', path: '/invoices', icon: 'invoice' },
        { name: t('Pembayaran'), path: '/payments', icon: 'payment' },
      ],
    },
    {
      label: t('Komunikasi'),
      items: [
        { name: t('Pengumuman'), path: '/announcements', icon: 'announcement' },
        { name: 'Feedback', path: '/feedback', icon: 'feedback' },
      ],
    },
    {
      label: t('Manajemen'),
      items: [
        { name: t('Pengguna'), path: '/users', icon: 'users' },
      ],
    },
  ];
}

function getAdminMasterExtraItems(t) {
  return [
    { name: t('Kelola Admin'), path: '/admin-management', icon: 'admin' },
    { name: t('Bahasa & Terjemahan'), path: '/translations', icon: 'language' },
  ];
}

function SidebarIcon({ name, size = 18 }) {
  const icons = {
    dashboard: <svg width={size} height={size} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round"><rect x="3" y="3" width="7" height="7" rx="1.5"/><rect x="14" y="3" width="7" height="7" rx="1.5"/><rect x="3" y="14" width="7" height="7" rx="1.5"/><rect x="14" y="14" width="7" height="7" rx="1.5"/></svg>,
    child: <svg width={size} height={size} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round"><circle cx="12" cy="8" r="4"/><path d="M5 20c0-4 3.5-7 7-7s7 3 7 7"/></svg>,
    parent: <svg width={size} height={size} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round"><circle cx="9" cy="7" r="4"/><path d="M3 21v-2a4 4 0 014-4h4a4 4 0 014 4v2"/><path d="M16 3.13a4 4 0 010 7.75M21 21v-2a4 4 0 00-3-3.87"/></svg>,
    attendance: <svg width={size} height={size} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round"><path d="M9 11l3 3L22 4"/><path d="M21 12v7a2 2 0 01-2 2H5a2 2 0 01-2-2V5a2 2 0 012-2h11"/></svg>,
    story: <svg width={size} height={size} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round"><path d="M4 19.5A2.5 2.5 0 016.5 17H20"/><path d="M6.5 2H20v20H6.5A2.5 2.5 0 014 19.5v-15A2.5 2.5 0 016.5 2z"/></svg>,
    activity: <svg width={size} height={size} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round"><circle cx="12" cy="12" r="10"/><path d="M8 14s1.5 2 4 2 4-2 4-2"/><line x1="9" y1="9" x2="9.01" y2="9"/><line x1="15" y1="9" x2="15.01" y2="9"/></svg>,
    development: <svg width={size} height={size} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round"><polyline points="22 12 18 12 15 21 9 3 6 12 2 12"/></svg>,
    package: <svg width={size} height={size} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round"><path d="M21 16V8a2 2 0 00-1-1.73l-7-4a2 2 0 00-2 0l-7 4A2 2 0 003 8v8a2 2 0 001 1.73l7 4a2 2 0 002 0l7-4A2 2 0 0021 16z"/><polyline points="3.27 6.96 12 12.01 20.73 6.96"/><line x1="12" y1="22.08" x2="12" y2="12"/></svg>,
    voucher: <svg width={size} height={size} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round"><path d="M20 12v6a2 2 0 01-2 2H6a2 2 0 01-2-2v-6"/><polyline points="22 7 13 12 22 17 22 7"/><line x1="2" y1="7" x2="13" y2="12"/></svg>,
    invoice: <svg width={size} height={size} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round"><path d="M14 2H6a2 2 0 00-2 2v16a2 2 0 002 2h12a2 2 0 002-2V8z"/><polyline points="14 2 14 8 20 8"/><line x1="16" y1="13" x2="8" y2="13"/><line x1="16" y1="17" x2="8" y2="17"/></svg>,
    payment: <svg width={size} height={size} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round"><rect x="1" y="4" width="22" height="16" rx="2" ry="2"/><line x1="1" y1="10" x2="23" y2="10"/></svg>,
    announcement: <svg width={size} height={size} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round"><path d="M18 8A6 6 0 006 8c0 7-3 9-3 9h18s-3-2-3-9"/><path d="M13.73 21a2 2 0 01-3.46 0"/></svg>,
    event: <svg width={size} height={size} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round"><rect x="3" y="4" width="18" height="18" rx="2" ry="2"/><line x1="16" y1="2" x2="16" y2="6"/><line x1="8" y1="2" x2="8" y2="6"/><line x1="3" y1="10" x2="21" y2="10"/></svg>,
    feedback: <svg width={size} height={size} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round"><path d="M21 15a2 2 0 01-2 2H7l-4 4V5a2 2 0 012-2h14a2 2 0 012 2z"/></svg>,
    report: <svg width={size} height={size} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round"><line x1="18" y1="20" x2="18" y2="10"/><line x1="12" y1="20" x2="12" y2="4"/><line x1="6" y1="20" x2="6" y2="14"/></svg>,
    users: <svg width={size} height={size} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round"><path d="M17 21v-2a4 4 0 00-4-4H5a4 4 0 00-4 4v2"/><circle cx="9" cy="7" r="4"/><path d="M23 21v-2a4 4 0 00-3-3.87"/><path d="M16 3.13a4 4 0 010 7.75"/></svg>,
    admin: <svg width={size} height={size} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round"><path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"/></svg>,
    language: <svg width={size} height={size} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round"><circle cx="12" cy="12" r="10"/><path d="M2 12h20"/><path d="M12 2a15.3 15.3 0 0 1 4 10 15.3 15.3 0 0 1-4 10 15.3 15.3 0 0 1-4-10 15.3 15.3 0 0 1 4-10z"/></svg>,
    info: <svg width={size} height={size} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round"><circle cx="12" cy="12" r="10"/><line x1="12" y1="16" x2="12" y2="12"/><line x1="12" y1="8" x2="12.01" y2="8"/></svg>,
    profile: <svg width={size} height={size} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round"><path d="M20 21v-2a4 4 0 00-4-4H8a4 4 0 00-4 4v2"/><circle cx="12" cy="7" r="4"/></svg>,
  };
  return icons[name] || null;
}

function SidebarContent({ sidebarOpen, onNav }) {
  const { user, logout } = useAuth();
  const { t } = useTranslation();
  const location = useLocation();
  const menuSections = getMenuSections(t);
  const adminMasterExtraItems = getAdminMasterExtraItems(t);

  return (
    <>
      {/* Logo */}
      <div style={{
        padding: sidebarOpen ? '20px 20px 16px' : '20px 0',
        display: 'flex', alignItems: 'center', gap: '12px',
        justifyContent: sidebarOpen ? 'flex-start' : 'center',
        borderBottom: '1px solid var(--sidebar-border)',
        minHeight: '65px',
      }}>
        <div style={{
          width: '36px', height: '36px', borderRadius: '10px',
          background: 'var(--color-primary)',
          display: 'flex', alignItems: 'center', justifyContent: 'center',
          flexShrink: 0,
        }}>
          <svg width="18" height="18" viewBox="0 0 32 32" fill="none">
            <path d="M16 28s-11-7.2-11-15.2C5 9.2 7.2 7 10 7c1.8 0 3.4 1 4 2.5C14.6 8 16.2 7 18 7c2.8 0 5 2.2 5 5.8C23 20.8 16 28 16 28z" fill="white"/>
          </svg>
        </div>
{sidebarOpen && (
            <div>
              <h1 style={{ fontSize: '16px', fontWeight: '700', color: 'var(--color-text)', lineHeight: 1.2 }}>TinyCare</h1>
              <p style={{ fontSize: '11px', color: 'var(--color-text-muted)', lineHeight: 1.2 }}>{t('Admin Dashboard')}</p>
            </div>
          )}
      </div>

      {/* Navigation */}
      <nav style={{ flex: 1, overflowY: 'auto', padding: '8px' }}>
        {[...menuSections, ...(user?.role === 'admin_master' ? [{ label: 'Admin', items: adminMasterExtraItems }] : [])].map((section) => (
          <div key={section.label} style={{ marginBottom: '4px' }}>
            {sidebarOpen && (
              <div className="tc-section-title">{section.label}</div>
            )}
            {section.items.map((item) => {
              const isActive = location.pathname === item.path;
              return (
                <Link
                  key={item.path}
                  to={item.path}
                  onClick={onNav}
                  className={`tc-nav-link ${isActive ? 'tc-nav-link-active' : ''}`}
                  style={{ padding: sidebarOpen ? '8px 12px' : '8px 0', justifyContent: sidebarOpen ? 'flex-start' : 'center' }}
                >
                  {isActive && (
                    <div style={{
                      position: 'absolute', left: 0, top: '50%', transform: 'translateY(-50%)',
                      width: '3px', height: '18px', background: 'var(--color-primary)',
                      borderRadius: '0 3px 3px 0',
                    }} />
                  )}
                  <span style={{ display: 'flex', alignItems: 'center', justifyContent: 'center', width: '20px', flexShrink: 0 }}>
                    <SidebarIcon name={item.icon} size={17} />
                  </span>
                  {sidebarOpen && <span>{item.name}</span>}
                </Link>
              );
            })}
          </div>
        ))}
      </nav>

      {/* User Info */}
      <div style={{
        padding: sidebarOpen ? '12px 16px' : '12px 0',
        borderTop: '1px solid var(--sidebar-border)',
        display: 'flex', flexDirection: 'column', gap: '8px',
        alignItems: sidebarOpen ? 'stretch' : 'center',
      }}>
        <div style={{
          display: 'flex', alignItems: 'center', gap: '10px',
          justifyContent: sidebarOpen ? 'flex-start' : 'center',
        }}>
          <div style={{
            width: '32px', height: '32px', borderRadius: 'var(--radius-full)',
            background: 'var(--color-primary-lighter)',
            display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0,
          }}>
            <span style={{ color: 'var(--color-primary)', fontWeight: '700', fontSize: '12px' }}>
              {user?.name?.charAt(0) || 'A'}
            </span>
          </div>
          {sidebarOpen && (
            <div style={{ minWidth: 0, flex: 1 }}>
              <p className="tc-truncate" style={{ fontSize: '13px', fontWeight: '600', color: 'var(--color-text)' }}>{user?.name}</p>
              <p style={{ fontSize: '11px', color: 'var(--color-text-muted)', textTransform: 'capitalize' }}>{user?.role}</p>
            </div>
          )}
        </div>
        <button
          onClick={() => { logout(); }}
          className="tc-btn-ghost tc-btn"
          style={{ padding: '7px 10px', fontSize: '12px', width: '100%', justifyContent: sidebarOpen ? 'flex-start' : 'center', color: 'var(--color-text-muted)' }}
        >
          <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
            <path d="M9 21H5a2 2 0 01-2-2V5a2 2 0 012-2h4"/><polyline points="16 17 21 12 16 7"/><line x1="21" y1="12" x2="9" y2="12"/>
          </svg>
          {sidebarOpen && t('Keluar')}
        </button>
      </div>
    </>
  );
}

export default function Layout({ children }) {
  const [sidebarOpen, setSidebarOpen] = useState(true);
  const [mobileOpen, setMobileOpen] = useState(false);
  const [profileOpen, setProfileOpen] = useState(false);
  const { theme, setTheme } = useTheme();
  const { user, logout } = useAuth();
  const { t } = useTranslation();
  const location = useLocation();
  const navigate = useNavigate();

  // Close mobile sidebar on navigation
  useEffect(() => { setMobileOpen(false); }, [location.pathname]);

  // Close sidebar on small screens
  useEffect(() => {
    const mql = window.matchMedia('(max-width: 768px)');
    const handler = (e) => { if (e.matches) { setSidebarOpen(false); } };
    mql.addEventListener('change', handler);
    if (mql.matches) setSidebarOpen(false);
    return () => mql.removeEventListener('change', handler);
  }, []);

  return (
    <div style={{ display: 'flex', height: '100vh', background: 'var(--color-bg)', overflow: 'hidden' }}>
      {/* Desktop Sidebar */}
      <aside
        className="tc-sidebar-desktop"
        style={{
          width: sidebarOpen ? '250px' : '68px',
          background: 'var(--sidebar-bg)',
          borderRight: '1px solid var(--sidebar-border)',
          transition: 'width 0.2s ease',
          display: 'flex', flexDirection: 'column', overflow: 'hidden', flexShrink: 0,
        }}
      >
        <SidebarContent sidebarOpen={sidebarOpen} />
      </aside>

      {/* Mobile Sidebar Overlay */}
      {mobileOpen && (
        <div className="tc-sidebar-backdrop" onClick={() => setMobileOpen(false)} />
      )}

      {/* Mobile Sidebar Drawer */}
      <aside
        className="tc-sidebar-mobile"
        style={{
          position: 'fixed', top: 0, left: 0, bottom: 0, zIndex: 50,
          width: '260px',
          background: 'var(--sidebar-bg)',
          borderRight: '1px solid var(--sidebar-border)',
          display: 'flex', flexDirection: 'column', overflow: 'hidden',
          transform: mobileOpen ? 'translateX(0)' : 'translateX(-100%)',
          transition: 'transform 0.25s ease',
        }}
      >
        <SidebarContent sidebarOpen={true} onNav={() => setMobileOpen(false)} />
      </aside>

      {/* Main Content */}
      <div style={{ flex: 1, display: 'flex', flexDirection: 'column', overflow: 'hidden', minWidth: 0 }}>
        {/* Header */}
        <header style={{
          background: 'var(--header-bg)',
          borderBottom: '1px solid var(--header-border)',
          padding: '0 24px', height: '56px',
          display: 'flex', alignItems: 'center', justifyContent: 'space-between', flexShrink: 0,
          backdropFilter: 'blur(8px)',
        }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: '12px' }}>
            <button
              onClick={() => {
                if (window.innerWidth <= 768) setMobileOpen(!mobileOpen);
                else setSidebarOpen(!sidebarOpen);
              }}
              style={{
                padding: '6px', border: 'none', borderRadius: 'var(--radius-sm)',
                background: 'transparent', color: 'var(--color-text-secondary)',
                cursor: 'pointer', display: 'flex', alignItems: 'center', justifyContent: 'center',
              }}
            >
              <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                <line x1="3" y1="12" x2="21" y2="12"/><line x1="3" y1="6" x2="21" y2="6"/><line x1="3" y1="18" x2="21" y2="18"/>
              </svg>
            </button>
          </div>

          <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
            <LanguageSwitcher />

            <button
              onClick={() => setTheme(theme === 'dark' ? 'light' : 'dark')}
              style={{
                padding: '6px', border: '1px solid var(--color-border)',
                borderRadius: 'var(--radius-sm)', background: 'var(--color-surface)',
                color: 'var(--color-text-secondary)', cursor: 'pointer',
                display: 'flex', alignItems: 'center', justifyContent: 'center',
                width: '34px', height: '34px',
              }}
              title={theme === 'dark' ? t('Mode Terang') : t('Mode Gelap')}
            >
              {theme === 'dark' ? (
                <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                  <circle cx="12" cy="12" r="5"/><line x1="12" y1="1" x2="12" y2="3"/><line x1="12" y1="21" x2="12" y2="23"/><line x1="4.22" y1="4.22" x2="5.64" y2="5.64"/><line x1="18.36" y1="18.36" x2="19.78" y2="19.78"/><line x1="1" y1="12" x2="3" y2="12"/><line x1="21" y1="12" x2="23" y2="12"/><line x1="4.22" y1="19.78" x2="5.64" y2="18.36"/><line x1="18.36" y1="5.64" x2="19.78" y2="4.22"/>
                </svg>
              ) : (
                <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                  <path d="M21 12.79A9 9 0 1111.21 3 7 7 0 0021 12.79z"/>
                </svg>
              )}
            </button>

            <span
              title={t('Versi aplikasi')}
              style={{
                fontSize: '11px', fontWeight: '700', padding: '4px 8px',
                borderRadius: 'var(--radius-sm)', background: 'var(--color-primary-lighter)',
                color: 'var(--color-primary)', whiteSpace: 'nowrap', userSelect: 'none',
              }}
            >
              v1.3.1
            </span>

            {/* Profile dropdown */}
            <div style={{ position: 'relative' }}>
              <button
                onClick={() => setProfileOpen(!profileOpen)}
                style={{
                  display: 'flex', alignItems: 'center', gap: '8px',
                  padding: '4px 8px', borderRadius: 'var(--radius-sm)',
                  border: '1px solid var(--color-border)', background: 'var(--color-surface)',
                  cursor: 'pointer', color: 'var(--color-text)',
                }}
              >
                <div style={{
                  width: '28px', height: '28px', borderRadius: 'var(--radius-full)',
                  background: 'var(--color-primary-lighter)',
                  display: 'flex', alignItems: 'center', justifyContent: 'center',
                }}>
                  <span style={{ color: 'var(--color-primary)', fontWeight: '700', fontSize: '11px' }}>
                    {user?.name?.charAt(0) || 'A'}
                  </span>
                </div>
                <span style={{ fontSize: '13px', fontWeight: '500', maxWidth: '120px', overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>{user?.name}</span>
              </button>
              {profileOpen && (
                <>
                  <div style={{ position: 'fixed', inset: 0, zIndex: 99 }} onClick={() => setProfileOpen(false)} />
                  <div style={{
                    position: 'absolute', right: 0, top: '100%', marginTop: '4px',
                    background: 'var(--color-surface)', border: '1px solid var(--color-border)',
                    borderRadius: 'var(--radius-lg)', padding: '6px', minWidth: '180px',
                    zIndex: 100, boxShadow: 'var(--shadow-md)',
                  }}>
                    <div style={{ padding: '8px 12px', borderBottom: '1px solid var(--color-border-light)', marginBottom: '4px' }}>
                      <p style={{ fontSize: '13px', fontWeight: '600' }}>{user?.name}</p>
                      <p style={{ fontSize: '11px', color: 'var(--color-text-muted)' }}>{user?.email}</p>
                    </div>
                    <button
                      onClick={() => { setProfileOpen(false); navigate('/profile'); }}
                      style={{
                        display: 'flex', alignItems: 'center', gap: '8px', width: '100%',
                        padding: '8px 12px', border: 'none', borderRadius: 'var(--radius-md)',
                        background: 'transparent', cursor: 'pointer', fontSize: '13px',
                        color: 'var(--color-text)', textAlign: 'left',
                      }}
                      onMouseEnter={(e) => e.target.style.background = 'var(--color-bg-alt)'}
                      onMouseLeave={(e) => e.target.style.background = 'transparent'}
                    >
                      <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M20 21v-2a4 4 0 00-4-4H8a4 4 0 00-4 4v2"/><circle cx="12" cy="7" r="4"/></svg>
                      {t('Profil')}
                    </button>
                    <button
                      onClick={() => { setProfileOpen(false); logout(); }}
                      style={{
                        display: 'flex', alignItems: 'center', gap: '8px', width: '100%',
                        padding: '8px 12px', border: 'none', borderRadius: 'var(--radius-md)',
                        background: 'transparent', cursor: 'pointer', fontSize: '13px',
                        color: 'var(--color-error)', textAlign: 'left',
                      }}
                      onMouseEnter={(e) => e.target.style.background = 'var(--color-bg-alt)'}
                      onMouseLeave={(e) => e.target.style.background = 'transparent'}
                    >
                      <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M9 21H5a2 2 0 01-2-2V5a2 2 0 012-2h4"/><polyline points="16 17 21 12 16 7"/><line x1="21" y1="12" x2="9" y2="12"/></svg>
                      {t('Keluar')}
                    </button>
                  </div>
                </>
              )}
            </div>
          </div>
        </header>

        {/* Page Content */}
        <main className="tc-main-content" style={{ flex: 1, overflowY: 'auto' }}>
          <div className="tc-page-enter" style={{ maxWidth: '1400px', margin: '0 auto' }}>
            {children}
          </div>
        </main>
      </div>

      {/* Responsive CSS */}
      <style>{`
        .tc-sidebar-desktop { display: flex; }
        .tc-sidebar-mobile { display: none; }
        @media (max-width: 768px) {
          .tc-sidebar-desktop { display: none !important; }
          .tc-sidebar-mobile { display: flex; }
        }
      `}</style>
    </div>
  );
}
