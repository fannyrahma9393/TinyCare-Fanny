import { useState, useEffect } from 'react';
import { parentAPI } from '../../services/api';
import { useNavigate } from 'react-router-dom';
import ChildPhoto from '../../components/ChildPhoto';

export default function ParentChildren() {
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

  if (loading) return <div className="tc-loading-screen"><div className="tc-spinner tc-spinner-lg"></div><p>Memuat data anak...</p></div>;

  if (error) return (
    <div className="tc-error-state">
      <div className="tc-error-state-icon"><svg width="28" height="28" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8"><circle cx="12" cy="12" r="10"/><line x1="12" y1="8" x2="12" y2="12"/><line x1="12" y1="16" x2="12.01" y2="16"/></svg></div>
      <p className="tc-empty-state-title">{error}</p>
    </div>
  );

  return (
    <div>
      <div className="tc-page-header">
        <h1>Anak Saya</h1>
        <p>Daftar anak yang terdaftar di daycare.</p>
      </div>

      {children.length > 0 ? (
        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(300px, 1fr))', gap: '16px' }}>
          {children.map((child) => (
            <div
              key={child.id}
              className="tc-card tc-card-interactive"
              style={{ padding: '24px', cursor: 'pointer' }}
              onClick={() => navigate(`/parent/children/${child.id}`)}
            >
              <div style={{ display: 'flex', alignItems: 'center', gap: '14px', marginBottom: '16px' }}>
                <ChildPhoto child={child} width={52} alt={child.name} />
                <div>
                  <h3 style={{ fontSize: '16px', fontWeight: '600', marginBottom: '2px' }}>{child.name}</h3>
                  <p style={{ fontSize: '13px', color: 'var(--color-text-muted)' }}>
                    {child.gender === 'male' ? 'Laki-laki' : 'Perempuan'} · {child.birth_date ? new Date(child.birth_date).toLocaleDateString('id-ID', { year: 'numeric', month: 'long' }) : '-'}
                  </p>
                </div>
              </div>
              <div style={{ display: 'flex', gap: '8px', flexWrap: 'wrap' }}>
                <span className="tc-badge tc-badge-success">Aktif</span>
                {child.child_packages?.[0]?.package && (
                  <span className="tc-badge tc-badge-info">{child.child_packages[0].package.name}</span>
                )}
              </div>
              <div style={{ marginTop: '14px', display: 'flex', alignItems: 'center', gap: '4px', fontSize: '12px', fontWeight: '500', color: 'var(--color-primary)' }}>
                Lihat Detail
                <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><polyline points="9 18 15 12 9 6"/></svg>
              </div>
            </div>
          ))}
        </div>
      ) : (
        <div className="tc-card">
          <div className="tc-empty-state">
            <div className="tc-empty-state-icon"><svg width="28" height="28" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8"><circle cx="12" cy="8" r="4"/><path d="M5 20c0-4 3.5-7 7-7s7 3 7 7"/></svg></div>
            <p className="tc-empty-state-title">Belum ada data anak</p>
            <p className="tc-empty-state-desc">Data akan muncul ketika anak sudah terdaftar.</p>
          </div>
        </div>
      )}
    </div>
  );
}
