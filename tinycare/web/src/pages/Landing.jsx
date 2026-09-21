import { useCallback, useEffect, useRef, useState } from 'react';
import { Link } from 'react-router-dom';
import { useTranslation } from 'react-i18next';
import { useAuth } from '../context/AuthContext';
import { publicStatsAPI } from '../services/api';
import LanguageSwitcher from '../components/LanguageSwitcher';

/* ─── Premium Utility Hooks ─────────────────────── */

function useInView(threshold = 0.12) {
  const ref = useRef(null);
  const [inView, setInView] = useState(false);
  useEffect(() => {
    const el = ref.current;
    if (!el) return;
    const obs = new IntersectionObserver(
      ([entry]) => { if (entry.isIntersecting) { setInView(true); obs.disconnect(); } },
      { threshold },
    );
    obs.observe(el);
    return () => obs.disconnect();
  }, [threshold]);
  return { ref, inView };
}

function useParallax(speed = 0.3) {
  const ref = useRef(null);
  useEffect(() => {
    let raf;
    const onScroll = () => {
      raf = requestAnimationFrame(() => {
        const el = ref.current;
        if (!el) return;
        const rect = el.getBoundingClientRect();
        const y = (rect.top - window.innerHeight / 2) * speed;
        el.style.transform = `translateY(${y}px)`;
      });
    };
    window.addEventListener('scroll', onScroll, { passive: true });
    return () => { window.removeEventListener('scroll', onScroll); cancelAnimationFrame(raf); };
  }, [speed]);
  return ref;
}

/* ─── Reveal Animation ──────────────────────────── */

function Reveal({ children, delay = 0, style, direction = 'up' }) {
  const { ref, inView } = useInView();
  const transforms = {
    up: 'translateY(52px)',
    down: 'translateY(-52px)',
    left: 'translateX(-52px)',
    right: 'translateX(52px)',
    scale: 'scale(0.88)',
    fade: 'none',
  };
  return (
    <div
      ref={ref}
      style={{
        opacity: inView ? 1 : 0,
        transform: inView ? 'none' : transforms[direction],
        transition: `opacity 1s cubic-bezier(.22,1,.36,1) ${delay}s, transform 1s cubic-bezier(.22,1,.36,1) ${delay}s`,
        willChange: 'opacity, transform',
        ...style,
      }}
    >
      {children}
    </div>
  );
}

/* ─── Animated Counter ──────────────────────────── */

