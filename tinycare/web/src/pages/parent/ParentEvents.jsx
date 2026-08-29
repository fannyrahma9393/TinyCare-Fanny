import { useState, useEffect } from 'react';
import { parentAPI } from '../../services/api';

export default function ParentEvents() {
  const [items, setItems] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');

  useEffect(() => {
    parentAPI.events()
      .then((res) => setItems(res.data.data?.events || res.data.data?.data || []))
      .catch(() => setError('Gagal memuat jadwal.'))
      .finally(() => setLoading(false));
  }, []);

  if (loading) return <div className="tc-loading-screen"><div className="tc-spinner tc-spinner-lg"></div><p>Memuat jadwal...</p></div>;

  if (error) return (
    <div className="tc-error-state">
      <div className="tc-error-state-icon"><svg width="28" height="28" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8"><circle cx="12" cy="12" r="10"/><line x1="12" y1="8" x2="12" y2="12"/><line x1="12" y1="16" x2="12.01" y2="16"/></svg></div>
      <p className="tc-empty-state-title">{error}</p>
    </div>
  );

  return (
    <div>
      <div className="tc-page-header">
        <h1>Jadwal & Event</h1>
        <p>Jadwal dan event yang akan datang.</p>
      </div>

      {items.length > 0 ? (
        <div style={{ display: 'flex', flexDirection: 'column', gap: '12px' }}>
          {items.map((event) => (
            <div key={event.id} className="tc-card tc-card-hover" style={{ padding: '20px' }}>
              <h3 style={{ fontSize: '15px', fontWeight: '600', marginBottom: '6px' }}>{event.title}</h3>
              {event.description && <p style={{ fontSize: '13px', color: 'var(--color-text-secondary)', marginBottom: '8px', lineHeight: 1.5 }}>{event.description}</p>}
              <div style={{ display: 'flex', flexWrap: 'wrap', gap: '16px', fontSize: '12px', color: 'var(--color-text-muted)' }}>
                <span>📅 {new Date(event.date).toLocaleDateString('id-ID', { weekday: 'long', year: 'numeric', month: 'long', day: 'numeric' })}</span>
                {event.start_time && <span>🕐 {event.start_time} - {event.end_time || '-'}</span>}
                {event.location && <span>📍 {event.location}</span>}
              </div>
            </div>
          ))}
        </div>
      ) : (
        <div className="tc-card">
          <div className="tc-empty-state">
            <div className="tc-empty-state-icon"><svg width="28" height="28" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8"><rect x="3" y="4" width="18" height="18" rx="2" ry="2"/><line x1="16" y1="2" x2="16" y2="6"/><line x1="8" y1="2" x2="8" y2="6"/><line x1="3" y1="10" x2="21" y2="10"/></svg></div>
            <p className="tc-empty-state-title">Belum ada jadwal</p>
            <p className="tc-empty-state-desc">Jadwal akan muncul ketika ada event mendatang.</p>
          </div>
        </div>
      )}
    </div>
  );
}
