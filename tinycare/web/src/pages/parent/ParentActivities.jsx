import { useState, useEffect } from 'react';
import { parentAPI } from '../../services/api';

export default function ParentActivities() {
  const [children, setChildren] = useState([]);
  const [selectedChild, setSelectedChild] = useState('');
  const [activities, setActivities] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');

  useEffect(() => {
    parentAPI.children()
      .then((res) => {
        const list = res.data.data.data || [];
        setChildren(list);
        if (list.length > 0) setSelectedChild(list[0].id);
      })
      .catch(() => setError('Gagal memuat data anak.'))
      .finally(() => setLoading(false));
  }, []);

  useEffect(() => {
    if (!selectedChild) return;
    setLoading(true);
    setError('');
    parentAPI.childActivities(selectedChild)
      .then((res) => setActivities(res.data.data?.data || []))
      .catch(() => { setActivities([]); setError('Gagal memuat data aktivitas.'); })
      .finally(() => setLoading(false));
  }, [selectedChild]);

  if (loading && children.length === 0) return <div className="tc-loading-screen"><div className="tc-spinner tc-spinner-lg"></div><p>Memuat data...</p></div>;

  return (
    <div>
      <div className="tc-page-header">
        <h1>Aktivitas</h1>
        <p>Aktivitas yang diikuti anak Anda.</p>
      </div>

      {children.length > 0 && (
        <div style={{ marginBottom: '20px' }}>
          <label className="tc-label">Pilih Anak</label>
          <select value={selectedChild} onChange={(e) => setSelectedChild(e.target.value)} className="tc-select" style={{ maxWidth: '260px' }}>
            {children.map((c) => <option key={c.id} value={c.id}>{c.name}</option>)}
          </select>
        </div>
      )}

      {error && (
        <div className="tc-card" style={{ padding: '20px', marginBottom: '16px', borderColor: 'var(--color-error)', background: 'var(--color-error-bg)' }}>
          <p style={{ color: 'var(--color-error)', fontSize: '13px' }}>{error}</p>
        </div>
      )}

      {activities.length > 0 ? (
        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(280px, 1fr))', gap: '14px' }}>
          {activities.map((a) => (
            <div key={a.id} className="tc-card tc-card-hover" style={{ padding: '18px' }}>
              <p style={{ fontSize: '14px', fontWeight: '600', marginBottom: '6px' }}>{a.activity?.name || a.name}</p>
              <p style={{ fontSize: '12px', color: 'var(--color-text-muted)' }}>{a.date}{a.time ? ` · ${a.time}` : ''}</p>
              {a.notes && <p style={{ fontSize: '12px', color: 'var(--color-text-secondary)', marginTop: '8px', lineHeight: 1.5 }}>{a.notes}</p>}
            </div>
          ))}
        </div>
      ) : (
        <div className="tc-card">
          <div className="tc-empty-state">
            <div className="tc-empty-state-icon"><svg width="28" height="28" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8"><circle cx="12" cy="12" r="10"/><path d="M8 14s1.5 2 4 2 4-2 4-2"/><line x1="9" y1="9" x2="9.01" y2="9"/><line x1="15" y1="9" x2="15.01" y2="9"/></svg></div>
            <p className="tc-empty-state-title">Belum ada aktivitas</p>
            <p className="tc-empty-state-desc">Aktivitas akan muncul ketika ada kegiatan terbaru.</p>
          </div>
        </div>
      )}
    </div>
  );
}