function AnimatedStat({ value, suffix = '', label, icon }) {
  const { t } = useTranslation();
  const ref = useRef(null);
  const [inView, setInView] = useState(false);
  useEffect(() => {
    const obs = new IntersectionObserver(
      ([e]) => { if (e.isIntersecting) { setInView(true); obs.disconnect(); } },
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
    const dur = 2200;
    const tick = (now) => {
      const p = Math.min((now - t0) / dur, 1);
      const eased = 1 - Math.pow(1 - p, 4);
      setVal(Math.round(value * eased));
      if (p < 1) raf = requestAnimationFrame(tick);
    };
    raf = requestAnimationFrame(tick);
    return () => cancelAnimationFrame(raf);
  }, [inView, value]);

  return (
    <div ref={ref} style={{ textAlign: 'center', position: 'relative' }}>
      <div style={{
        width: 56, height: 56, borderRadius: 20, margin: '0 auto 18px',
        display: 'flex', alignItems: 'center', justifyContent: 'center',
        background: 'linear-gradient(135deg, rgba(201,164,92,0.15), rgba(201,164,92,0.05))',
        border: '1px solid rgba(201,164,92,0.2)',
        color: '#b8963e',
      }}>
        {icon}
      </div>
      <div style={{
        fontFamily: "'Playfair Display', Georgia, serif",
        fontSize: 'clamp(38px, 5vw, 58px)',
        fontWeight: 700,
        background: 'linear-gradient(135deg, #2c5a47 0%, #3a7059 50%, #4a8c6f 100%)',
        WebkitBackgroundClip: 'text',
        backgroundClip: 'text',
        color: 'transparent',
        lineHeight: 1,
      }}>
        {inView ? val : value}{suffix}
      </div>
      <div style={{
        margin: '14px auto 0', width: 40, height: 2,
        background: 'linear-gradient(90deg, transparent, #c9a45c, transparent)',
        borderRadius: 99,
      }} />
      <div style={{
        marginTop: 14, fontSize: 13, fontWeight: 500,
        color: 'var(--color-text-secondary)', letterSpacing: '0.06em',
        textTransform: 'uppercase',
      }}>{t(label)}</div>
    </div>
  );
}

/* ─── Floating Particles Background ─────────────── */

function Particles() {
  const canvasRef = useRef(null);
  useEffect(() => {
    const canvas = canvasRef.current;
    if (!canvas) return;
    const ctx = canvas.getContext('2d');
    let raf, particles = [];
    const resize = () => { canvas.width = window.innerWidth; canvas.height = window.innerHeight; };
    resize();
    window.addEventListener('resize', resize);
    const count = Math.min(50, Math.floor(window.innerWidth / 25));
    for (let i = 0; i < count; i++) {
      particles.push({
        x: Math.random() * canvas.width,
        y: Math.random() * canvas.height,
        r: Math.random() * 2 + 0.5,
        dx: (Math.random() - 0.5) * 0.3,
        dy: (Math.random() - 0.5) * 0.3,
        o: Math.random() * 0.25 + 0.05,
      });
    }
    const draw = () => {
      ctx.clearRect(0, 0, canvas.width, canvas.height);
      particles.forEach(p => {
        p.x += p.dx; p.y += p.dy;
        if (p.x < 0) p.x = canvas.width;
        if (p.x > canvas.width) p.x = 0;
        if (p.y < 0) p.y = canvas.height;
        if (p.y > canvas.height) p.y = 0;
        ctx.beginPath();
        ctx.arc(p.x, p.y, p.r, 0, Math.PI * 2);
        ctx.fillStyle = `rgba(201,164,92,${p.o})`;
        ctx.fill();
      });
      // draw lines between close particles
      for (let i = 0; i < particles.length; i++) {
        for (let j = i + 1; j < particles.length; j++) {
          const dx = particles[i].x - particles[j].x;
          const dy = particles[i].y - particles[j].y;
          const dist = Math.sqrt(dx * dx + dy * dy);
          if (dist < 120) {
            ctx.beginPath();
            ctx.moveTo(particles[i].x, particles[i].y);
            ctx.lineTo(particles[j].x, particles[j].y);
            ctx.strokeStyle = `rgba(201,164,92,${0.06 * (1 - dist / 120)})`;
            ctx.lineWidth = 0.5;
            ctx.stroke();
          }
        }
      }
      raf = requestAnimationFrame(draw);
    };
    draw();
    return () => { cancelAnimationFrame(raf); window.removeEventListener('resize', resize); };
  }, []);
  return (
    <canvas
      ref={canvasRef}
      style={{ position: 'absolute', inset: 0, pointerEvents: 'none', zIndex: 0 }}
    />
  );
}

/* ─── SVG Icons ─────────────────────────────────── */

function Icon({ name, size = 24, color = 'currentColor' }) {
  const paths = {
    shield: <path d="M12 2l8 4v6c0 5.25-3.4 9.74-8 10-4.6-.26-8-4.75-8-10V6l8-4zm0 2.25L5.5 7.8V12c0 4.35 2.7 8.05 6.5 8.7 3.8-.65 6.5-4.35 6.5-8.7V7.8L12 4.25zm-.7 11.4l-3.1-3.1 1.4-1.4 1.7 1.7 3.6-3.6 1.4 1.4-5 5z" />,
    chart: <path d="M4 20V10m6 10V4m6 16v-7m4 7H2" strokeWidth="2.2" />,
    users: <path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2M9 11a4 4 0 1 0 0-8 4 4 0 0 0 0 8zm14 10v-2a4 4 0 0 0-3-3.87M16 3.13a4 4 0 0 1 0 7.75" strokeWidth="2" />,
    calendar: <path d="M8 2v4m8-4v4M3 10h18M4 4h16a1 1 0 0 1 1 1v16a1 1 0 0 1-1 1H4a1 1 0 0 1-1-1V5a1 1 0 0 1 1-1z" strokeWidth="2" />,
    spark: <path d="M12 2l1.9 5.6L19.5 9.5l-5.6 1.9L12 17l-1.9-5.6L4.5 9.5l5.6-1.9L12 2zm7 13l.9 2.6 2.6.9-2.6.9-.9 2.6-.9-2.6-2.6-.9 2.6-.9.9-2.6z" />,
    heart: <path d="M12 21s-7.5-4.6-9.7-8.8C.6 9 2.2 5.5 5.6 5.1c2-.2 3.8 1 4.4 2.8.6-1.8 2.4-3 4.4-2.8 3.4.4 5 3.9 3.3 7.1C19.5 16.4 12 21 12 21z" />,
    bell: <path d="M18 8a6 6 0 1 0-12 0c0 7-3 9-3 9h18s-3-2-3-9m-4.27 13a2 2 0 0 0 3.54 0" strokeWidth="2" />,
    camera: <><path d="M23 19a2 2 0 0 1-2 2H3a2 2 0 0 1-2-2V8a2 2 0 0 1 2-2h4l2-3h6l2 3h4a2 2 0 0 1 2 2z" strokeWidth="2" /><circle cx="12" cy="13" r="4" strokeWidth="2" /></>,
    star: <path d="M12 2l3.09 6.26L22 9.27l-5 4.87 1.18 6.88L12 17.77l-6.18 3.25L7 14.14 2 9.27l6.91-1.01L12 2z" strokeWidth="2" />,
    globe: <><circle cx="12" cy="12" r="10" strokeWidth="2" /><path d="M2 12h20M12 2a15.3 15.3 0 0 1 4 10 15.3 15.3 0 0 1-4 10 15.3 15.3 0 0 1-4-10 15.3 15.3 0 0 1 4-10z" strokeWidth="2" /></>,
    zap: <polygon points="13 2 3 14 12 14 11 22 21 10 12 10 13 2" strokeWidth="2" />,
    check: <path d="M20 6L9 17l-5-5" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round" />,
    arrow: <path d="M5 12h14M12 5l7 7-7 7" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" />,
  };
  return (
    <svg width={size} height={size} viewBox="0 0 24 24" fill="none" stroke={color}
      strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
      {paths[name]}
    </svg>
  );
}

/* ─── Ticker ────────────────────────────────────── */

function Ticker() {
  const { t } = useTranslation();
  const items = [
    t('Manajemen Absensi'), t('Laporan Anak Harian'), t('Tagihan Otomatis'), t('Kegiatan Edukatif'),
    t('Galeri Dokumentasi'), t('Pantauan Pertumbuhan'), t('Notifikasi Real-time'), t('Keamanan Berlapis'),
    t('Voucher & Promo'), t('Jadwal Kegiatan'), t('Portofolio Anak'), t('Pembayaran Digital'),
  ];
  const row = [...items, ...items];
  return (
    <div style={{
      overflow: 'hidden',
      borderTop: '1px solid var(--lp-ticker-border)',
      borderBottom: '1px solid var(--lp-ticker-border)',
      background: 'var(--lp-ticker-bg)',
      backdropFilter: 'blur(12px)',
      padding: '18px 0',
      whiteSpace: 'nowrap',
    }}>
      <div style={{ display: 'inline-block', animation: 'lpTicker 40s linear infinite' }}>
        {row.map((item, i) => (
          <span key={i} style={{
            display: 'inline-block', margin: '0 28px', fontSize: 13, fontWeight: 600,
            letterSpacing: '0.06em', color: 'var(--color-text-secondary)',
            textTransform: 'uppercase',
          }}>
            <span style={{
              display: 'inline-block', width: 6, height: 6, borderRadius: '50%',
              background: 'linear-gradient(135deg, #c9a45c, #a8853f)',
              marginRight: 12, verticalAlign: 'middle',
              boxShadow: '0 0 8px rgba(201,164,92,0.4)',
            }} />
            {item}
          </span>
        ))}
      </div>
    </div>
  );
}

/* ─── Feature Card ──────────────────────────────── */

function FeatureCard({ icon, title, desc, index }) {
  const [hovered, setHovered] = useState(false);
  return (
    <Reveal delay={index * 0.08} direction="up">
      <div
        onMouseEnter={() => setHovered(true)}
        onMouseLeave={() => setHovered(false)}
        style={{
          height: '100%', padding: '38px 32px', borderRadius: 28,
          background: hovered
            ? 'var(--lp-card-glass-hover)'
            : 'var(--lp-card-glass)',
          backdropFilter: 'blur(16px)',
          border: hovered ? '1px solid var(--lp-card-border-hover)' : '1px solid var(--lp-card-border)',
          boxShadow: hovered
            ? 'var(--lp-card-shadow-hover), 0 0 0 1px rgba(201,164,92,0.1)'
            : 'var(--lp-card-shadow)',
          transition: 'all 0.5s cubic-bezier(.22,1,.36,1)',
          transform: hovered ? 'translateY(-8px)' : 'none',
          position: 'relative', overflow: 'hidden',
        }}
      >
        {/* Gold shimmer accent */}
        <div style={{
          position: 'absolute', top: 0, left: 0, right: 0, height: 3,
          background: hovered
            ? 'linear-gradient(90deg, transparent, #c9a45c, transparent)'
            : 'transparent',
          transition: 'all 0.5s ease',
        }} />
        <div style={{
          width: 60, height: 60, borderRadius: 20,
          display: 'flex', alignItems: 'center', justifyContent: 'center',
          background: 'linear-gradient(135deg, #e8f4ed, #f5f0e4)',
          color: 'var(--color-primary)',
          marginBottom: 24,
          boxShadow: '0 12px 28px rgba(44,90,71,0.12)',
          transition: 'transform 0.5s cubic-bezier(.22,1,.36,1)',
          transform: hovered ? 'scale(1.1) rotate(-3deg)' : 'none',
        }}>
          <Icon name={icon} size={28} />
        </div>
        <h3 style={{
          fontSize: 19, fontWeight: 700, color: 'var(--color-text)',
          marginBottom: 12, lineHeight: 1.3,
        }}>{title}</h3>
        <p style={{
          fontSize: 14, lineHeight: 1.8, color: 'var(--color-text-secondary)', margin: 0,
        }}>{desc}</p>
      </div>
    </Reveal>
  );
}

/* ─── Testimonial Card ──────────────────────────── */

function TestimonialCard({ name, role, text }) {
  const [hovered, setHovered] = useState(false);
  return (
    <div
      onMouseEnter={() => setHovered(true)}
      onMouseLeave={() => setHovered(false)}
      style={{
        background: hovered
          ? 'var(--lp-testimonial-hover)'
          : 'var(--lp-testimonial-bg)',
        backdropFilter: 'blur(16px)',
        borderRadius: 28, padding: '36px 30px',
        border: hovered ? '1px solid var(--lp-testimonial-border-hover)' : '1px solid var(--lp-testimonial-border)',
        boxShadow: hovered
          ? 'var(--lp-testimonial-shadow-hover)'
          : 'var(--lp-testimonial-shadow)',
        height: '100%', display: 'flex', flexDirection: 'column',
        transition: 'all 0.5s cubic-bezier(.22,1,.36,1)',
        transform: hovered ? 'translateY(-6px)' : 'none',
        position: 'relative', overflow: 'hidden',
        userSelect: 'none',
        WebkitUserSelect: 'none',
        touchAction: 'pan-y',
      }}
    >
      {/* Decorative gold corner */}
      <div style={{
        position: 'absolute', top: -1, right: -1, width: 60, height: 60,
        background: 'linear-gradient(225deg, rgba(201,164,92,0.15), transparent 70%)',
        borderRadius: '0 28px 0 0',
      }} />
      <span style={{
        color: '#c9a45c', fontSize: 48, lineHeight: 1, fontWeight: 700,
        fontFamily: "'Playfair Display', Georgia, serif",
        opacity: 0.6,
      }}>&ldquo;</span>
      <p style={{
        fontSize: 14.5, lineHeight: 1.85, color: 'var(--color-text-secondary)',
        flex: 1, margin: '8px 0 26px', fontStyle: 'italic',
      }}>{text}</p>
      <div style={{ display: 'flex', alignItems: 'center', gap: 14 }}>
        <span style={{
          width: 48, height: 48, borderRadius: '50%', flexShrink: 0,
          display: 'flex', alignItems: 'center', justifyContent: 'center',
          background: 'linear-gradient(135deg, #2c5a47, #4a8c6f)',
          color: '#fff', fontWeight: 700, fontSize: 15,
          boxShadow: '0 8px 20px rgba(44,90,71,0.3)',
          fontFamily: "'Playfair Display', Georgia, serif",
        }}>{name.split(' ').map((w) => w[0]).join('').slice(0, 2)}</span>
        <div>
          <div style={{ fontSize: 15, fontWeight: 700, color: 'var(--color-text)' }}>{name}</div>
          <div style={{ fontSize: 12.5, color: '#c9a45c', fontWeight: 600, letterSpacing: '0.03em' }}>{role}</div>
        </div>
      </div>
    </div>
  );
}

/* ─── Swipeable Testimonial Carousel ─────────── */

function TestimonialCarousel({ items }) {
  const [current, setCurrent] = useState(0);
  const [isMobile, setIsMobile] = useState(false);
  const [isPaused, setIsPaused] = useState(false);
  const [dragOffset, setDragOffset] = useState(0);
  const [isDragging, setIsDragging] = useState(false);
  const [containerWidth, setContainerWidth] = useState(360);
  const touchStart = useRef({ x: 0, y: 0, time: 0 });
  const autoPlayRef = useRef(null);
  const { t } = useTranslation();

  // Detect mobile
  useEffect(() => {
    const check = () => setIsMobile(window.innerWidth < 768);
    check();
    window.addEventListener('resize', check);
    return () => window.removeEventListener('resize', check);
  }, []);

  const total = items.length;

  const goTo = useCallback((i) => {
    setCurrent(((i % total) + total) % total);
    setDragOffset(0);
  }, [total]);

  const next = useCallback(() => goTo(current + 1), [current, goTo]);
  const prev = useCallback(() => goTo(current - 1), [current, goTo]);

  // Auto-play
  useEffect(() => {
    if (isPaused || !isMobile) return;
    autoPlayRef.current = setInterval(next, 5000);
    return () => clearInterval(autoPlayRef.current);
  }, [isPaused, isMobile, next]);

  // Touch handlers for swipe
  const onTouchStart = (e) => {
    const t = e.touches[0];
    touchStart.current = { x: t.clientX, y: t.clientY, time: Date.now() };
    setIsDragging(true);
    clearInterval(autoPlayRef.current);
  };

  const onTouchMove = (e) => {
    if (!isDragging) return;
    const t = e.touches[0];
    const dx = t.clientX - touchStart.current.x;
    const dy = t.clientY - touchStart.current.y;

    // If vertical scroll is dominant, don't interfere
    if (Math.abs(dy) > Math.abs(dx) * 1.2 && Math.abs(dx) < 30) return;

    // Prevent vertical scroll during horizontal swipe
    if (Math.abs(dx) > 10) {
      e.preventDefault();
    }

    // Apply rubber-band resistance at edges
    let offset = dx;
    if ((current === 0 && dx > 0) || (current === total - 1 && dx < 0)) {
      offset = dx * 0.25;
    }
    setDragOffset(offset);
  };

  const onTouchEnd = () => {
    setIsDragging(false);
    const dx = dragOffset;
    const elapsed = Date.now() - touchStart.current.time;
    const velocity = Math.abs(dx) / elapsed;

    // Fast flick or significant drag
    if (velocity > 0.3 || Math.abs(dx) > 60) {
      if (dx < 0) next();
      else prev();
    } else {
      setDragOffset(0);
    }
  };

  // Mouse drag for desktop testing
  const onMouseDown = (e) => {
    if (isMobile) return;
    touchStart.current = { x: e.clientX, y: e.clientY, time: Date.now() };
    setIsDragging(true);
  };

  const onMouseMove = (e) => {
    if (!isDragging) return;
    const dx = e.clientX - touchStart.current.x;
    let offset = dx;
    if ((current === 0 && dx > 0) || (current === total - 1 && dx < 0)) {
      offset = dx * 0.25;
    }
    setDragOffset(offset);
  };

  const onMouseUp = () => {
    if (!isDragging) return;
    setIsDragging(false);
    const dx = dragOffset;
    const elapsed = Date.now() - touchStart.current.time;
    const velocity = Math.abs(dx) / elapsed;
    if (velocity > 0.3 || Math.abs(dx) > 60) {
      if (dx < 0) next();
      else prev();
    } else {
      setDragOffset(0);
    }
  };

  useEffect(() => {
    if (isDragging) {
      window.addEventListener('mousemove', onMouseMove);
      window.addEventListener('mouseup', onMouseUp);
      return () => {
        window.removeEventListener('mousemove', onMouseMove);
        window.removeEventListener('mouseup', onMouseUp);
      };
    }
  }, [isDragging, dragOffset]);

  // Desktop: show all in grid
  if (!isMobile) {
    return (
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(300px, 1fr))', gap: 24 }}>
        {items.map((item, i) => (
          <Reveal key={item.name} delay={i * 0.1} direction="scale">
            <TestimonialCard name={item.name} role={item.role} text={item.text} />
          </Reveal>
        ))}
      </div>
    );
  }

  // Mobile: swipeable carousel
  const slideWidth = 100;
  const translateX = -(current * slideWidth) + (dragOffset / (containerWidth || 360)) * 100;

  return (
    <div
      ref={(node) => {
        if (node) setContainerWidth(node.offsetWidth || 360);
      }}
      onTouchStart={onTouchStart}
      onTouchMove={onTouchMove}
      onTouchEnd={onTouchEnd}
      onMouseDown={onMouseDown}
      onMouseEnter={() => setIsPaused(true)}
      onMouseLeave={() => { setIsPaused(false); if (isDragging) { setIsDragging(false); setDragOffset(0); } }}
      style={{
        overflow: 'hidden', borderRadius: 28,
        position: 'relative', cursor: isDragging ? 'grabbing' : 'grab',
        touchAction: 'pan-y',
        WebkitOverflowScrolling: 'touch',
        padding: '0 0 8px',
      }}
    >
      {/* Slides track */}
      <div style={{
        display: 'flex',
        transform: `translateX(${translateX}%)`,
        transition: isDragging ? 'none' : 'transform 0.5s cubic-bezier(.22,1,.36,1)',
        willChange: 'transform',
      }}>
        {items.map((item) => (
          <div key={item.name} style={{
            minWidth: `${slideWidth}%`,
            padding: '0 4px',
            flexShrink: 0,
          }}>
            <TestimonialCard name={item.name} role={item.role} text={item.text} />
          </div>
        ))}
      </div>

      {/* Navigation dots */}
      <div style={{
        display: 'flex', justifyContent: 'center', gap: 10,
        marginTop: 24, position: 'relative',
      }}>
        {items.map((_, i) => (
          <button
            key={i}
            onClick={() => goTo(i)}
            aria-label={t('Testimoni {{nomor}}', { nomor: i + 1 })}
            style={{
              width: i === current ? 28 : 10,
              height: 10,
              borderRadius: 99,
              border: 'none', cursor: 'pointer',
              background: i === current
                ? 'linear-gradient(135deg, #c9a45c, #a8853f)'
                : 'var(--color-border)',
              transition: 'all 0.4s cubic-bezier(.22,1,.36,1)',
              padding: 0,
              boxShadow: i === current ? '0 4px 12px rgba(201,164,92,0.3)' : 'none',
            }}
          />
        ))}
      </div>

      {/* Prev / Next arrows */}
      <div style={{
        display: 'flex', justifyContent: 'center', gap: 14,
        marginTop: 18,
      }}>
        {[{ dir: prev, label: 'Sebelumnya', path: 'M15 18l-6-6 6-6' }, { dir: next, label: 'Selanjutnya', path: 'M9 18l6-6-6-6' }].map(({ dir, label, path }) => (
          <button
            key={label}
            onClick={dir}
            aria-label={t(label)}
            style={{
              width: 48, height: 48, borderRadius: 14,
              border: '1px solid var(--lp-card-border)',
              background: 'var(--lp-card-glass)',
              backdropFilter: 'blur(8px)',
              color: 'var(--color-text)',
              display: 'flex', alignItems: 'center', justifyContent: 'center',
              cursor: 'pointer', transition: 'all 0.3s ease',
              boxShadow: 'var(--lp-card-shadow)',
            }}
            onMouseEnter={(e) => { e.currentTarget.style.borderColor = 'rgba(201,164,92,0.4)'; e.currentTarget.style.transform = 'scale(1.08)'; }}
            onMouseLeave={(e) => { e.currentTarget.style.borderColor = 'var(--lp-card-border)'; e.currentTarget.style.transform = 'scale(1)'; }}
          >
            <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
              <path d={path} />
            </svg>
          </button>
        ))}
      </div>
    </div>
  );
}

