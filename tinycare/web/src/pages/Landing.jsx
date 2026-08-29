import { useEffect, useRef, useState } from 'react';
import { Link } from 'react-router-dom';
import { useAuth } from '../context/AuthContext';

function useInView(threshold = 0.12) {
  const ref = useRef(null);
  const [inView, setInView] = useState(false);
  useEffect(() => {
    const el = ref.current;
    if (!el) return;
    const obs = new IntersectionObserver(
      ([entry]) => {
        if (entry.isIntersecting) {
          setInView(true);
          obs.disconnect();
        }
      },
      { threshold },
    );
    obs.observe(el);
    return () => obs.disconnect();
  }, [threshold]);
  return { ref, inView };
}

function Reveal({ children, delay = 0, style }) {
  const { ref, inView } = useInView();
  return (
    <div
      ref={ref}
      style={{
        opacity: inView ? 1 : 0,
        transform: inView ? 'translateY(0)' : 'translateY(30px)',
        transition: `opacity .8s ease ${delay}s, transform .8s cubic-bezier(.22,1,.36,1) ${delay}s`,
        willChange: 'opacity, transform',
        ...style,
      }}
    >
      {children}
    </div>
  );
}

function Stat({ value, suffix, label }) {
  const ref = useRef(null);
  const [inView, setInView] = useState(false);
  useEffect(() => {
    const obs = new IntersectionObserver(
      ([e]) => {
        if (e.isIntersecting) { setInView(true); obs.disconnect(); }
      },
      { threshold: 0.4 },
    );
    if (ref.current) obs.observe(ref.current);
    return () => obs.disconnect();
  }, []);
  const [val, setVal] = useState(0);
  useEffect(() => {
    if (!inView) return;
    let raf;
    const t0 = performance.now();
    const dur = 1600;
    const tick = (now) => {
      const p = Math.min((now - t0) / dur, 1);
      const eased = 1 - Math.pow(1 - p, 3);
      setVal(Math.round(value * eased));
      if (p < 1) raf = requestAnimationFrame(tick);
    };
    raf = requestAnimationFrame(tick);
    return () => cancelAnimationFrame(raf);
  }, [inView, value]);
  return (
    <div ref={ref} style={{ textAlign: 'center' }}>
      <div className="lp-serif" style={{ fontSize: 'clamp(34px, 5vw, 52px)', fontWeight: 700, color: 'var(--color-primary-dark)', lineHeight: 1 }}>
        {inView ? val : value}{suffix}
      </div>
      <div style={{ margin: '10px auto 0', width: 34, height: 2, background: 'linear-gradient(90deg,#d6b26a,#a8853f)', borderRadius: 99 }} />
      <div style={{ marginTop: 10, fontSize: 13, color: 'var(--color-text-secondary)', letterSpacing: '0.02em' }}>{label}</div>
    </div>
  );
}

function Icon({ name, size = 24, color = 'currentColor' }) {
  const paths = {
    shield: (
      <path d="M12 2l8 4v6c0 5.25-3.4 9.74-8 10-4.6-.26-8-4.75-8-10V6l8-4zm0 2.25L5.5 7.8V12c0 4.35 2.7 8.05 6.5 8.7 3.8-.65 6.5-4.35 6.5-8.7V7.8L12 4.25zm-.7 11.4l-3.1-3.1 1.4-1.4 1.7 1.7 3.6-3.6 1.4 1.4-5 5z" />
    ),
    chart: (
      <path d="M4 20V10m6 10V4m6 16v-7m4 7H2" strokeWidth="2.2" />
    ),
    users: (
      <path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2M9 11a4 4 0 1 0 0-8 4 4 0 0 0 0 8zm14 10v-2a4 4 0 0 0-3-3.87M16 3.13a4 4 0 0 1 0 7.75" strokeWidth="2" />
    ),
    calendar: (
      <path d="M8 2v4m8-4v4M3 10h18M4 4h16a1 1 0 0 1 1 1v16a1 1 0 0 1-1 1H4a1 1 0 0 1-1-1V5a1 1 0 0 1 1-1z" strokeWidth="2" />
    ),
    spark: (
      <path d="M12 2l1.9 5.6L19.5 9.5l-5.6 1.9L12 17l-1.9-5.6L4.5 9.5l5.6-1.9L12 2zm7 13l.9 2.6 2.6.9-2.6.9-.9 2.6-.9-2.6-2.6-.9 2.6-.9.9-2.6z" />
    ),
    lock: (
      <path d="M12 2a5 5 0 0 0-5 5v3H6a2 2 0 0 0-2 2v8a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2v-8a2 2 0 0 0-2-2h-1V7a5 5 0 0 0-5-5zm-3 8V7a3 3 0 1 1 6 0v3H9zm3 4a2 2 0 0 1 1 3.73V20h-2v-2.27A2 2 0 0 1 12 14z" />
    ),
    file: (
      <path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8l-6-6zm0 2l6 6h-6V4zM8 13h8v2H8v-2zm0 4h8v2H8v-2zm0-8h2v2H8V9z" />
    ),
    bell: (
      <path d="M18 8a6 6 0 1 0-12 0c0 7-3 9-3 9h18s-3-2-3-9m-4.27 13a2 2 0 0 0 3.54 0" strokeWidth="2" />
    ),
    heart: (
      <path d="M12 21s-7.5-4.6-9.7-8.8C.6 9 2.2 5.5 5.6 5.1c2-.2 3.8 1 4.4 2.8.6-1.8 2.4-3 4.4-2.8 3.4.4 5 3.9 3.3 7.1C19.5 16.4 12 21 12 21z" />
    ),
  };
  return (
    <svg width={size} height={size} viewBox="0 0 24 24" fill="none" stroke={color} strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
      {paths[name]}
    </svg>
  );
}

