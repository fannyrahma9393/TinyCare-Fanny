import { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { childrenAPI } from '../services/api';
import { PageHeader, EmptyState } from '../components/PageHeader';
import ChildPhoto from '../components/ChildPhoto';

export default function Development() {
  const navigate = useNavigate();
  const [children, setChildren] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');

  async function loadChildren() {
    try {
      const res = await childrenAPI.list({ per_page: 100 });
      setChildren(res.data.data.data || []);
      setError('');
    } catch (err) {
      setError(err.response?.data?.message || 'Gagal memuat data anak.');
    } finally {
      setLoading(false);
    }
  }

  useEffect(() => {
    loadChildren();
  }, []);

  if (loading) {
    return <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'center', height: '300px' }}><div className="tc-spinner"></div></div>;
  }

  return (
    <div>
      <PageHeader
        title="Perkembangan Anak"
        subtitle="Pilih anak untuk melihat dan mengelola data perkembangan"
      />

      {error && (
        <div className="tc-error-state" style={{ padding: '24px', marginBottom: '16px' }}>
          <p className="tc-empty-state-title">{error}</p>
          <button onClick={loadChildren} className="tc-btn tc-btn-secondary tc-btn-sm" style={{ marginTop: '12px' }}>Coba Lagi</button>
        </div>
      )}

      {!error && children.length > 0 && (
        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(220px, 1fr))', gap: '16px' }}>
          {children.map((child) => (
            <div
              key={child.id}
              className="tc-card tc-card-hover"
              style={{ padding: '16px', cursor: 'pointer', overflow: 'hidden' }}
              onClick={() => navigate(`/development/${child.id}`)}
            >
              <div style={{ display: 'flex', justifyContent: 'center', marginBottom: '14px' }}>
                <ChildPhoto child={child} width={120} alt={child.name} />
              </div>
              <h3 style={{ fontSize: '15px', fontWeight: '700', marginBottom: '4px' }}>{child.name}</h3>
              <span className={`tc-badge ${child.status === 'active' ? 'tc-badge-success' : 'tc-badge-info'}`}>
                {child.status === 'active' ? 'Status: Aktif' : 'Status: Nonaktif'}
              </span>
            </div>
          ))}
        </div>
      )}

      {!error && children.length === 0 && (
        <EmptyState
          icon="📈"
          title="Belum ada data anak"
          description="Tambahkan data anak terlebih dahulu untuk melihat perkembangan."
        />
      )}
    </div>
  );
}
