import { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { parentAPI } from '../../services/api';
import ChildPhoto from '../../components/ChildPhoto';

export default function ParentActivities() {
  const [children, setChildren] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const navigate = useNavigate();

  useEffect(() => {
    parentAPI.children()
      .then((res) => {
        const list = res.data.data?.data || res.data.data || [];
        setChildren(Array.isArray(list) ? list : []);
      })
      .catch(() => setError('Gagal memuat data anak.'))
      .finally(() => setLoading(false));
  }, []);

  if (loading) return <div className="tc-loading-screen"><div className="tc-spinner tc-spinner-lg"></div><p>Memuat data...</p></div>;

  return (
    <div>
      <div className="tc-page-header">
        <h1>Aktivitas</h1>
        <p>Pilih anak untuk melihat aktivitasnya.</p>
      </div>

      {error && (
        <div className="tc-card" style={{ padding: '20px', marginBottom: '16px', borderColor: 'var(--color-error)', background: 'var(--color-error-bg)' }}>
          <p style={{ color: 'var(--color-error)', fontSize: '13px' }}>{error}</p>
        </div>
      )}

      {children.length > 0 ? (
        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(170px, 1fr))', gap: '14px' }}>
          {children.map((child) => (
            <div
              key={child.id}
              className="tc-card tc-card-interactive"
              style={{ padding: '18px', textAlign: 'center', cursor: 'pointer' }}
              onClick={() => navigate(`/parent/activities/${child.id}`)}
            >
              <ChildPhoto child={child} width={120} alt={child.name} style={{ margin: '0 auto 12px' }} />
              <h3 style={{ fontSize: '14px', fontWeight: '600', marginBottom: '4px' }}>{child.name}</h3>
              <p style={{ fontSize: '12px', color: 'var(--color-text-muted)' }}>
                {child.gender === 'male' ? 'Laki-laki' : 'Perempuan'}
                {child.birth_date ? ` · ${new Date(child.birth_date).toLocaleDateString('id-ID', { month: 'short', year: 'numeric' })}` : ''}
              </p>
              <div style={{
                marginTop: '10px', display: 'flex', alignItems: 'center', justifyContent: 'center', gap: '4px',
                fontSize: '12px', fontWeight: '500', color: 'var(--color-primary)',
              }}>
                Lihat Aktivitas
                <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                  <polyline points="9 18 15 12 9 6"/>
                </svg>
              </div>
            </div>
          ))}
        </div>
      ) : (
        <div className="tc-card">
          <div className="tc-empty-state">
            <div className="tc-empty-state-icon"><svg width="28" height="28" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8"><circle cx="12" cy="12" r="10"/><path d="M8 14s1.5 2 4 2 4-2 4-2"/><line x1="9" y1="9" x2="9.01" y2="9"/><line x1="15" y1="9" x2="15.01" y2="9"/></svg></div>
            <p className="tc-empty-state-title">Belum ada data anak</p>
            <p className="tc-empty-state-desc">Data akan muncul ketika anak sudah terdaftar di daycare.</p>
          </div>
        </div>
      )}
    </div>
  );
}