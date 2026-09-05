import { useState, useEffect } from 'react';
import { parentAPI } from '../../services/api';
import { PageHeader, EmptyState } from '../../components/PageHeader';
import ChildPhoto from '../../components/ChildPhoto';

const priorityConfig = {
  normal: { label: 'Normal', color: 'var(--color-text-muted)', bg: 'var(--color-bg-alt)' },
  important: { label: 'Penting', color: 'var(--color-warning)', bg: 'var(--color-warning-bg)' },
  urgent: { label: 'Mendesak', color: 'var(--color-error)', bg: 'var(--color-error-bg)' },
};

export default function ParentInformation() {
  const [children, setChildren] = useState([]);
  const [loading, setLoading] = useState(true);
  const [selectedChild, setSelectedChild] = useState(null);
  const [informations, setInformations] = useState([]);
  const [loadingInfo, setLoadingInfo] = useState(false);
  const [error, setError] = useState('');

  async function loadChildren() {
    try {
      const res = await parentAPI.children();
      const list = res.data.data?.data || res.data.data || [];
      setChildren(Array.isArray(list) ? list : []);
    } catch (e) {
      setError(e.response?.data?.message || 'Gagal memuat data anak.');
    }
  }

  async function loadInformation(childId) {
    setLoadingInfo(true);
    setError('');
    try {
      const res = await parentAPI.childInformation(childId);
      setInformations(res.data.data?.data || res.data.data || []);
    } catch (e) {
      setError(e.response?.data?.message || 'Gagal memuat informasi.');
      setInformations([]);
    } finally {
      setLoadingInfo(false);
    }
  }

  useEffect(() => {
    loadChildren().finally(() => setLoading(false));
  }, []);

  useEffect(() => {
    if (selectedChild) {
      loadInformation(selectedChild.id);
    } else {
      setInformations([]);
    }
  }, [selectedChild]);

  function formatDate(dateStr) {
    if (!dateStr) return '-';
    return new Date(dateStr).toLocaleDateString('id-ID', { day: 'numeric', month: 'long', year: 'numeric' });
  }

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
        title="Informasi Anak"
        subtitle={selectedChild ? `Informasi untuk ${selectedChild.name}` : 'Pilih anak untuk melihat informasi'}
        action={
          selectedChild && (
            <button onClick={() => { setSelectedChild(null); setError(''); }} className="tc-btn tc-btn-secondary">
              ← Kembali
            </button>
          )
        }
      />

      {error && (
        <div style={{ padding: '10px 14px', background: 'var(--color-error-bg)', border: '1px solid var(--color-error)', borderRadius: 'var(--radius-md)', color: 'var(--color-error)', fontSize: '13px', marginBottom: '16px' }}>
          {error}
        </div>
      )}

      {!selectedChild ? (
        children.length === 0 ? (
          <EmptyState icon="👶" title="Belum ada anak" description="Anda belum memiliki data anak yang terdaftar." />
        ) : (
          <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(200px, 1fr))', gap: '12px' }}>
            {children.map((child) => (
              <div
                key={child.id}
                onClick={() => setSelectedChild(child)}
                className="tc-card"
                style={{ padding: '16px', cursor: 'pointer', textAlign: 'center', transition: 'box-shadow 0.2s, border-color 0.2s', border: '2px solid transparent' }}
                onMouseEnter={(e) => { e.currentTarget.style.borderColor = 'var(--color-primary)'; e.currentTarget.style.boxShadow = 'var(--shadow-md)'; }}
                onMouseLeave={(e) => { e.currentTarget.style.borderColor = 'transparent'; e.currentTarget.style.boxShadow = 'none'; }}
              >
                <div style={{ display: 'flex', justifyContent: 'center', marginBottom: '12px' }}>
                  <ChildPhoto child={child} width={120} alt={child.name} />
                </div>
                <p style={{ fontSize: '14px', fontWeight: '600', marginBottom: '4px' }}>{child.name}</p>
                <span className="tc-badge" style={{ background: 'var(--color-success-bg)', color: 'var(--color-success)', fontSize: '11px' }}>
                  {child.status === 'active' ? 'Aktif' : 'Nonaktif'}
                </span>
              </div>
            ))}
          </div>
        )
      ) : loadingInfo ? (
        <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'center', height: '200px' }}>
          <div className="tc-spinner"></div>
        </div>
      ) : informations.length === 0 ? (
        <EmptyState icon="📋" title="Belum ada informasi" description={`Belum ada informasi untuk ${selectedChild.name}.`} />
      ) : (
        <div style={{ display: 'flex', flexDirection: 'column', gap: '12px' }}>
          {informations.map((info) => {
            const pc = priorityConfig[info.priority] || priorityConfig.normal;
            return (
              <div key={info.id} className="tc-card" style={{ padding: '16px' }}>
                <div style={{ display: 'flex', alignItems: 'flex-start', justifyContent: 'space-between', gap: '12px', marginBottom: '8px' }}>
                  <h3 style={{ fontSize: '14px', fontWeight: '600' }}>{info.title}</h3>
                  <span className="tc-badge" style={{ background: pc.bg, color: pc.color, whiteSpace: 'nowrap', fontSize: '11px' }}>
                    {pc.label}
                  </span>
                </div>
                <p style={{ fontSize: '13px', color: 'var(--color-text-secondary)', lineHeight: '1.5', marginBottom: '10px' }}>
                  {info.content}
                </p>
                <div style={{ display: 'flex', alignItems: 'center', gap: '12px', fontSize: '11px', color: 'var(--color-text-muted)' }}>
                  <span>{formatDate(info.created_at)}</span>
                  {info.creator && <span>oleh {info.creator.name}</span>}
                </div>
              </div>
            );
          })}
        </div>
      )}
    </div>
  );
}
