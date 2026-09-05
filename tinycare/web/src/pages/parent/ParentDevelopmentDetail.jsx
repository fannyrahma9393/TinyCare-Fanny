import { useState, useEffect } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import { parentAPI } from '../../services/api';
import ChildPhoto from '../../components/ChildPhoto';

export default function ParentDevelopmentDetail() {
  const { childId } = useParams();
  const navigate = useNavigate();
  const [child, setChild] = useState(null);
  const [development, setDevelopment] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');

  useEffect(() => {
    Promise.all([
      parentAPI.childDetail(childId).then((r) => setChild(r.data.data)),
      parentAPI.childDevelopment(childId).then((r) => setDevelopment(r.data.data)),
    ]).catch((_err) => {
      setError('Gagal memuat data perkembangan.');
    }).finally(() => setLoading(false));
  }, [childId]);

  if (loading) return <div className="tc-loading-screen"><div className="tc-spinner tc-spinner-lg"></div><p>Memuat data...</p></div>;

  if (error) return (
    <div className="tc-error-state">
      <div className="tc-error-state-icon"><svg width="28" height="28" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8"><circle cx="12" cy="12" r="10"/><line x1="12" y1="8" x2="12" y2="12"/><line x1="12" y1="16" x2="12.01" y2="16"/></svg></div>
      <p className="tc-empty-state-title">{error}</p>
    </div>
  );

  if (!child) return (
    <div className="tc-card">
      <div className="tc-empty-state">
        <p className="tc-empty-state-title">Anak tidak ditemukan.</p>
      </div>
    </div>
  );

  return (
    <div>
      <button onClick={() => navigate('/parent/development')} style={{ background: 'none', border: 'none', color: 'var(--color-primary)', cursor: 'pointer', fontSize: '13px', marginBottom: '16px', display: 'flex', alignItems: 'center', gap: '4px', fontWeight: 500 }}>
        <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><polyline points="15 18 9 12 15 6"/></svg>
        Kembali ke Perkembangan
      </button>

      {/* Child Profile */}
      <div style={{ display: 'flex', alignItems: 'center', gap: '16px', marginBottom: '24px' }}>
        <ChildPhoto child={child} width={96} alt={child.name} />
        <div>
          <h1 style={{ fontSize: '22px', fontWeight: '700', letterSpacing: '-0.02em' }}>{child.name}</h1>
          <p style={{ fontSize: '13px', color: 'var(--color-text-secondary)' }}>
            {child.gender === 'male' ? 'Laki-laki' : 'Perempuan'} · {child.birth_date ? new Date(child.birth_date).toLocaleDateString('id-ID') : '-'}
          </p>
          <p style={{ fontSize: '12px', color: 'var(--color-text-muted)', marginTop: '4px' }}>Tracking perkembangan anak Anda.</p>
        </div>
      </div>

      {!development && (
        <div className="tc-card">
          <div className="tc-empty-state">
            <div className="tc-empty-state-icon"><svg width="28" height="28" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8"><polyline points="22 12 18 12 15 21 9 3 6 12 2 12"/></svg></div>
            <p className="tc-empty-state-title">Belum ada data perkembangan</p>
            <p className="tc-empty-state-desc">Data perkembangan akan muncul setelah penilaian dilakukan.</p>
          </div>
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
                    <span style={{ fontSize: '18px' }}>{cat.icon || '📊'}</span>
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
                  <span style={{ fontSize: '16px' }}>{cat.icon || '📊'}</span>
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
    </div>
  );
}