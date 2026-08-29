import { useState, useEffect } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import { parentAPI } from '../../services/api';

export default function ParentChildDetail() {
  const { id } = useParams();
  const navigate = useNavigate();
  const [child, setChild] = useState(null);
  const [activeTab, setActiveTab] = useState('overview');
  const [development, setDevelopment] = useState(null);
  const [attendance, setAttendance] = useState([]);
  const [activities, setActivities] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');

  useEffect(() => {
    Promise.all([
      parentAPI.childDetail(id).then((r) => setChild(r.data.data)),
      parentAPI.childDevelopment(id).then((r) => setDevelopment(r.data.data)),
      parentAPI.childAttendance(id).then((r) => setAttendance(r.data.data?.attendance?.data || [])),
      parentAPI.childActivities(id).then((r) => setActivities(r.data.data?.data || [])),
    ]).catch((err) => {
      console.error('Child detail error:', err);
      setError('Gagal memuat data anak.');
    }).finally(() => setLoading(false));
  }, [id]);

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

  const tabs = [
    { key: 'overview', label: 'Ringkasan' },
    { key: 'development', label: 'Perkembangan' },
    { key: 'attendance', label: 'Kehadiran' },
    { key: 'activities', label: 'Aktivitas' },
  ];

  const categoryIcons = { motorik: '🏃', bahasa: '💬', sosial: '👫', kognitif: '🧠', kemandirian: '💪' };

  return (
    <div>
      <button onClick={() => navigate('/parent/children')} style={{ background: 'none', border: 'none', color: 'var(--color-primary)', cursor: 'pointer', fontSize: '13px', marginBottom: '16px', display: 'flex', alignItems: 'center', gap: '4px', fontWeight: 500 }}>
        <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><polyline points="15 18 9 12 15 6"/></svg>
        Kembali ke Anak Saya
      </button>

      {/* Child Profile */}
      <div style={{ display: 'flex', alignItems: 'center', gap: '16px', marginBottom: '24px' }}>
        <div style={{
          width: '56px', height: '56px', borderRadius: 'var(--radius-xl)',
          background: 'var(--color-primary-lighter)',
          display: 'flex', alignItems: 'center', justifyContent: 'center',
        }}>
          <span style={{ color: 'var(--color-primary)', fontWeight: '700', fontSize: '22px' }}>{child.name?.charAt(0)}</span>
        </div>
        <div>
          <h1 style={{ fontSize: '22px', fontWeight: '700', letterSpacing: '-0.02em' }}>{child.name}</h1>
          <p style={{ fontSize: '13px', color: 'var(--color-text-secondary)' }}>
            {child.gender === 'male' ? 'Laki-laki' : 'Perempuan'} · {child.birth_date ? new Date(child.birth_date).toLocaleDateString('id-ID') : '-'}
          </p>
        </div>
      </div>

      {/* Tabs */}
      <div style={{ display: 'flex', gap: '6px', marginBottom: '20px', flexWrap: 'wrap' }}>
        {tabs.map((tab) => (
          <button key={tab.key} onClick={() => setActiveTab(tab.key)}
            className={activeTab === tab.key ? 'tc-btn tc-btn-primary tc-btn-sm' : 'tc-btn tc-btn-secondary tc-btn-sm'}>
            {tab.label}
          </button>
        ))}
      </div>

      {/* Tab Content */}
      {activeTab === 'overview' && development && (
        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(180px, 1fr))', gap: '14px' }}>
          {development.categories?.map((cat) => (
            <div key={cat.id} className="tc-card tc-card-hover" style={{ padding: '18px' }}>
              <h3 style={{ fontSize: '13px', fontWeight: '600', textTransform: 'capitalize', marginBottom: '10px' }}>{categoryIcons[cat.name] || '📊'} {cat.name}</h3>
              <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: '12px', marginBottom: '4px' }}>
                <span style={{ color: 'var(--color-text-muted)' }}>Progress</span>
                <span style={{ fontWeight: '600' }}>{cat.average_progress}%</span>
              </div>
              <div style={{ width: '100%', height: '4px', borderRadius: 'var(--radius-full)', background: 'var(--color-bg-alt)' }}>
                <div style={{ height: '4px', borderRadius: 'var(--radius-full)', background: 'var(--color-primary)', width: `${cat.average_progress}%` }} />
              </div>
              <p style={{ fontSize: '11px', color: 'var(--color-text-muted)', marginTop: '6px' }}>{cat.total_assessments} penilaian</p>
            </div>
          ))}
        </div>
      )}

      {activeTab === 'development' && development && (
        <div className="tc-card" style={{ padding: '20px' }}>
          <h2 style={{ fontSize: '14px', fontWeight: '700', marginBottom: '14px' }}>Riwayat Penilaian</h2>
          <div style={{ display: 'flex', flexDirection: 'column', gap: '8px' }}>
            {development.categories?.flatMap(cat => cat.recent_assessments?.map((a) => (
              <div key={a.id} style={{
                display: 'flex', alignItems: 'center', gap: '12px',
                padding: '12px', borderRadius: 'var(--radius-md)', background: 'var(--color-bg-alt)',
              }}>
                <span style={{ fontSize: '16px' }}>{categoryIcons[cat.name] || '📊'}</span>
                <div style={{ flex: 1 }}>
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
      )}

      {activeTab === 'attendance' && (
        <div className="tc-card" style={{ overflow: 'hidden' }}>
          {attendance.length > 0 ? (
            <table className="tc-table">
              <thead><tr><th>Tanggal</th><th>Status</th><th>Masuk</th><th>Keluar</th></tr></thead>
              <tbody>
                {attendance.map((r) => (
                  <tr key={r.id}>
                    <td style={{ fontSize: '13px' }}>{new Date(r.date).toLocaleDateString('id-ID')}</td>
                    <td><span className={`tc-badge ${r.status === 'hadir' ? 'tc-badge-success' : 'tc-badge-warning'}`}>{r.status}</span></td>
                    <td style={{ fontSize: '13px', color: 'var(--color-text-secondary)' }}>{r.check_in_time || '-'}</td>
                    <td style={{ fontSize: '13px', color: 'var(--color-text-secondary)' }}>{r.check_out_time || '-'}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          ) : (
            <div className="tc-empty-state">
              <p className="tc-empty-state-desc">Belum ada catatan kehadiran.</p>
            </div>
          )}
        </div>
      )}

      {activeTab === 'activities' && (
        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(260px, 1fr))', gap: '14px' }}>
          {activities.length > 0 ? activities.map((a) => (
            <div key={a.id} className="tc-card tc-card-hover" style={{ padding: '18px' }}>
              <p style={{ fontSize: '14px', fontWeight: '600' }}>{a.activity?.name || a.name}</p>
              <p style={{ fontSize: '12px', color: 'var(--color-text-muted)', marginTop: '4px' }}>{a.date}{a.time ? ` · ${a.time}` : ''}</p>
              {a.notes && <p style={{ fontSize: '12px', color: 'var(--color-text-secondary)', marginTop: '8px', lineHeight: 1.5 }}>{a.notes}</p>}
            </div>
          )) : (
            <div className="tc-card" style={{ gridColumn: '1 / -1' }}>
              <div className="tc-empty-state">
                <p className="tc-empty-state-desc">Belum ada aktivitas.</p>
              </div>
            </div>
          )}
        </div>
      )}
    </div>
  );
}