/* ─── Data dari Database ─────────────────────── */

// Kategori icon mapping untuk activities
const activityIcons = {
  edukasi: 'spark', bermain: 'heart', olahraga: 'zap',
  seni: 'star', makan: 'heart', istirahat: 'bell',
};

/* ─── Scroll-to-Top Button ────────────────────── */

function ScrollToTopButton() {
  const { t } = useTranslation();
  const [visible, setVisible] = useState(false);
  const [hovered, setHovered] = useState(false);

  useEffect(() => {
    const onScroll = () => setVisible(window.scrollY > 500);
    window.addEventListener('scroll', onScroll, { passive: true });
    return () => window.removeEventListener('scroll', onScroll);
  }, []);

  const scrollTop = () => window.scrollTo({ top: 0, behavior: 'smooth' });

  return (
    <div
      style={{
        position: 'fixed', bottom: 36, right: 36, zIndex: 50,
        opacity: visible ? 1 : 0,
        transform: visible
          ? (hovered ? 'translateY(-4px) scale(1.08)' : 'translateY(0) scale(1)')
          : 'translateY(20px) scale(0.8)',
        pointerEvents: visible ? 'auto' : 'none',
        transition: 'all 0.5s cubic-bezier(.22,1,.36,1)',
      }}
    >
      {/* Pulse ring behind button */}
      <div
        style={{
          position: 'absolute', inset: -6, borderRadius: 20,
          background: 'linear-gradient(135deg, rgba(201,164,92,0.3), rgba(201,164,92,0.1))',
          opacity: hovered ? 1 : 0,
          transition: 'opacity 0.4s ease',
          filter: 'blur(2px)',
        }}
      />
      <button
        onClick={scrollTop}
        onMouseEnter={() => setHovered(true)}
        onMouseLeave={() => setHovered(false)}
        aria-label={t('Kembali ke atas')}
        style={{
          width: 52, height: 52, borderRadius: 18, border: 'none', cursor: 'pointer',
          background: hovered
            ? 'var(--lp-scroll-top-hover-bg)'
            : 'var(--lp-scroll-top-bg)',
          color: '#fff', display: 'flex', alignItems: 'center', justifyContent: 'center',
          boxShadow: hovered
            ? 'var(--lp-scroll-top-shadow-hover), 0 0 0 1px rgba(201,164,92,0.2)'
            : 'var(--lp-scroll-top-shadow)',
          transition: 'all 0.4s cubic-bezier(.22,1,.36,1)',
          position: 'relative',
        }}
      >
        {/* Inner gold border glow */}
        <div
          style={{
            position: 'absolute', inset: 1, borderRadius: 17,
            border: hovered ? '1px solid rgba(255,255,255,0.25)' : '1px solid rgba(255,255,255,0.1)',
            pointerEvents: 'none',
            transition: 'border-color 0.4s ease',
          }}
        />
        <svg
          width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor"
          strokeWidth="2.2" strokeLinecap="round" strokeLinejoin="round"
          style={{
            transform: hovered ? 'translateY(-1px)' : 'none',
            transition: 'transform 0.3s ease',
          }}
        >
          <path d="M18 15l-6-6-6 6" />
        </svg>
      </button>
    </div>
  );
}

