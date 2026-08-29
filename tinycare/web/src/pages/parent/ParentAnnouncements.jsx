import { useState, useEffect } from 'react';
import { parentAPI } from '../../services/api';

export default function ParentAnnouncements() {
  const [items, setItems] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');

  useEffect(() => {
    parentAPI.announcements()
      .then((res) => setItems(res.data.data.data || []))
      .catch(() => setError('Gagal memuat pengumuman.'))
      .finally(() => setLoading(false));
  }, []);

  if (loading) return <div className="tc-loading-screen"><div className="tc-spinner tc-spinner-lg"></div><p>Memuat pengumuman...</p></div>;

  if (error) return (
    <div className="tc-error-state">
      <div className="tc-error-state-icon"><svg width="28" height="28" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8"><circle cx="12" cy="12" r="10"/><line x1="12" y1="8" x2="12" y2="12"/><line x1="12" y1="16" x2="12.01" y2="16"/></svg></div>
      <p className="tc-empty-state-title">{error}</p>
    </div>
  );

  return (
    <div>
      <div className="tc-page-header">
        <h1>Pengumuman</h1>
        <p>Pengumuman terbaru dari daycare.</p>
      </div>

      {items.length > 0 ? (
        <div style={{ display: 'flex', flexDirection: 'column', gap: '12px' }}>
          {items.map((item) => (
            <div key={item.id} className="tc-card tc-card-hover" style={{ padding: '20px' }}>
              <div style={{ display: 'flex', alignItems: 'center', gap: '8px', marginBottom: '8px' }}>
                {item.priority === 'high' && <span className="tc-badge tc-badge-error">Penting</span>}
                <h3 style={{ fontSize: '15px', fontWeight: '600' }}>{item.title}</h3>
              </div>
              <p style={{ fontSize: '13px', color: 'var(--color-text-secondary)', lineHeight: 1.6, marginBottom: '8px' }}>{item.content}</p>
              <p style={{ fontSize: '12px', color: 'var(--color-text-muted)' }}>{new Date(item.created_at).toLocaleDateString('id-ID', { year: 'numeric', month: 'long', day: 'numeric' })}</p>
            </div>
          ))}
        </div>
      ) : (
        <div className="tc-card">
          <div className="tc-empty-state">
            <div className="tc-empty-state-icon"><svg width="28" height="28" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8"><path d="M18 8A6 6 0 006 8c0 7-3 9-3 9h18s-3-2-3-9"/><path d="M13.73 21a2 2 0 01-3.46 0"/></svg></div>
            <p className="tc-empty-state-title">Belum ada pengumuman</p>
            <p className="tc-empty-state-desc">Pengumuman akan muncul ketika ada info terbaru.</p>
          </div>
        </div>
      )}
    </div>
  );
}
