import { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { childrenAPI } from '../services/api';
import { PageHeader, EmptyState } from '../components/PageHeader';
import ChildPhoto from '../components/ChildPhoto';

const statusConfig = {
  active: { label: 'Aktif', className: 'tc-badge-success' },
  inactive: { label: 'Nonaktif', className: 'tc-badge-info' },
};

export default function DailyStories() {
  const [childrenList, setChildrenList] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const navigate = useNavigate();

  async function loadChildren() {
    setLoading(true);
    setError('');
    try {
      const res = await childrenAPI.list({ per_page: 100 });
      setChildrenList(res.data.data.data || []);
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
    return (
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'center', height: '300px' }}>
        <div className="tc-spinner"></div>
      </div>
    );
  }

  return (
    <div>
      <PageHeader
        title="Daily Stories"
        subtitle="Pilih anak untuk melihat cerita hariannya"
      />

      {error && (
        <div className="tc-error-state" style={{ marginBottom: '16px' }}>
          <p className="tc-empty-state-title">{error}</p>
          <button onClick={loadChildren} className="tc-btn tc-btn-secondary tc-btn-sm" style={{ marginTop: '12px' }}>
            Coba Lagi
          </button>
        </div>
      )}

      {!error && childrenList.length === 0 && (
        <EmptyState
          icon="📖"
          title="Belum ada data anak"
          description="Tambahkan data anak terlebih dahulu untuk melihat Daily Stories."
        />
      )}

      {!error && childrenList.length > 0 && (
        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(220px, 1fr))', gap: '16px' }}>
          {childrenList.map((child) => {
            const st = statusConfig[child.status] || statusConfig.active;
            return (
              <div
                key={child.id}
                className="tc-card"
                onClick={() => navigate(`/daily-stories/${child.id}`)}
                style={{ padding: '16px', cursor: 'pointer', overflow: 'hidden', transition: 'box-shadow 0.15s' }}
                onMouseEnter={(e) => (e.currentTarget.style.boxShadow = '0 4px 16px rgba(0,0,0,0.08)')}
                onMouseLeave={(e) => (e.currentTarget.style.boxShadow = '')}
              >
                <div style={{ display: 'flex', justifyContent: 'center', marginBottom: '14px' }}>
                  <ChildPhoto child={child} width={120} alt={child.name} />
                </div>
                <h3 style={{ fontSize: '15px', fontWeight: '700', marginBottom: '4px' }}>{child.name}</h3>
                <span className={`tc-badge ${st.className}`}>{st.label}</span>
              </div>
            );
          })}
        </div>
      )}
    </div>
  );
}
