import { useState, useEffect } from 'react';
import { parentAPI } from '../../services/api';

export default function ParentDevelopment() {
  const [children, setChildren] = useState([]);
  const [selectedChild, setSelectedChild] = useState('');
  const [development, setDevelopment] = useState(null);
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
    parentAPI.childDevelopment(selectedChild)
      .then((res) => setDevelopment(res.data.data))
      .catch(() => { setDevelopment(null); setError('Gagal memuat data perkembangan.'); })
      .finally(() => setLoading(false));
  }, [selectedChild]);

  if (loading && children.length === 0) return <div className="tc-loading-screen"><div className="tc-spinner tc-spinner-lg"></div><p>Memuat data...</p></div>;

  const categoryIcons = { motorik: '🏃', bahasa: '💬', sosial: '👫', kognitif: '🧠', kemandirian: '💪' };

  return (
    <div>
      <div className="tc-page-header">
        <h1>Perkembangan</h1>
        <p>Tracking perkembangan anak Anda.</p>
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

      {development && (
        <>
          {/* Category Progress */}
          <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(200px, 1fr))', gap: '14px', marginBottom: '24px' }}>
            {development.categories?.map((cat) => {
              const pct = cat.average_progress;
              const barColor = pct >= 75 ? 'var(--color-success)' : pct >= 50 ? 'var(--color-warning)' : 'var(--color-primary)';
              return (
                <div key={cat.id} className="tc-card tc-card-hover" style={{ padding: '18px' }}>
                  <div style={{ display: 'flex', alignItems: 'center', gap: '8px', marginBottom: '12px' }}>
                    <span style={{ fontSize: '18px' }}>{categoryIcons[cat.name] || '📊'}</span>
                    <h3 style={{ fontSize: '13px', fontWeight: '600', textTransform: 'capitalize' }}>{cat.name}</h3>
                  </div>
                  <div style={{ marginBottom: '8px' }}>
                    <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: '12px', marginBottom: '4px' }}>
                      <span style={{ color: 'var(--color-text-muted)' }}>Progress</span>
                      <span style={{ fontWeight: '600' }}>{pct}%</span>
                    </div>
                    <div style={{ width: '100%', height: '4px', borderRadius: 'var(--radius-full)', background: 'var(--color-bg-alt)' }}>
                      <div style={{ height: '4px', borderRadius: 'var(--radius-full)', background: barColor, width: `${pct}%`, transition: 'width 0.5s ease' }} />
                    </div>
                  </div>
                  {cat.latest_assessment && <p style={{ fontSize: '11px', color: 'var(--color-text-muted)' }}>Terakhir: <strong>{cat.latest_assessment.progress_label}</strong></p>}
                  <p style={{ fontSize: '11px', color: 'var(--color-text-muted)', marginTop: '4px' }}>{cat.total_assessments} penilaian</p>
                </div>
              );
            })}
          </div>

          {/* Assessment History */}
          <div className="tc-card" style={{ padding: '20px' }}>
            <h2 style={{ fontSize: '14px', fontWeight: '700', marginBottom: '14px' }}>Riwayat Penilaian Terbaru</h2>
            <div style={{ display: 'flex', flexDirection: 'column', gap: '8px' }}>
              {development.categories?.flatMap(cat => cat.recent_assessments?.map((a) => (
                <div key={a.id} style={{
                  display: 'flex', alignItems: 'center', gap: '12px',
                  padding: '12px', borderRadius: 'var(--radius-md)', background: 'var(--color-bg-alt)',
                }}>
                  <span style={{ fontSize: '16px' }}>{categoryIcons[cat.name] || '📊'}</span>
                  <div style={{ flex: 1, minWidth: 0 }}>
                    <p style={{ fontSize: '13px', fontWeight: '600' }}>{a.indicator}</p>
                    <p style={{ fontSize: '11px', color: 'var(--color-text-muted)', textTransform: 'capitalize' }}>{cat.name} · {a.observation_date}</p>
                  </div>
                  <span className="tc-badge tc-badge-success">{a.progress_label}</span>
                </div>
              ))) || []}
              {(!development.categories || development.categories.every(c => !c.recent_assessments?.length)) && (
                <div className="tc-empty-state" style={{ padding: '24px' }}>
                  <p className="tc-empty-state-desc">Belum ada penilaian.</p>
                </div>
              )}
            </div>
          </div>
        </>
      )}

      {!loading && !error && !development && (
        <div className="tc-card">
          <div className="tc-empty-state">
            <div className="tc-empty-state-icon"><svg width="28" height="28" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8"><polyline points="22 12 18 12 15 21 9 3 6 12 2 12"/></svg></div>
            <p className="tc-empty-state-title">Belum ada data perkembangan</p>
            <p className="tc-empty-state-desc">Data perkembangan akan muncul setelah penilaian dilakukan.</p>
          </div>
        </div>
      )}
    </div>
  );
}
