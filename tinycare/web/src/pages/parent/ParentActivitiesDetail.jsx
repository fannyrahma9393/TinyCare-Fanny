import { useState, useEffect } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import { parentAPI } from '../../services/api';
import ChildPhoto from '../../components/ChildPhoto';

export default function ParentActivitiesDetail() {
  const { childId } = useParams();
  const navigate = useNavigate();
  const [child, setChild] = useState(null);
  const [activities, setActivities] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');

  useEffect(() => {
    Promise.all([
      parentAPI.childDetail(childId).then((r) => setChild(r.data.data)),
      parentAPI.childActivities(childId).then((r) => setActivities(r.data.data?.data || [])),
    ]).catch((_err) => {
      setError('Gagal memuat data aktivitas.');
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
      <button onClick={() => navigate('/parent/activities')} style={{ background: 'none', border: 'none', color: 'var(--color-primary)', cursor: 'pointer', fontSize: '13px', marginBottom: '16px', display: 'flex', alignItems: 'center', gap: '4px', fontWeight: 500 }}>
        <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><polyline points="15 18 9 12 15 6"/></svg>
        Kembali ke Aktivitas
      </button>

      {/* Child Profile */}
      <div style={{ display: 'flex', alignItems: 'center', gap: '16px', marginBottom: '24px' }}>
        <ChildPhoto child={child} width={96} alt={child.name} />
        <div>
          <h1 style={{ fontSize: '22px', fontWeight: '700', letterSpacing: '-0.02em' }}>{child.name}</h1>
          <p style={{ fontSize: '13px', color: 'var(--color-text-secondary)' }}>
            {child.gender === 'male' ? 'Laki-laki' : 'Perempuan'} · {child.birth_date ? new Date(child.birth_date).toLocaleDateString('id-ID') : '-'}
          </p>
          <p style={{ fontSize: '12px', color: 'var(--color-text-muted)', marginTop: '4px' }}>Aktivitas yang diikuti anak Anda.</p>
        </div>
      </div>

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