function Ticker() {
  const items = [
    'Manajemen Absensi', 'Laporan Anak Harian', 'Tagihan Otomatis', 'Kegiatan Edukatif',
    'Galeri Dokumentasi', 'Pantauan Pertumbuhan', 'Notifikasi Real-time', 'Keamanan Terjamin',
  ];
  const row = [...items, ...items];
  return (
    <div style={{ overflow: 'hidden', borderTop: '1px solid rgba(201,164,92,0.25)', borderBottom: '1px solid rgba(201,164,92,0.25)', background: 'rgba(250,247,240,0.6)', padding: '14px 0', whiteSpace: 'nowrap' }}>
      <div style={{ display: 'inline-block', animation: 'lpTicker 32s linear infinite' }}>
        {row.map((t, i) => (
          <span key={i} style={{ display: 'inline-block', margin: '0 22px', fontSize: 13, fontWeight: 600, letterSpacing: '0.04em', color: 'var(--color-text-secondary)' }}>
            <span style={{ color: '#c9a45c', marginRight: 10 }}>&#9670;</span>{t}
          </span>
        ))}
      </div>
    </div>
  );
}

const features = [
  { icon: 'users', title: 'Kelola Murid & Orang Tua', desc: 'Data lengkap anak, orang tua, hingga penjemputan terotorisasi — semua dalam satu genggaman.' },
  { icon: 'chart', title: 'Dashboard Analitik', desc: 'Pendapatan, jumlah kehadiran, dan perkembangan bulanan tersaji visual dan rapi.' },
  { icon: 'bell', title: 'Notifikasi Real-time', desc: 'Info kegiatan, pengumuman, dan tagihan terkirim langsung ke orang tua.' },
  { icon: 'shield', title: 'Keamanan Berlapis', desc: 'Level akses admin, petugas, dan orang tua — data anak terlindungi ketat.' },
  { icon: 'calendar', title: 'Absensi & Jadwal', desc: 'Pencatatan kedatangan harian, jadwal kegiatan, dan event daycare terautomasi.' },
  { icon: 'spark', title: 'Laporan Perkembangan', desc: 'Cerita harian, asesmen tumbuh kembang, dan rekap bulanan yang mudah dibaca.' },
];

const testimonials = [
  { name: 'Bunda Amalia', role: 'Orang Tua', text: 'Sekarang saya bisa melihat aktivitas dan laporan perkembangan anak setiap hari meski sedang di kantor. Sangat menenangkan.' },
  { name: 'Bapak Rendy', role: 'Orang Tua', text: 'Tagihan dan pembayaran jadi jelas, tidak ada lagi miss komunikasi dengan daycare. Fiturnya lengkap sekali.' },
  { name: 'Ibu Sarah', role: 'Pengelola Daycare', text: 'Mengelola 40+ anak, orang tua, dan karyawan jadi jauh lebih ringan. Dashboard-nya rapi, cepat, dan kelas premium.' },
];