/* ─── Main Component ────────────────────────────── */

export default function Landing() {
  const { user } = useAuth();
  const { t } = useTranslation();
  const [menuOpen, setMenuOpen] = useState(false);
  const [scrolled, setScrolled] = useState(false);
  const [publicStats, setPublicStats] = useState(null);
  const heroRef = useParallax(0.15);

  useEffect(() => {
    const onScroll = () => setScrolled(window.scrollY > 30);
    window.addEventListener('scroll', onScroll, { passive: true });
    return () => window.removeEventListener('scroll', onScroll);
  }, []);

  useEffect(() => {
    publicStatsAPI.get()
      .then((res) => {
        setPublicStats(res.data.data);
      })
      .catch((err) => {
        console.error('[Landing] Failed to load public stats:', err?.response?.data || err.message);
      });
  }, []);

  const isAdmin = user?.role === 'admin' || user?.role === 'admin_master';
  const appLink = user ? (isAdmin ? '/dashboard' : '/parent') : '/login';
  const appLabel = user ? t('Buka Aplikasi') : t('Masuk Aplikasi');

  const formatCurrency = (n) =>
    n ? new Intl.NumberFormat('id-ID', { style: 'currency', currency: 'IDR', maximumFractionDigits: 0 }).format(n) : 'Rp 0';

  const scrollTo = useCallback((id) => {
    document.getElementById(id)?.scrollIntoView({ behavior: 'smooth' });
    setMenuOpen(false);
  }, []);

  return (
    <div style={{
      background: 'var(--lp-bg)',
      color: 'var(--color-text)',
      fontFamily: "'Inter', system-ui, sans-serif",
      overflowX: 'hidden',
    }}>
      {/* ============ NAVBAR ============ */}
      <header style={{
        position: 'fixed', top: 0, left: 0, right: 0, zIndex: 40,
        padding: `${scrolled ? 8 : 16}px 0`,
        background: scrolled ? 'var(--lp-dashboard-chrome)' : 'transparent',
        backdropFilter: scrolled ? 'blur(20px) saturate(1.2)' : 'none',
        borderBottom: scrolled ? '1px solid rgba(50,70,58,0.06)' : '1px solid transparent',
        transition: 'all 0.4s cubic-bezier(.22,1,.36,1)',
      }}>
        <div style={{
          maxWidth: 1200, margin: '0 auto', padding: '0 28px',
          display: 'flex', alignItems: 'center', justifyContent: 'space-between',
        }}>
          <a href="#top" style={{ display: 'flex', alignItems: 'center', gap: 12, textDecoration: 'none' }}>
            <span style={{
              width: 42, height: 42, borderRadius: 14,
              display: 'flex', alignItems: 'center', justifyContent: 'center',
              background: 'linear-gradient(135deg, #2c5a47, #3a7059)',
              color: '#fff', fontWeight: 800, fontSize: 17,
              boxShadow: '0 8px 24px rgba(44,90,71,0.35)',
              fontFamily: "'Playfair Display', Georgia, serif",
            }}>TC</span>
            <span style={{
              fontSize: 23, fontWeight: 700, color: 'var(--color-primary-dark)',
              fontFamily: "'Playfair Display', Georgia, serif",
              letterSpacing: '-0.01em',
            }}>TinyCare</span>
          </a>
          <div className="lp-nav-desktop" style={{ alignItems: 'center', gap: 8 }}>
            {[['Fitur', 'fitur'], ['Cara Kerja', 'cara'], ['Testimoni', 'testimoni']].map(([label, id]) => (
              <button key={id} onClick={() => scrollTo(id)} style={{
                fontSize: 14, fontWeight: 500, color: 'var(--color-text-secondary)',
                padding: '10px 18px', borderRadius: 12, textDecoration: 'none',
                background: 'transparent', border: 'none', cursor: 'pointer',
                transition: 'all 0.2s ease',
              }}
              onMouseEnter={(e) => { e.currentTarget.style.color = 'var(--color-primary-dark)'; e.currentTarget.style.background = 'rgba(44,90,71,0.06)'; }}
              onMouseLeave={(e) => { e.currentTarget.style.color = 'var(--color-text-secondary)'; e.currentTarget.style.background = 'transparent'; }}>
                {t(label)}
              </button>
            ))}
            <Link to={appLink} style={{
              padding: '11px 26px', borderRadius: 14,
              background: 'linear-gradient(135deg, #2c5a47, #3a7059)',
              color: '#fff', fontSize: 13, fontWeight: 700, textDecoration: 'none',
              boxShadow: '0 8px 24px rgba(44,90,71,0.3)',
              transition: 'all 0.3s cubic-bezier(.22,1,.36,1)',
              letterSpacing: '0.02em',
            }}
              onMouseEnter={(e) => { e.currentTarget.style.transform = 'translateY(-2px)'; e.currentTarget.style.boxShadow = '0 14px 32px rgba(44,90,71,0.4)'; }}
              onMouseLeave={(e) => { e.currentTarget.style.transform = 'translateY(0)'; e.currentTarget.style.boxShadow = '0 8px 24px rgba(44,90,71,0.3)'; }}>
              {appLabel}
            </Link>
            <LanguageSwitcher />
          </div>
          <button
            className="lp-menu-btn"
            aria-label={t('Menu')}
            onClick={() => setMenuOpen(!menuOpen)}
            style={{
              display: 'flex', flexDirection: 'column', gap: 5,
              background: 'none', border: 'none', cursor: 'pointer', padding: 8,
              borderRadius: 10, transition: 'background 0.2s',
            }}>
            <span style={{
              width: 26, height: 2, borderRadius: 9,
              background: menuOpen ? '#c9a45c' : 'var(--lp-menu-btn-bar)',
              transform: menuOpen ? 'rotate(45deg) translateY(7px)' : 'none',
              transition: 'all 0.3s ease',
            }} />
            <span style={{
              width: 18, height: 2, borderRadius: 9,
              background: '#c9a45c',
              opacity: menuOpen ? 0 : 1,
              transition: 'all 0.3s ease',
            }} />
            <span style={{
              width: 26, height: 2, borderRadius: 9,
              background: menuOpen ? '#c9a45c' : 'var(--lp-menu-btn-bar)',
              transform: menuOpen ? 'rotate(-45deg) translateY(-7px)' : 'none',
              transition: 'all 0.3s ease',
            }} />
          </button>
        </div>
        {/* Mobile menu */}
        <div style={{
          maxHeight: menuOpen ? 300 : 0, overflow: 'hidden',
          transition: 'max-height 0.4s cubic-bezier(.22,1,.36,1)',
          background: 'var(--lp-dashboard-chrome)', backdropFilter: 'blur(16px)',
        }}>
          <div style={{ padding: '12px 28px 20px', display: 'flex', flexDirection: 'column', gap: 4 }}>
            {[['Fitur', 'fitur'], ['Cara Kerja', 'cara'], ['Testimoni', 'testimoni']].map(([label, id]) => (
              <button key={id} onClick={() => scrollTo(id)} style={{
                fontSize: 15, fontWeight: 500, color: 'var(--color-text-secondary)',
                padding: '12px 16px', borderRadius: 12, textDecoration: 'none',
                background: 'transparent', border: 'none', cursor: 'pointer', textAlign: 'left',
              }}>{t(label)}</button>
            ))}
            <Link to={appLink} style={{
              marginTop: 8, padding: '13px', borderRadius: 14,
              background: 'linear-gradient(135deg, #2c5a47, #3a7059)',
              color: '#fff', fontSize: 14, fontWeight: 700, textAlign: 'center', textDecoration: 'none',
            }}>{appLabel}</Link>
          </div>
        </div>
      </header>

      {/* ============ HERO ============ */}
      <section id="top" style={{
        position: 'relative', minHeight: '100vh', display: 'flex', alignItems: 'center',
        padding: '120px 28px 80px', overflow: 'hidden',
      }}>
        {/* Floating particles canvas */}
        <Particles />

        {/* Animated gradient orbs */}
        <div aria-hidden style={{
          position: 'absolute', top: '5%', left: '-5%',
          width: 600, height: 600, borderRadius: '50%',
          background: `radial-gradient(circle at 30% 30%, var(--lp-glow-orb-gold), transparent 65%)`,
          filter: 'blur(40px)', animation: 'lpDrift 20s ease-in-out infinite',
        }} />
        <div aria-hidden style={{
          position: 'absolute', top: '30%', right: '-8%',
          width: 650, height: 650, borderRadius: '50%',
          background: `radial-gradient(circle at 60% 40%, var(--lp-glow-orb-green), transparent 65%)`,
          filter: 'blur(50px)', animation: 'lpDrift 24s ease-in-out infinite reverse',
        }} />
        <div aria-hidden style={{
          position: 'absolute', bottom: '-8%', left: '25%',
          width: 500, height: 500, borderRadius: '50%',
          background: `radial-gradient(circle, var(--lp-glow-orb-cream), transparent 60%)`,
          animation: 'lpWrinkle 18s ease-in-out infinite',
        }} />

        <div ref={heroRef} style={{
          position: 'relative', maxWidth: 1200, margin: '0 auto', width: '100%', textAlign: 'center', zIndex: 1,
        }}>
          {/* Premium badge */}
          <Reveal>
            <div style={{
              display: 'inline-flex', alignItems: 'center', gap: 10,
              padding: '10px 22px', borderRadius: 999,
              border: `1px solid var(--lp-badge-border)`,
              background: 'var(--lp-badge-bg)',
              backdropFilter: 'blur(12px)',
              fontSize: 13, fontWeight: 700, color: 'var(--lp-badge-text)',
              letterSpacing: '0.06em', textTransform: 'uppercase',
              marginBottom: 32,
              boxShadow: 'var(--lp-badge-shadow)',
            }}>
              <span style={{
                width: 8, height: 8, borderRadius: '50%',
                background: 'linear-gradient(135deg, #c9a45c, #e8cf94)',
                boxShadow: '0 0 0 4px rgba(201,164,92,0.15)',
                animation: 'lpGlow 2.5s ease-in-out infinite',
              }} />
              {t('Platform Manajemen Daycare Premium')}
            </div>
          </Reveal>

          {/* Main heading */}
          <Reveal delay={0.1}>
            <h1 style={{
              fontFamily: "'Playfair Display', Georgia, serif",
              fontSize: 'clamp(42px, 8vw, 92px)',
              lineHeight: 1.05, fontWeight: 700,
              color: 'var(--color-primary-dark)',
              letterSpacing: '-0.025em',
              margin: '0 auto', maxWidth: 980,
            }}>
              {t('Tempat Tumbuh Kembang')}
              <br />
              {t('Anak Anda,')}{' '}
              <span className="lp-gold-text">{t('Dikelola Cerdas')}</span>
            </h1>
          </Reveal>

          {/* Subtitle */}
          <Reveal delay={0.2}>
            <p style={{
              maxWidth: 620, margin: '28px auto 0',
              fontSize: 'clamp(16px, 2vw, 19px)',
              lineHeight: 1.8, color: 'var(--color-text-secondary)',
              fontWeight: 400,
            }}>
              {t('TinyCare menghubungkan daycare & orang tua dalam satu ekosistem premium: kehadiran real-time, laporan harian, tagihan, hingga dokumentasi tumbuh kembang.')}
            </p>
          </Reveal>

          {/* CTA buttons */}
          <Reveal delay={0.3}>
            <div style={{ display: 'flex', gap: 18, justifyContent: 'center', marginTop: 44, flexWrap: 'wrap' }}>
              <Link to={appLink} className="lp-cta-primary" style={{
                padding: '18px 40px', borderRadius: 16,
                background: 'var(--lp-cta-primary-bg)',
                color: '#fff', fontSize: 15, fontWeight: 700, textDecoration: 'none',
                boxShadow: 'var(--lp-cta-primary-shadow)',
                transition: 'all 0.4s cubic-bezier(.22,1,.36,1)',
                display: 'inline-flex', alignItems: 'center', gap: 10,
                letterSpacing: '0.02em',
              }}>
                {appLabel}
                <Icon name="arrow" size={18} color="#fff" />
              </Link>
              <button onClick={() => scrollTo('fitur')} style={{
                padding: '18px 40px', borderRadius: 16,
                border: `1.5px solid var(--lp-cta-secondary-border)`,
                background: 'var(--lp-cta-secondary-bg)', backdropFilter: 'blur(8px)',
                color: 'var(--color-primary-dark)', fontSize: 15, fontWeight: 600,
                cursor: 'pointer', transition: 'all 0.3s ease',
              }}
              onMouseEnter={(e) => { e.currentTarget.style.background = 'var(--lp-cta-secondary-hover)'; e.currentTarget.style.borderColor = 'rgba(201,164,92,0.4)'; }}
              onMouseLeave={(e) => { e.currentTarget.style.background = 'var(--lp-cta-secondary-bg)'; e.currentTarget.style.borderColor = 'var(--lp-cta-secondary-border)'; }}>
                {t('Kenali Fiturnya')}
              </button>
            </div>
          </Reveal>

          {/* Premium Dashboard Preview */}
          <Reveal delay={0.45} style={{ marginTop: 80 }}>
            <div style={{
              maxWidth: 1000, margin: '0 auto', padding: 14, borderRadius: 36,
              background: 'linear-gradient(140deg, rgba(44,90,71,0.1), rgba(201,164,92,0.15), rgba(44,90,71,0.08))',
              boxShadow: '0 50px 100px rgba(44,60,50,0.2), 0 0 0 1px var(--lp-dashboard-border-outer)',
              position: 'relative',
            }}>
              {/* Gold shimmer border */}
              <div style={{
                position: 'absolute', inset: 0, borderRadius: 36,
                border: '1px solid transparent',
                background: 'linear-gradient(135deg, rgba(201,164,92,0.3), transparent, rgba(201,164,92,0.2)) border-box',
                WebkitMask: 'linear-gradient(#fff 0 0) padding-box, linear-gradient(#fff 0 0)',
                WebkitMaskComposite: 'xor', maskComposite: 'exclude',
                pointerEvents: 'none',
              }} />
              <div style={{
                borderRadius: 28, background: 'var(--lp-dashboard-bg)',
                backdropFilter: 'blur(16px)', overflow: 'hidden',
                boxShadow: 'inset 0 1px 0 rgba(255,255,255,0.9)',
              }}>
                {/* Browser chrome */}
                <div style={{
                  display: 'flex', alignItems: 'center', gap: 8,
                  padding: '18px 26px',
                  borderBottom: '1px solid var(--lp-card-border)',
                  background: 'var(--lp-dashboard-chrome)',
                }}>
                  <span style={{ width: 12, height: 12, borderRadius: '50%', background: '#e8857b' }} />
                  <span style={{ width: 12, height: 12, borderRadius: '50%', background: '#e8c87b' }} />
                  <span style={{ width: 12, height: 12, borderRadius: '50%', background: '#7bc89a' }} />
                  <span style={{ flex: 1 }} />
                  <span style={{
                    fontSize: 12, color: 'var(--color-text-muted)', letterSpacing: '0.04em',
                    fontFamily: 'monospace',
                  }}>dashboard.tinycare.app</span>
                  <span style={{ flex: 1 }} />
                  <span style={{ width: 12, height: 12, borderRadius: '50%', background: 'transparent' }} />
                </div>

                {/* Stats grid */}
                <div style={{
                  display: 'grid',
                  gridTemplateColumns: 'repeat(auto-fit, minmax(190px, 1fr))',
                  gap: 18, padding: '28px 26px',
                }}>
                  {[
                    { k: 'Anak Terdaftar', v: publicStats?.total_children?.toString() || '0', c: 'linear-gradient(135deg, #2c5a47, #3a7059)', icon: 'users' },
                    { k: 'Orang Tua Aktif', v: publicStats?.total_parents?.toString() || '0', c: 'linear-gradient(135deg, #8a6a2f, #c9a45c)', icon: 'heart' },
                    { k: 'Kehadiran Hari Ini', v: publicStats?.today_present?.toString() || '0', c: 'linear-gradient(135deg, #3a6fa0, #5a9fc5)', icon: 'calendar' },
                    { k: 'Total Pendapatan', v: formatCurrency(publicStats?.total_revenue), c: 'linear-gradient(135deg, #5d7b6c, #8fb5a0)', icon: 'chart' },
                    { k: 'Paket Aktif', v: publicStats?.active_packages?.toString() || '0', c: 'linear-gradient(135deg, #6b5b95, #8b7bb5)', icon: 'spark' },
                    { k: 'Kegiatan Tersedia', v: publicStats?.total_activities?.toString() || '0', c: 'linear-gradient(135deg, #b56b5b, #d58b7b)', icon: 'calendar' },
                    { k: 'Event Mendatang', v: publicStats?.total_events?.toString() || '0', c: 'linear-gradient(135deg, #5b8fb5, #7bafd5)', icon: 'globe' },
                    { k: 'Dokumentasi', v: publicStats?.total_media?.toString() || '0', c: 'linear-gradient(135deg, #8b6b5b, #ab8b7b)', icon: 'camera' },
                  ].map((s) => (
                    <div key={s.k} style={{
                      borderRadius: 20, padding: '22px 20px',
                      background: s.c, color: '#fff',
                      display: 'flex', flexDirection: 'column', gap: 8,
                      position: 'relative', overflow: 'hidden',
                    }}>
                      {/* Decorative circle */}
                      <div style={{
                        position: 'absolute', top: -20, right: -16,
                        width: 80, height: 80, borderRadius: '50%',
                        background: 'rgba(255,255,255,0.12)',
                      }} />
                      <div style={{
                        position: 'absolute', bottom: -10, left: -8,
                        width: 50, height: 50, borderRadius: '50%',
                        background: 'rgba(255,255,255,0.08)',
                      }} />
                      <div style={{ display: 'flex', alignItems: 'center', gap: 8, position: 'relative' }}>
                        <Icon name={s.icon} size={18} color="rgba(255,255,255,0.8)" />
                        <span style={{ fontSize: 12, opacity: 0.85, letterSpacing: '0.04em', fontWeight: 600 }}>{t(s.k)}</span>
                      </div>
                      <span style={{
                        fontSize: 26, fontWeight: 700, position: 'relative',
                        fontFamily: "'Playfair Display', Georgia, serif",
                      }}>{s.v}</span>
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
      <section style={{ padding: '100px 28px', maxWidth: 1100, margin: '0 auto' }}>
        <Reveal style={{ textAlign: 'center', marginBottom: 64 }}>
          <span style={{
            fontSize: 12, fontWeight: 700, letterSpacing: '0.14em',
            color: '#c9a45c', textTransform: 'uppercase',
          }}>{t('Dipercaya Ribuan Keluarga')}</span>
          <h2 style={{
            fontFamily: "'Playfair Display', Georgia, serif",
            fontSize: 'clamp(30px, 4.6vw, 48px)', fontWeight: 700,
            color: 'var(--color-primary-dark)', margin: '14px 0 0',
          }}>{t('Angka yang Bicara')}</h2>
        </Reveal>
        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(200px, 1fr))', gap: 48 }}>
          <AnimatedStat
            value={publicStats?.total_children || 0} suffix="+" label={t('Anak Terlayani')}
            icon={<Icon name="users" size={26} />}
          />
          <AnimatedStat
            value={publicStats?.total_reports || 0} suffix="+" label={t('Laporan Terkirim')}
            icon={<Icon name="spark" size={26} />}
          />
          <AnimatedStat
            value={publicStats?.avg_satisfaction || 0} suffix="%" label={t('Kepuasan Orang Tua')}
            icon={<Icon name="star" size={26} />}
          />
          <AnimatedStat
            value={publicStats?.total_media || 0} suffix="+" label={t('Dokumentasi Foto')}
            icon={<Icon name="camera" size={26} />}
          />
        </div>
      </section>

      {/* ============ KEGIATAN (dari Database) ============ */}
      <section id="fitur" style={{ padding: '0 28px 60px' }}>
        <div style={{ maxWidth: 1200, margin: '0 auto' }}>
          <Reveal style={{ textAlign: 'center', marginBottom: 64 }}>
            <span style={{
              fontSize: 12, fontWeight: 700, letterSpacing: '0.14em',
              color: '#c9a45c', textTransform: 'uppercase',
            }}>{t('Kegiatan Tersedia')}</span>
            <h2 style={{
              fontFamily: "'Playfair Display', Georgia, serif",
              fontSize: 'clamp(30px, 4.6vw, 48px)', fontWeight: 700,
              color: 'var(--color-primary-dark)', margin: '14px 0 18px',
            }}>{t('Aktivitas di Daycare Kami')}</h2>
            <div className="lp-shimmer-line" style={{ height: 2, width: 140, margin: '0 auto', borderRadius: 99 }} />
            <p style={{
              maxWidth: 560, margin: '20px auto 0', fontSize: 16,
              color: 'var(--color-text-secondary)', lineHeight: 1.8,
            }}>
              {t('{{count}} kegiatan aktif tersedia untuk tumbuh kembang anak Anda.', { count: publicStats?.total_activities || 0 })}
            </p>
          </Reveal>
          <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(320px, 1fr))', gap: 24 }}>
            {(publicStats?.activities || []).map((f, i) => (
              <FeatureCard
                key={f.id}
                icon={activityIcons[f.category] || 'spark'}
                title={f.name}
                desc={f.description || t('Kategori: {{kategori}}', { kategori: f.category || '-' })}
                index={i}
              />
            ))}
            {(!publicStats?.activities || publicStats.activities.length === 0) && (
              <Reveal>
                <div style={{
                  gridColumn: '1 / -1', textAlign: 'center', padding: '48px 24px',
                  color: 'var(--color-text-muted)', fontSize: 15,
                }}>
                  {t('Belum ada kegiatan yang terdaftar.')}
                </div>
              </Reveal>
            )}
          </div>
        </div>
      </section>

      {/* ============ HOW IT WORKS ============ */}
      <section id="cara" style={{
        padding: '108px 28px',
        background: 'var(--lp-how-bg)',
        position: 'relative',
      }}>
        {/* Decorative element */}
        <div aria-hidden style={{
          position: 'absolute', top: 40, right: '10%', width: 200, height: 200,
          borderRadius: '50%', border: '1px solid var(--lp-decorative-ring)',
          animation: 'lpWrinkle 12s ease-in-out infinite',
        }} />
        <div style={{ maxWidth: 1200, margin: '0 auto', position: 'relative' }}>
          <Reveal style={{ textAlign: 'center', marginBottom: 64 }}>
            <span style={{
              fontSize: 12, fontWeight: 700, letterSpacing: '0.14em',
              color: '#c9a45c', textTransform: 'uppercase',
            }}>{t('Cara Kerja')}</span>
            <h2 style={{
              fontFamily: "'Playfair Display', Georgia, serif",
              fontSize: 'clamp(30px, 4.6vw, 48px)', fontWeight: 700,
              color: 'var(--color-primary-dark)', margin: '14px 0 0',
            }}>{t('Satu Platform, Dua Dunia')}</h2>
          </Reveal>
          <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(340px, 1fr))', gap: 28 }}>
            {/* Admin Panel */}
            <Reveal>
              <div style={{
                background: 'var(--lp-panel-light-bg)', backdropFilter: 'blur(16px)',
                borderRadius: 30, padding: '44px 38px',
                border: '1px solid var(--lp-panel-light-border)',
                height: '100%',
                boxShadow: 'var(--lp-card-shadow)',
              }}>
                <span style={{
                  display: 'inline-flex', padding: '8px 18px', borderRadius: 999,
                  background: 'linear-gradient(135deg, #2c5a47, #3a7059)',
                  color: '#fff', fontSize: 11, fontWeight: 700,
                  letterSpacing: '0.08em', textTransform: 'uppercase',
                }}>{t('Untuk Pengelola')}</span>
                <h3 style={{
                  fontSize: 24, fontWeight: 700, color: 'var(--color-text)',
                  margin: '24px 0 16px',
                  fontFamily: "'Playfair Display', Georgia, serif",
                }}>{t('Operasional menjadi ringan')}</h3>
                <p style={{
                  fontSize: 14.5, lineHeight: 1.8, color: 'var(--color-text-secondary)',
                  margin: '0 0 28px',
                }}>
                  {t('Kelola data anak, kehadiran, paket, voucher, tagihan, hingga pembayaran dalam satu panel elegan.')}
                </p>
                {[
                  'Kelola murid & orang tua secara terpusat',
                  'Pembuatan tagihan & verifikasi pembayaran otomatis',
                  'Laporan harian, mingguan, dan bulanan satu klik',
                  'Riwayat kehadiran & aktivitas tiap anak terlacak',
                ].map((item, i) => (
                  <Reveal key={item} delay={0.1 + i * 0.06}>
                    <div style={{
                      display: 'flex', alignItems: 'center', gap: 14,
                      padding: '11px 0', fontSize: 14, color: 'var(--color-text-secondary)',
                    }}>
                      <span style={{
                        width: 22, height: 22, borderRadius: '50%', flexShrink: 0,
                        background: 'var(--lp-check-bg)',
                        color: 'var(--color-success)', display: 'flex',
                        alignItems: 'center', justifyContent: 'center',
                        fontSize: 11, fontWeight: 800,
                      }}><Icon name="check" size={12} /></span>
                      {t(item)}
                    </div>
                  </Reveal>
                ))}
              </div>
            </Reveal>

            {/* Parent Panel */}
            <Reveal delay={0.12}>
              <div style={{
                background: 'linear-gradient(150deg, #1f3d31, #2c5a47 55%, #3a7059)',
                borderRadius: 30, padding: '44px 38px', color: '#fff',
                height: '100%',
                boxShadow: 'var(--lp-panel-dark-shadow)',
                position: 'relative', overflow: 'hidden',
              }}>
                {/* Decorative circles */}
                <div style={{
                  position: 'absolute', top: -40, right: -30,
                  width: 200, height: 200, borderRadius: '50%',
                  background: 'rgba(201,164,92,0.12)',
                }} />
                <div style={{
                  position: 'absolute', bottom: -60, left: -40,
                  width: 250, height: 250, borderRadius: '50%',
                  background: 'rgba(255,255,255,0.04)',
                }} />
                <div style={{ position: 'relative' }}>
                  <span style={{
                    display: 'inline-flex', padding: '8px 18px', borderRadius: 999,
                    background: 'linear-gradient(135deg, #c9a45c, #a8853f)',
                    color: '#fff', fontSize: 11, fontWeight: 700,
                    letterSpacing: '0.08em', textTransform: 'uppercase',
                    boxShadow: '0 8px 20px rgba(201,164,92,0.3)',
                  }}>{t('Untuk Orang Tua')}</span>
                  <h3 style={{
                    fontSize: 24, fontWeight: 700, margin: '24px 0 16px',
                    fontFamily: "'Playfair Display', Georgia, serif",
                  }}>{t('Tenang dari mana saja')}</h3>
                  <p style={{
                    fontSize: 14.5, lineHeight: 1.8, opacity: 0.9,
                    margin: '0 0 28px',
                  }}>
                    {t('Pantau buah hati Anda secara real-time melalui ponsel — kapan pun dan di mana pun.')}
                  </p>
                  {[
                    'Kehadiran & kegiatan anak hari ini real-time',
                    'Cerita harian + dokumentasi foto kegiatan',
                    'Tagihan jelas, bayar langsung dari aplikasi',
                    'Perkembangan & portofolio tumbuh kembang',
                  ].map((item, i) => (
                    <Reveal key={item} delay={0.2 + i * 0.06}>
                      <div style={{
                        display: 'flex', alignItems: 'center', gap: 14,
                        padding: '11px 0', fontSize: 14,
                      }}>
                        <span style={{
                          width: 22, height: 22, borderRadius: '50%', flexShrink: 0,
                          background: 'rgba(201,164,92,0.25)',
                          display: 'flex', alignItems: 'center', justifyContent: 'center',
                          fontSize: 11, fontWeight: 800,
                        }}><Icon name="check" size={12} color="#e8cf94" /></span>
                        {t(item)}
                      </div>
                    </Reveal>
                  ))}
                </div>
              </div>
            </Reveal>
          </div>
        </div>
      </section>

      {/* ============ PAKET (dari Database) ============ */}
      <section style={{ padding: '48px 28px 60px' }}>
        <div style={{ maxWidth: 1200, margin: '0 auto' }}>
          <Reveal style={{ textAlign: 'center', marginBottom: 48 }}>
            <span style={{
              fontSize: 12, fontWeight: 700, letterSpacing: '0.14em',
              color: '#c9a45c', textTransform: 'uppercase',
            }}>{t('Paket Kami')}</span>
            <h2 style={{
              fontFamily: "'Playfair Display', Georgia, serif",
              fontSize: 'clamp(30px, 4.6vw, 42px)', fontWeight: 700,
              color: 'var(--color-primary-dark)', margin: '14px 0 0',
            }}>{t('{{count}} Paket Aktif', { count: publicStats?.active_packages || 0 })}</h2>
          </Reveal>
          <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(260px, 1fr))', gap: 22 }}>
            {(publicStats?.packages || []).map((p, i) => (
              <Reveal key={p.id} delay={i * 0.08}>
                <div style={{
                  background: 'var(--lp-card-glass)', backdropFilter: 'blur(16px)',
                  borderRadius: 24, padding: '32px 28px',
                  border: '1px solid var(--lp-card-border)',
                  boxShadow: 'var(--lp-card-shadow)',
                  height: '100%', position: 'relative', overflow: 'hidden',
                }}>
                  <div style={{
                    position: 'absolute', top: -1, right: -1, width: 50, height: 50,
                    background: 'linear-gradient(225deg, rgba(201,164,92,0.15), transparent 70%)',
                    borderRadius: '0 24px 0 0',
                  }} />
                  <h3 style={{
                    fontSize: 18, fontWeight: 700, color: 'var(--color-text)',
                    marginBottom: 8,
                  }}>{p.name}</h3>
                  <p style={{
                    fontSize: 13.5, lineHeight: 1.7, color: 'var(--color-text-secondary)',
                    margin: '0 0 18px', minHeight: 46,
                  }}>{p.description || t('Paket premium untuk tumbuh kembang optimal.')}</p>
                  <div style={{ display: 'flex', alignItems: 'baseline', gap: 4 }}>
                    <span style={{
                      fontSize: 24, fontWeight: 700, color: 'var(--color-primary-dark)',
                      fontFamily: "'Playfair Display', Georgia, serif",
                    }}>{formatCurrency(p.price)}</span>
                    <span style={{ fontSize: 12, color: 'var(--color-text-muted)' }}>{' / '}{t('{{hari}} hari', { hari: p.duration_days })}</span>
                  </div>
                </div>
              </Reveal>
            ))}
            {(!publicStats?.packages || publicStats.packages.length === 0) && (
              <Reveal>
                <div style={{
                  gridColumn: '1 / -1', textAlign: 'center', padding: '48px 24px',
                  color: 'var(--color-text-muted)', fontSize: 15,
                }}>
                  {t('Belum ada paket yang tersedia.')}
                </div>
              </Reveal>
            )}
          </div>
        </div>
      </section>

      {/* ============ TESTIMONIALS (dari Database) ============ */}
      <section id="testimoni" style={{ padding: '48px 28px 108px', maxWidth: 1100, margin: '0 auto' }}>
        <Reveal style={{ textAlign: 'center', marginBottom: 56 }}>
          <span style={{
            fontSize: 12, fontWeight: 700, letterSpacing: '0.14em',
            color: '#c9a45c', textTransform: 'uppercase',
          }}>{t('Testimoni')}</span>
          <h2 style={{
            fontFamily: "'Playfair Display', Georgia, serif",
            fontSize: 'clamp(30px, 4.6vw, 46px)', fontWeight: 700,
            color: 'var(--color-primary-dark)', margin: '14px 0 0',
          }}>{t('{{count}} Ulasan dari Orang Tua', { count: publicStats?.total_feedback || 0 })}</h2>
        </Reveal>
        {(publicStats?.testimonials || []).length > 0 ? (
          <TestimonialCarousel items={publicStats.testimonials} />
        ) : (
          <Reveal>
            <div style={{
              textAlign: 'center', padding: '48px 24px',
              color: 'var(--color-text-muted)', fontSize: 15,
            }}>
              {t('Belum ada testimoni dari orang tua.')}
            </div>
          </Reveal>
        )}
      </section>

      {/* ============ PENGUMUMAN (dari Database) ============ */}
      {(publicStats?.announcements || []).length > 0 && (
        <section style={{ padding: '0 28px 60px' }}>
          <div style={{ maxWidth: 1200, margin: '0 auto' }}>
            <Reveal style={{ textAlign: 'center', marginBottom: 48 }}>
              <span style={{
                fontSize: 12, fontWeight: 700, letterSpacing: '0.14em',
                color: '#c9a45c', textTransform: 'uppercase',
              }}>{t('Pengumuman Terbaru')}</span>
              <h2 style={{
                fontFamily: "'Playfair Display', Georgia, serif",
                fontSize: 'clamp(28px, 4vw, 40px)', fontWeight: 700,
                color: 'var(--color-primary-dark)', margin: '14px 0 0',
              }}>{t('{{count}} Pengumuman Aktif', { count: publicStats.total_announcements })}</h2>
            </Reveal>
            <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(320px, 1fr))', gap: 20 }}>
              {publicStats.announcements.map((a, i) => (
                <Reveal key={a.id} delay={i * 0.07}>
                  <div style={{
                    background: 'var(--lp-card-glass)', backdropFilter: 'blur(16px)',
                    borderRadius: 22, padding: '28px 26px',
                    border: '1px solid var(--lp-card-border)',
                    boxShadow: 'var(--lp-card-shadow)',
                  }}>
                    <div style={{ display: 'flex', alignItems: 'center', gap: 10, marginBottom: 12 }}>
                      <span style={{
                        padding: '3px 10px', borderRadius: 999, fontSize: 11, fontWeight: 700,
                        background: a.priority === 'urgent' ? 'var(--color-error-bg)' : a.priority === 'high' ? 'var(--color-warning-bg)' : 'var(--color-info-bg)',
                        color: a.priority === 'urgent' ? 'var(--color-error)' : a.priority === 'high' ? 'var(--color-warning)' : 'var(--color-info)',
                        textTransform: 'uppercase', letterSpacing: '0.04em',
                      }}>{a.priority}</span>
                      {a.publish_date && (
                        <span style={{ fontSize: 12, color: 'var(--color-text-muted)' }}>{a.publish_date}</span>
                      )}
                    </div>
                    <h3 style={{
                      fontSize: 16, fontWeight: 700, color: 'var(--color-text)',
                      marginBottom: 8,
                    }}>{a.title}</h3>
                    <p style={{
                      fontSize: 13.5, lineHeight: 1.7, color: 'var(--color-text-secondary)',
                      margin: 0,
                    }}>{a.content?.substring(0, 150)}{a.content?.length > 150 ? '...' : ''}</p>
                  </div>
                </Reveal>
              ))}
            </div>
          </div>
        </section>
      )}

      {/* ============ EVENT (dari Database) ============ */}
      {(publicStats?.events || []).length > 0 && (
        <section style={{ padding: '0 28px 60px' }}>
          <div style={{ maxWidth: 1200, margin: '0 auto' }}>
            <Reveal style={{ textAlign: 'center', marginBottom: 48 }}>
              <span style={{
                fontSize: 12, fontWeight: 700, letterSpacing: '0.14em',
                color: '#c9a45c', textTransform: 'uppercase',
              }}>{t('Event Mendatang')}</span>
              <h2 style={{
                fontFamily: "'Playfair Display', Georgia, serif",
                fontSize: 'clamp(28px, 4vw, 40px)', fontWeight: 700,
                color: 'var(--color-primary-dark)', margin: '14px 0 0',
              }}>{t('{{count}} Event Terjadwal', { count: publicStats.total_events })}</h2>
            </Reveal>
            <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(300px, 1fr))', gap: 20 }}>
              {publicStats.events.map((e, i) => (
                <Reveal key={e.id} delay={i * 0.07}>
                  <div style={{
                    background: 'var(--lp-card-glass)', backdropFilter: 'blur(16px)',
                    borderRadius: 22, padding: '28px 26px',
                    border: '1px solid var(--lp-card-border)',
                    boxShadow: 'var(--lp-card-shadow)',
                    display: 'flex', gap: 18, alignItems: 'flex-start',
                  }}>
                    <div style={{
                      width: 56, height: 56, borderRadius: 16, flexShrink: 0,
                      display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center',
                      background: 'linear-gradient(135deg, #2c5a47, #3a7059)', color: '#fff',
                      boxShadow: '0 8px 20px rgba(44,90,71,0.25)',
                    }}>
                      <span style={{ fontSize: 18, fontWeight: 800, lineHeight: 1 }}>{new Date(e.date).getDate()}</span>
                      <span style={{ fontSize: 9, fontWeight: 600, opacity: 0.85, textTransform: 'uppercase' }}>{new Date(e.date).toLocaleDateString('id-ID', { month: 'short' })}</span>
                    </div>
                    <div style={{ flex: 1, minWidth: 0 }}>
                      <h3 style={{
                        fontSize: 15, fontWeight: 700, color: 'var(--color-text)',
                        marginBottom: 4, lineHeight: 1.3,
                      }}>{e.title}</h3>
                      <p style={{
                        fontSize: 13, color: 'var(--color-text-secondary)',
                        margin: '0 0 8px', lineHeight: 1.6,
                      }}>{e.description?.substring(0, 100)}{e.description?.length > 100 ? '...' : ''}</p>
                      <div style={{ display: 'flex', gap: 14, fontSize: 12, color: 'var(--color-text-muted)' }}>
                        {e.start_time && <span>{e.start_time} - {e.end_time}</span>}
                        {e.location && <span>📍 {e.location}</span>}
                      </div>
                    </div>
                  </div>
                </Reveal>
              ))}
            </div>
          </div>
        </section>
      )}

      {/* ============ FINAL CTA ============ */}
      <section style={{ padding: '0 28px 120px' }}>
        <Reveal>
          <div style={{
            maxWidth: 1200, margin: '0 auto', borderRadius: 40, overflow: 'hidden',
            position: 'relative',
            background: 'var(--lp-cta-section-bg)',
            padding: 'clamp(56px, 9vw, 96px) 40px',
            textAlign: 'center',
            boxShadow: 'var(--lp-cta-section-shadow)',
          }}>
            {/* Animated decorative elements */}
            <div aria-hidden style={{
              position: 'absolute', top: '-40%', left: '-6%',
              width: 480, height: 480, borderRadius: '50%',
              background: 'radial-gradient(circle, rgba(201,164,92,0.35), transparent 65%)',
              filter: 'blur(30px)', animation: 'lpDrift 16s ease-in-out infinite',
            }} />
            <div aria-hidden style={{
              position: 'absolute', bottom: '-45%', right: '-4%',
              width: 460, height: 460, borderRadius: '50%',
              background: 'radial-gradient(circle, rgba(255,255,255,0.1), transparent 60%)',
              animation: 'lpDrift 20s ease-in-out infinite reverse',
            }} />
            {/* Gold border glow */}
            <div style={{
              position: 'absolute', inset: 0, borderRadius: 40,
              border: '1px solid rgba(201,164,92,0.2)',
              pointerEvents: 'none',
            }} />
            <div style={{ position: 'relative', zIndex: 1 }}>
              <h2 style={{
                fontFamily: "'Playfair Display', Georgia, serif",
                fontSize: 'clamp(34px, 5.5vw, 58px)', fontWeight: 700,
                color: '#fff', margin: 0, lineHeight: 1.12,
              }}>
                {t('Siap Menata Daycare dengan')}{' '}
                <span style={{
                  background: 'linear-gradient(100deg, #e8cf94, #c9a45c, #e8cf94)',
                  backgroundSize: '200% auto',
                  WebkitBackgroundClip: 'text', backgroundClip: 'text',
                  color: 'transparent',
                  animation: 'lpShimmerText 4s ease-in-out infinite',
                }}>{t('Kelas Premium?')}</span>
              </h2>
              <p style={{
                maxWidth: 560, margin: '24px auto 0',
                color: 'rgba(255,255,255,0.85)', fontSize: 17, lineHeight: 1.8,
              }}>
                {t('Bergabunglah hari ini dan rasakan kemudahan mengelola daycare serta ketenangan sebagai orang tua.')}
              </p>
              <div style={{ marginTop: 40 }}>
                <Link to={appLink} style={{
                  display: 'inline-flex', alignItems: 'center', gap: 10,
                  padding: '18px 44px', borderRadius: 16,
                  background: 'linear-gradient(135deg, #e8cf94, #c9a45c, #d6b26a)',
                  color: '#1a3328', fontSize: 16, fontWeight: 700, textDecoration: 'none',
                  boxShadow: '0 20px 50px rgba(0,0,0,0.35)',
                  transition: 'all 0.4s cubic-bezier(.22,1,.36,1)',
                  letterSpacing: '0.02em',
                }}
                  onMouseEnter={(e) => { e.currentTarget.style.transform = 'translateY(-3px) scale(1.02)'; e.currentTarget.style.boxShadow = '0 28px 60px rgba(0,0,0,0.45)'; }}
                  onMouseLeave={(e) => { e.currentTarget.style.transform = 'translateY(0) scale(1)'; e.currentTarget.style.boxShadow = '0 20px 50px rgba(0,0,0,0.35)'; }}>
                  {appLabel}
                  <Icon name="arrow" size={20} color="#1a3328" />
                </Link>
              </div>
            </div>
          </div>
        </Reveal>
      </section>

      {/* ============ SCROLL TO TOP ============ */}
      <ScrollToTopButton />

      {/* ============ FOOTER ============ */}
      <footer style={{
        borderTop: '1px solid var(--lp-footer-border)',
        background: 'var(--lp-footer-bg)',
        backdropFilter: 'blur(12px)',
        padding: '48px 28px 56px',
      }}>
        <div style={{ maxWidth: 1200, margin: '0 auto', display: 'flex', flexDirection: 'column', gap: 24 }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
            <span style={{
              width: 36, height: 36, borderRadius: 11,
              display: 'flex', alignItems: 'center', justifyContent: 'center',
              background: 'linear-gradient(135deg, #2c5a47, #3a7059)',
              color: '#fff', fontWeight: 800, fontSize: 14,
              fontFamily: "'Playfair Display', Georgia, serif",
            }}>TC</span>
            <span style={{
              fontSize: 21, fontWeight: 700, color: 'var(--color-primary-dark)',
              fontFamily: "'Playfair Display', Georgia, serif",
            }}>TinyCare</span>
          </div>
          <div style={{
            display: 'flex', flexWrap: 'wrap', justifyContent: 'space-between',
            gap: 20, alignItems: 'flex-end',
          }}>
            <p style={{
              margin: 0, fontSize: 13.5, color: 'var(--color-text-muted)',
              maxWidth: 480, lineHeight: 1.8,
            }}>
              {t('Platform manajemen daycare premium — menghubungkan pengelola dan orang tua dalam satu ekosistem yang aman, transparan, dan mudah.')}
            </p>
            <div style={{ display: 'flex', gap: 24, fontSize: 13, color: 'var(--color-text-secondary)', fontWeight: 500 }}>
              <button onClick={() => scrollTo('fitur')} style={{ textDecoration: 'none', color: 'inherit', background: 'none', border: 'none', cursor: 'pointer', fontSize: 'inherit', fontWeight: 'inherit' }}>{t('Fitur')}</button>
              <button onClick={() => scrollTo('cara')} style={{ textDecoration: 'none', color: 'inherit', background: 'none', border: 'none', cursor: 'pointer', fontSize: 'inherit', fontWeight: 'inherit' }}>{t('Cara Kerja')}</button>
              <button onClick={() => scrollTo('testimoni')} style={{ textDecoration: 'none', color: 'inherit', background: 'none', border: 'none', cursor: 'pointer', fontSize: 'inherit', fontWeight: 'inherit' }}>{t('Testimoni')}</button>
            </div>
          </div>
          <div style={{
            borderTop: '1px solid var(--lp-footer-border)', paddingTop: 20,
            display: 'flex', flexWrap: 'wrap', justifyContent: 'space-between', gap: 12,
          }}>
            <span style={{ fontSize: 12.5, color: 'var(--color-text-muted)' }}>
              {t('© {{tahun}} TinyCare — Semua hak dilindungi.', { tahun: new Date().getFullYear() })}
            </span>
            <span style={{ fontSize: 12.5, color: 'var(--color-text-muted)' }}>
              {t('Dibuat dengan')} <span style={{ color: '#c9a45c' }}>♥</span> {t('untuk anak-anak Indonesia')}
            </span>
          </div>
        </div>
      </footer>
    </div>
  );
}