export default function Landing() {
  const { user } = useAuth();
  const [menuOpen, setMenuOpen] = useState(false);
  const [scrolled, setScrolled] = useState(false);

  useEffect(() => {
    const onScroll = () => setScrolled(window.scrollY > 24);
    window.addEventListener('scroll', onScroll, { passive: true });
    return () => window.removeEventListener('scroll', onScroll);
  }, []);

  const isAdmin = user?.role === 'admin' || user?.role === 'admin_master';
  const appLink = user ? (isAdmin ? '/dashboard' : '/parent') : '/login';
  const appLabel = user ? 'Buka Aplikasi' : 'Masuk Aplikasi';

  const nav = (label, href) => (
    <a key={href} href={href} style={{ fontSize: 14, fontWeight: 500, color: 'var(--color-text-secondary)', padding: '8px 4px', borderRadius: 8, textDecoration: 'none', transition: 'color .15s ease' }}
      onMouseEnter={(e) => { e.currentTarget.style.color = 'var(--color-primary-dark)'; }}
      onMouseLeave={(e) => { e.currentTarget.style.color = 'var(--color-text-secondary)'; }}>
      {label}
    </a>
  );

  return (
    <div style={{ background: 'linear-gradient(180deg,#faf7f0 0%,#f4efe4 100%)', color: 'var(--color-text)', fontFamily: "'Inter', system-ui, sans-serif", overflowX: 'hidden' }}>
      {/* ============ NAVBAR ============ */}
      <header style={{
        position: 'fixed', top: 0, left: 0, right: 0, zIndex: 40, padding: `${scrolled ? 10 : 18}px 0`,
        background: scrolled ? 'rgba(250,247,240,0.82)' : 'transparent',
        backdropFilter: scrolled ? 'blur(14px)' : 'none',
        borderBottom: scrolled ? '1px solid rgba(50,70,58,0.08)' : '1px solid transparent',
        transition: 'all .3s ease',
      }}>
        <div style={{ maxWidth: 1180, margin: '0 auto', padding: '0 24px', display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
          <a href="#top" style={{ display: 'flex', alignItems: 'center', gap: 12, textDecoration: 'none' }}>
            <span style={{
              width: 40, height: 40, borderRadius: 12, display: 'flex', alignItems: 'center', justifyContent: 'center',
              background: 'linear-gradient(135deg,#2c5a47,#3a7059)', color: '#fff', fontWeight: 800, fontSize: 18,
              boxShadow: '0 6px 16px rgba(44,90,71,.35)',
            }}>TC</span>
            <span className="lp-serif" style={{ fontSize: 22, fontWeight: 700, color: 'var(--color-primary-dark)' }}>TinyCare</span>
          </a>
          <div className="lp-nav-desktop" style={{ alignItems: 'center', gap: 28 }}>
            <a href="#fitur" style={{ fontSize: 14, fontWeight: 500, color: 'var(--color-text-secondary)', textDecoration: 'none' }}>Fitur</a>
            <a href="#cara" style={{ fontSize: 14, fontWeight: 500, color: 'var(--color-text-secondary)', textDecoration: 'none' }}>Cara Kerja</a>
            <a href="#testimoni" style={{ fontSize: 14, fontWeight: 500, color: 'var(--color-text-secondary)', textDecoration: 'none' }}>Testimoni</a>
            <Link to={appLink} style={{
              padding: '10px 22px', borderRadius: 999, background: 'linear-gradient(135deg,#2c5a47,#3a7059)',
              color: '#fff', fontSize: 13, fontWeight: 600, textDecoration: 'none',
              boxShadow: '0 8px 20px rgba(44,90,71,.3)', transition: 'transform .15s ease, box-shadow .15s ease',
            }}
              onMouseEnter={(e) => { e.currentTarget.style.transform = 'translateY(-1px)'; e.currentTarget.style.boxShadow = '0 12px 26px rgba(44,90,71,.38)'; }}
              onMouseLeave={(e) => { e.currentTarget.style.transform = 'translateY(0)'; e.currentTarget.style.boxShadow = '0 8px 20px rgba(44,90,71,.3)'; }}>
              {appLabel}
            </Link>
          </div>
          <button
            className="lp-menu-btn"
            aria-label="Menu"
            onClick={() => setMenuOpen(!menuOpen)}
            style={{ display: 'flex', flexDirection: 'column', gap: 5, background: 'none', border: 'none', cursor: 'pointer', padding: 6 }}
          >
            <span style={{ width: 26, height: 2, background: 'var(--color-primary-dark)', borderRadius: 9 }} />
            <span style={{ width: 18, height: 2, background: '#c9a45c', borderRadius: 9 }} />
            <span style={{ width: 26, height: 2, background: 'var(--color-primary-dark)', borderRadius: 9 }} />
          </button>
        </div>
        {menuOpen && (
          <div style={{ background: 'rgba(250,247,240,0.97)', backdropFilter: 'blur(10px)', padding: '18px 24px', display: 'flex', flexDirection: 'column', gap: 4, borderBottom: '1px solid rgba(50,70,58,0.08)' }}>
            {[['Fitur', '#fitur'], ['Cara Kerja', '#cara'], ['Testimoni', '#testimoni']].map(([label, href]) => nav(label, href))}
            <Link to={appLink} style={{ marginTop: 8, padding: '11px', borderRadius: 999, background: 'linear-gradient(135deg,#2c5a47,#3a7059)', color: '#fff', fontSize: 14, fontWeight: 600, textAlign: 'center', textDecoration: 'none' }}>{appLabel}</Link>
          </div>
        )}
      </header>

      {/* ============ HERO ============ */}
      <section id="top" style={{ position: 'relative', minHeight: '100vh', display: 'flex', alignItems: 'center', padding: '120px 24px 80px', overflow: 'hidden' }}>
        {/* animated blobs */}
        <div aria-hidden style={{ position: 'absolute', top: '6%', left: '-6%', width: 480, height: 480, borderRadius: '50%', background: 'radial-gradient(circle at 30% 30%, rgba(201,164,92,0.28), rgba(201,164,92,0) 65%)', filter: 'blur(8px)', animation: 'lpDrift 16s ease-in-out infinite' }} />
        <div aria-hidden style={{ position: 'absolute', top: '38%', right: '-8%', width: 560, height: 560, borderRadius: '50%', background: 'radial-gradient(circle at 60% 40%, rgba(72,132,105,0.32), rgba(72,132,105,0) 65%)', filter: 'blur(10px)', animation: 'lpDrift 20s ease-in-out infinite reverse' }} />
        <div aria-hidden style={{ position: 'absolute', bottom: '-10%', left: '30%', width: 420, height: 420, borderRadius: '50%', background: 'radial-gradient(circle, rgba(233,214,166,0.35), rgba(233,214,166,0) 60%)', animation: 'lpWrinkle 14s ease-in-out infinite' }} />

        <div style={{ position: 'relative', maxWidth: 1180, margin: '0 auto', width: '100%', textAlign: 'center' }}>
          <Reveal>
            <div style={{ display: 'inline-flex', alignItems: 'center', gap: 10, padding: '8px 18px', borderRadius: 999, border: '1px solid rgba(201,164,92,0.4)', background: 'rgba(255,255,255,0.55)', backdropFilter: 'blur(6px)', fontSize: 13, fontWeight: 600, color: '#8a6a2f', letterSpacing: '0.03em', marginBottom: 28 }}>
              <span style={{ width: 8, height: 8, borderRadius: '50%', background: '#c9a45c', boxShadow: '0 0 0 4px rgba(201,164,92,0.18)', animation: 'lpGlow 2.2s ease-in-out infinite' }} />
              Platform Manajemen Daycare Premium
            </div>
          </Reveal>

          <Reveal delay={0.1}>
            <h1 className="lp-serif" style={{ fontSize: 'clamp(40px, 7.5vw, 84px)', lineHeight: 1.08, fontWeight: 700, color: 'var(--color-primary-dark)', letterSpacing: '-0.02em', margin: '0 auto', maxWidth: 940 }}>
              Tempat Tumbuh Kembang
              <br />
              Anak Anda, <span className="lp-gold-text">Dikelola Cerdas</span>
            </h1>
          </Reveal>

          <Reveal delay={0.2}>
            <p style={{ maxWidth: 640, margin: '26px auto 0', fontSize: 'clamp(16px, 2vw, 19px)', lineHeight: 1.7, color: 'var(--color-text-secondary)' }}>
              TinyCare membantu daycare & orang tua terhubung: kehadiran real-time, laporan harian, tagihan,
              hingga dokumentasi tumbuh kembang — rapi, transparan, dan terpercaya.
            </p>
          </Reveal>

          <Reveal delay={0.3}>
            <div style={{ display: 'flex', gap: 16, justifyContent: 'center', marginTop: 40, flexWrap: 'wrap' }}>
              <Link to={appLink} style={{
                padding: '16px 34px', borderRadius: 999, background: 'linear-gradient(135deg,#2c5a47,#3a7059)',
                color: '#fff', fontSize: 15, fontWeight: 700, textDecoration: 'none',
                boxShadow: '0 14px 34px rgba(44,90,71,.35)', transition: 'transform .15s ease, box-shadow .15s ease',
              }}
                onMouseEnter={(e) => { e.currentTarget.style.transform = 'translateY(-2px)'; e.currentTarget.style.boxShadow = '0 20px 44px rgba(44,90,71,.42)'; }}
                onMouseLeave={(e) => { e.currentTarget.style.transform = 'translateY(0)'; e.currentTarget.style.boxShadow = '0 14px 34px rgba(44,90,71,.35)'; }}>
                {appLabel} →
              </Link>
              <a href="#fitur" style={{
                padding: '16px 34px', borderRadius: 999, border: '1.5px solid rgba(44,90,71,0.35)',
                background: 'rgba(255,255,255,0.5)', color: 'var(--color-primary-dark)', fontSize: 15, fontWeight: 600, textDecoration: 'none',
                transition: 'background .15s ease',
              }}
                onMouseEnter={(e) => { e.currentTarget.style.background = 'rgba(255,255,255,0.85)'; }}
                onMouseLeave={(e) => { e.currentTarget.style.background = 'rgba(255,255,255,0.5)'; }}>
                Kenali Fiturnya
              </a>
            </div>
          </Reveal>

          {/* Hero showcase card */}
          <Reveal delay={0.45} style={{ marginTop: 72 }}>
            <div style={{
              maxWidth: 980, margin: '0 auto', padding: 12, borderRadius: 32,
              background: 'linear-gradient(140deg, rgba(44,90,71,0.12), rgba(201,164,92,0.18))',
              boxShadow: '0 40px 90px rgba(44,60,50,0.22)', position: 'relative',
            }}>
              <div style={{ borderRadius: 24, background: 'rgba(255,255,255,0.92)', backdropFilter: 'blur(8px)', overflow: 'hidden', boxShadow: 'inset 0 1px 0 rgba(255,255,255,0.8)' }}>
                <div style={{ display: 'flex', alignItems: 'center', gap: 8, padding: '16px 22px', borderBottom: '1px solid rgba(50,70,58,0.08)' }}>
                  <span style={{ width: 11, height: 11, borderRadius: '50%', background: '#d97b7b' }} />
                  <span style={{ width: 11, height: 11, borderRadius: '50%', background: '#e0c07c' }} />
                  <span style={{ width: 11, height: 11, borderRadius: '50%', background: '#7bc79a' }} />
                  <span style={{ flex: 1 }} />
                  <span style={{ fontSize: 12, color: 'var(--color-text-muted)', letterSpacing: '0.04em' }}>dashboard.tinycare</span>
                </div>
                <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(180px, 1fr))', gap: 16, padding: '24px 22px' }}>
                  {[
                    { k: 'Anak Terdaftar', v: '48', c: 'linear-gradient(135deg,#2c5a47,#3a7059)' },
                    { k: 'Orang Tua Aktif', v: '46', c: 'linear-gradient(135deg,#8a6a2f,#c9a45c)' },
                    { k: 'Kehadiran Hari Ini', v: '45', c: 'linear-gradient(135deg,#3a6fa0,#5a9fc5)' },
                    { k: 'Pendapatan Bulan Ini', v: 'Rp 38,4Jt', c: 'linear-gradient(135deg,#5d7b6c,#8fb5a0)' },
                  ].map((s) => (
                    <div key={s.k} style={{ borderRadius: 18, padding: '20px 18px', background: s.c, color: '#fff', display: 'flex', flexDirection: 'column', gap: 6, position: 'relative', overflow: 'hidden' }}>
                      <div style={{ position: 'absolute', top: -18, right: -14, width: 70, height: 70, borderRadius: '50%', background: 'rgba(255,255,255,0.14)' }} />
                      <span style={{ fontSize: 12, opacity: 0.82, letterSpacing: '0.03em' }}>{s.k}</span>
                      <span style={{ fontSize: 24, fontWeight: 700 }}>{s.v}</span>
                    </div>
                  ))}
                </div>
              </div>
            </div>
          </Reveal>
        </div>
      </section>

      {/* ============ TICKER ============ */}
      <Reveal><Ticker /></Reveal>

      {/* ============ STATS ============ */}
      <section style={{ padding: '84px 24px', maxWidth: 1000, margin: '0 auto' }}>
        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(180px, 1fr))', gap: 40 }}>
          <Stat value={48} suffix="+" label="Anak Terlayani" />
          <Stat value={1200} suffix="+" label="Laporan Terkirim" />
          <Stat value={99} suffix="%" label="Kepuasan Orang Tua" />
          <Stat value={24} suffix="/7" label="Pantauan Keamanan" />
        </div>
      </section>

      {/* ============ FEATURES ============ */}
      <section id="fitur" style={{ padding: '0 24px 40px' }}>
        <div style={{ maxWidth: 1180, margin: '0 auto' }}>
          <Reveal style={{ textAlign: 'center', marginBottom: 56 }}>
            <span style={{ fontSize: 13, fontWeight: 700, letterSpacing: '0.12em', color: '#c9a45c', textTransform: 'uppercase' }}>Fitur Unggulan</span>
            <h2 className="lp-serif" style={{ fontSize: 'clamp(30px, 4.6vw, 46px)', fontWeight: 700, color: 'var(--color-primary-dark)', margin: '14px 0 16px' }}>
              Semua yang Anda Butuhkan
            </h2>
            <div className="lp-shimmer-line" style={{ height: 2, width: 120, margin: '0 auto', borderRadius: 99 }} />
            <p style={{ maxWidth: 560, margin: '18px auto 0', fontSize: 16, color: 'var(--color-text-secondary)', lineHeight: 1.7 }}>
              Satu platform terpadu untuk pengelola daycare dan orang tua — dari absensi hingga laporan tumbuh kembang.
            </p>
          </Reveal>
          <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(300px, 1fr))', gap: 24 }}>
            {features.map((f, i) => (
              <Reveal key={f.title} delay={i * 0.07}>
                <div style={{
                  height: '100%', padding: '34px 30px', borderRadius: 24,
                  background: 'rgba(255,255,255,0.75)', backdropFilter: 'blur(6px)',
                  border: '1px solid rgba(50,70,58,0.08)', boxShadow: '0 12px 34px rgba(44,60,50,0.08)',
                  transition: 'transform .25s ease, box-shadow .25s ease, border-color .25s ease',
                }}
                  onMouseEnter={(e) => { e.currentTarget.style.transform = 'translateY(-6px)'; e.currentTarget.style.boxShadow = '0 26px 60px rgba(44,60,50,0.14)'; e.currentTarget.style.borderColor = 'rgba(201,164,92,0.45)'; }}
                  onMouseLeave={(e) => { e.currentTarget.style.transform = 'translateY(0)'; e.currentTarget.style.boxShadow = '0 12px 34px rgba(44,60,50,0.08)'; e.currentTarget.style.borderColor = 'rgba(50,70,58,0.08)'; }}>
                  <span style={{
                    width: 54, height: 54, borderRadius: 16, display: 'flex', alignItems: 'center', justifyContent: 'center',
                    background: 'linear-gradient(135deg,#e8f4ed,#f5f0e4)', color: 'var(--color-primary)', marginBottom: 20,
                    boxShadow: '0 8px 20px rgba(44,90,71,0.12)',
                  }}>
                    <Icon name={f.icon} size={26} />
                  </span>
                  <h3 style={{ fontSize: 18, fontWeight: 700, color: 'var(--color-text)', marginBottom: 10 }}>{f.title}</h3>
                  <p style={{ fontSize: 14, lineHeight: 1.7, color: 'var(--color-text-secondary)', margin: 0 }}>{f.desc}</p>
                </div>
              </Reveal>
            ))}
          </div>
        </div>
      </section>

      {/* ============ HOW IT WORKS ============ */}
      <section id="cara" style={{ padding: '96px 24px', background: 'rgba(201,164,92,0.07)' }}>
        <div style={{ maxWidth: 1180, margin: '0 auto' }}>
          <Reveal style={{ textAlign: 'center', marginBottom: 56 }}>
            <span style={{ fontSize: 13, fontWeight: 700, letterSpacing: '0.12em', color: '#c9a45c', textTransform: 'uppercase' }}>Cara Kerja</span>
            <h2 className="lp-serif" style={{ fontSize: 'clamp(30px, 4.6vw, 46px)', fontWeight: 700, color: 'var(--color-primary-dark)', margin: '14px 0 0' }}>
              Satu Platform, Dua Dunia
            </h2>
          </Reveal>
          <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(300px, 1fr))', gap: 24 }}>
            <Reveal>
              <div style={{ background: 'rgba(255,255,255,0.8)', borderRadius: 26, padding: '40px 34px', border: '1px solid rgba(44,90,71,0.12)', height: '100%' }}>
                <span style={{ display: 'inline-flex', padding: '7px 16px', borderRadius: 999, background: 'linear-gradient(135deg,#2c5a47,#3a7059)', color: '#fff', fontSize: 12, fontWeight: 700, letterSpacing: '0.05em' }}>UNTUK PENGELOLA</span>
                <h3 style={{ fontSize: 22, fontWeight: 700, color: 'var(--color-text)', margin: '20px 0 14px' }}>Operasional menjadi ringan</h3>
                <p style={{ fontSize: 14, lineHeight: 1.75, color: 'var(--color-text-secondary)', margin: '0 0 22px' }}>
                  Kelola data anak, kehadiran, paket, voucher, tagihan, hingga pembayaran dalam satu panel yang rapi.
                </p>
                {['Kelola murid & orang tua secara terpusat', 'Pembuatan tagihan & verifikasi pembayaran otomatis', 'Laporan harian, mingguan, dan bulanan satu klik', 'Riwayat kehadiran & aktivitas tiap anak terlacak'].map((t) => (
                  <div key={t} style={{ display: 'flex', alignItems: 'center', gap: 12, padding: '9px 0', fontSize: 14, color: 'var(--color-text-secondary)' }}>
                    <span style={{ width: 20, height: 20, borderRadius: '50%', background: 'var(--color-primary-lighter)', color: 'var(--color-success)', display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: 12, fontWeight: 800 }}>✓</span>
                    {t}
                  </div>
                ))}
              </div>
            </Reveal>
            <Reveal delay={0.12}>
              <div style={{ background: 'linear-gradient(150deg,#24483a,#2c5a47 60%,#3a7059)', borderRadius: 26, padding: '40px 34px', color: '#fff', height: '100%', boxShadow: '0 30px 70px rgba(36,72,58,.35)' }}>
                <span style={{ display: 'inline-flex', padding: '7px 16px', borderRadius: 999, background: 'linear-gradient(135deg,#c9a45c,#a8853f)', color: '#fff', fontSize: 12, fontWeight: 700, letterSpacing: '0.05em' }}>UNTUK ORANG TUA</span>
                <h3 style={{ fontSize: 22, fontWeight: 700, margin: '20px 0 14px' }}>Tenang dari mana saja</h3>
                <p style={{ fontSize: 14, lineHeight: 1.75, opacity: 0.9, margin: '0 0 22px' }}>
                  Pantau buah hati Anda secara langsung melalui ponsel — kapan pun dan di mana pun.
                </p>
                {['Kehadiran & kegiatan anak hari ini real-time', 'Cerita harian + dokumentasi foto kegiatan', 'Tagihan jelas, bayar langsung dari aplikasi', 'Perkembangan & portofolio tumbuh kembang'].map((t) => (
                  <div key={t} style={{ display: 'flex', alignItems: 'center', gap: 12, padding: '9px 0', fontSize: 14 }}>
                    <span style={{ width: 20, height: 20, borderRadius: '50%', background: 'rgba(255,255,255,0.18)', display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: 12, fontWeight: 800 }}>✓</span>
                    {t}
                  </div>
                ))}
              </div>
            </Reveal>
          </div>
        </div>
      </section>

      {/* ============ TESTIMONIALS ============ */}
      <section id="testimoni" style={{ padding: '96px 24px', maxWidth: 1000, margin: '0 auto' }}>
        <Reveal style={{ textAlign: 'center', marginBottom: 48 }}>
          <span style={{ fontSize: 13, fontWeight: 700, letterSpacing: '0.12em', color: '#c9a45c', textTransform: 'uppercase' }}>Testimoni</span>
          <h2 className="lp-serif" style={{ fontSize: 'clamp(30px, 4.6vw, 42px)', fontWeight: 700, color: 'var(--color-primary-dark)', margin: '14px 0 0' }}>
            Dipercaya para Bunda & Pengelola
          </h2>
        </Reveal>
        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(280px, 1fr))', gap: 22 }}>
          {testimonials.map((t, i) => (
            <Reveal key={t.name} delay={i * 0.08}>
              <div style={{ background: 'rgba(255,255,255,0.85)', borderRadius: 24, padding: '32px 28px', border: '1px solid rgba(50,70,58,0.08)', boxShadow: '0 14px 38px rgba(44,60,50,0.09)', height: '100%', display: 'flex', flexDirection: 'column' }}>
                <span style={{ color: '#c9a45c', fontSize: 40, lineHeight: 1, fontWeight: 700, fontFamily: 'Georgia, serif' }}>&ldquo;</span>
                <p style={{ fontSize: 14.5, lineHeight: 1.75, color: 'var(--color-text-secondary)', flex: 1, margin: '6px 0 22px' }}>{t.text}</p>
                <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
                  <span style={{
                    width: 44, height: 44, borderRadius: '50%', display: 'flex', alignItems: 'center', justifyContent: 'center',
                    background: 'linear-gradient(135deg,#3a7059,#8fb5a0)', color: '#fff', fontWeight: 700, fontSize: 15,
                  }}>{t.name.split(' ').map((w) => w[0]).join('').slice(0, 2)}</span>
                  <div>
                    <div style={{ fontSize: 15, fontWeight: 700, color: 'var(--color-text)' }}>{t.name}</div>
                    <div style={{ fontSize: 12.5, color: 'var(--color-text-muted)' }}>{t.role}</div>
                  </div>
                </div>
              </div>
            </Reveal>
          ))}
        </div>
      </section>

      {/* ============ FINAL CTA ============ */}
      <section style={{ padding: '0 24px 110px' }}>
        <Reveal>
          <div style={{
            maxWidth: 1180, margin: '0 auto', borderRadius: 36, overflow: 'hidden', position: 'relative',
            background: 'linear-gradient(135deg,#1f3d31 0%,#2c5a47 55%,#3a7059 100%)', padding: 'clamp(48px, 8vw, 88px) 32px',
            textAlign: 'center', boxShadow: '0 40px 100px rgba(31,61,49,.45)',
          }}>
            <div aria-hidden style={{ position: 'absolute', top: '-40%', left: '-8%', width: 420, height: 420, borderRadius: '50%', background: 'radial-gradient(circle, rgba(201,164,92,0.4), transparent 65%)', filter: 'blur(10px)', animation: 'lpDrift 14s ease-in-out infinite' }} />
            <div aria-hidden style={{ position: 'absolute', bottom: '-45%', right: '-6%', width: 440, height: 440, borderRadius: '50%', background: 'radial-gradient(circle, rgba(255,255,255,0.14), transparent 60%)', animation: 'lpDrift 18s ease-in-out infinite reverse' }} />
            <div style={{ position: 'relative' }}>
              <h2 className="lp-serif" style={{ fontSize: 'clamp(32px, 5vw, 54px)', fontWeight: 700, color: '#fff', margin: 0, lineHeight: 1.15 }}>
                Siap Menata Daycare dengan <span style={{ background: 'linear-gradient(100deg,#e8cf94,#c9a45c)', WebkitBackgroundClip: 'text', backgroundClip: 'text', color: 'transparent' }}>Kelas Premium?</span>
              </h2>
              <p style={{ maxWidth: 560, margin: '20px auto 0', color: 'rgba(255,255,255,0.85)', fontSize: 16, lineHeight: 1.75 }}>
                Bergabunglah hari ini dan rasakan kemudahan mengelola daycare serta ketenangan sebagai orang tua.
              </p>
              <div style={{ marginTop: 36 }}>
                <Link to={appLink} style={{
                  display: 'inline-flex', padding: '17px 42px', borderRadius: 999,
                  background: 'linear-gradient(135deg,#e8cf94,#c9a45c)', color: '#24483a', fontSize: 16, fontWeight: 700, textDecoration: 'none',
                  boxShadow: '0 18px 44px rgba(0,0,0,0.35)', transition: 'transform .15s ease, box-shadow .15s ease',
                }}
                  onMouseEnter={(e) => { e.currentTarget.style.transform = 'translateY(-2px)'; e.currentTarget.style.boxShadow = '0 24px 54px rgba(0,0,0,0.42)'; }}
                  onMouseLeave={(e) => { e.currentTarget.style.transform = 'translateY(0)'; e.currentTarget.style.boxShadow = '0 18px 44px rgba(0,0,0,0.35)'; }}>
                  {appLabel} →
                </Link>
              </div>
            </div>
          </div>
        </Reveal>
      </section>

      {/* ============ FOOTER ============ */}
      <footer style={{ borderTop: '1px solid rgba(50,70,58,0.1)', background: '#efe9dc', padding: '44px 24px 52px' }}>
        <div style={{ maxWidth: 1180, margin: '0 auto', display: 'flex', flexDirection: 'column', gap: 20 }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
            <span style={{ width: 34, height: 34, borderRadius: 10, display: 'flex', alignItems: 'center', justifyContent: 'center', background: 'linear-gradient(135deg,#2c5a47,#3a7059)', color: '#fff', fontWeight: 800, fontSize: 15 }}>TC</span>
            <span className="lp-serif" style={{ fontSize: 20, fontWeight: 700, color: 'var(--color-primary-dark)' }}>TinyCare</span>
          </div>
          <div style={{ display: 'flex', flexWrap: 'wrap', justifyContent: 'space-between', gap: 18, alignItems: 'flex-end' }}>
            <p style={{ margin: 0, fontSize: 13.5, color: 'var(--color-text-muted)', maxWidth: 460, lineHeight: 1.7 }}>
              Platform manajemen daycare premium — menghubungkan pengelola dan orang tua dalam satu ekosistem yang aman, transparan, dan mudah.
            </p>
            <div style={{ display: 'flex', gap: 22, fontSize: 13, color: 'var(--color-text-secondary)', fontWeight: 500 }}>
              <a href="#fitur" style={{ textDecoration: 'none', color: 'inherit' }}>Fitur</a>
              <a href="#cara" style={{ textDecoration: 'none', color: 'inherit' }}>Cara Kerja</a>
              <a href="#testimoni" style={{ textDecoration: 'none', color: 'inherit' }}>Testimoni</a>
            </div>
          </div>
          <div style={{ borderTop: '1px solid rgba(50,70,58,0.1)', paddingTop: 18, display: 'flex', flexWrap: 'wrap', justifyContent: 'space-between', gap: 10 }}>
            <span style={{ fontSize: 12.5, color: 'var(--color-text-muted)' }}>© {new Date().getFullYear()} TinyCare — Semua hak dilindungi.</span>
            <span style={{ fontSize: 12.5, color: 'var(--color-text-muted)' }}>Dibuat dengan <span style={{ color: '#c9a45c' }}>♥</span> untuk anak-anak Indonesia</span>
          </div>
        </div>
      </footer>
    </div>
  );
}