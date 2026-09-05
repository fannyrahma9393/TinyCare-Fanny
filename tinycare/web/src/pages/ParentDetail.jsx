import { useState, useEffect } from 'react';
import { useNavigate, useParams } from 'react-router-dom';
import { parentsAPI } from '../services/api';
import ChildPhoto from '../components/ChildPhoto';

export default function ParentDetail() {
  const { id } = useParams();
  const navigate = useNavigate();
  const [parent, setParent] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');

  async function loadParent() {
    try {
      const res = await parentsAPI.get(id);
      setParent(res.data.data || null);
      setError('');
    } catch (err) {
      if (err.response?.status === 404) {
        setError('Orang tua tidak ditemukan.');
      } else {
        setError(err.response?.data?.message || 'Gagal memuat data orang tua.');
      }
    } finally {
      setLoading(false);
    }
  }

  useEffect(() => {
    loadParent();
  }, [id]);

  if (loading) {
    return <div className="tc-loading-screen"><div className="tc-spinner tc-spinner-lg"></div><p>Memuat data orang tua...</p></div>;
  }

  if (error) {
    return (
      <div>
        <button onClick={() => navigate('/parents')} style={{ background: 'none', border: 'none', color: 'var(--color-primary)', cursor: 'pointer', fontSize: '13px', marginBottom: '16px', display: 'flex', alignItems: 'center', gap: '4px', fontWeight: 500 }}>
          <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><polyline points="15 18 9 12 15 6"/></svg>
          Kembali
        </button>
        <div className="tc-error-state">
          <div className="tc-error-state-icon"><svg width="28" height="28" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8"><circle cx="12" cy="12" r="10"/><line x1="12" y1="8" x2="12" y2="12"/><line x1="12" y1="16" x2="12.01" y2="16"/></svg></div>
          <p className="tc-empty-state-title">{error}</p>
          <button onClick={loadParent} className="tc-btn tc-btn-secondary tc-btn-sm" style={{ marginTop: '12px' }}>Coba Lagi</button>
        </div>
      </div>
    );
  }

  if (!parent) {
    return (
      <div>
        <button onClick={() => navigate('/parents')} style={{ background: 'none', border: 'none', color: 'var(--color-primary)', cursor: 'pointer', fontSize: '13px', marginBottom: '16px', display: 'flex', alignItems: 'center', gap: '4px', fontWeight: 500 }}>
          <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><polyline points="15 18 9 12 15 6"/></svg>
          Kembali
        </button>
        <div className="tc-card"><div className="tc-empty-state"><p className="tc-empty-state-title">Orang tua tidak ditemukan.</p></div></div>
      </div>
    );
  }

  const userName = parent.user?.name || '-';
  const userEmail = parent.user?.email || '-';

  const InfoRow = ({ label, value }) => (
    <div style={{ display: 'flex', justifyContent: 'space-between', padding: '8px 0', borderBottom: '1px solid var(--color-border-light)' }}>
      <span style={{ fontSize: '13px', color: 'var(--color-text-secondary)' }}>{label}</span>
      <span style={{ fontSize: '13px', fontWeight: '500', color: 'var(--color-text)', textAlign: 'right' }}>{value || '-'}</span>
    </div>
  );

  return (
    <div>
      <button onClick={() => navigate('/parents')} style={{ background: 'none', border: 'none', color: 'var(--color-primary)', cursor: 'pointer', fontSize: '13px', marginBottom: '16px', display: 'flex', alignItems: 'center', gap: '4px', fontWeight: 500 }}>
        <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><polyline points="15 18 9 12 15 6"/></svg>
        Kembali ke Daftar Orang Tua
      </button>

      {/* Header Section */}
      <div style={{ display: 'flex', alignItems: 'center', gap: '20px', marginBottom: '28px', flexWrap: 'wrap' }}>
        <div style={{
          width: '72px', height: '72px', borderRadius: 'var(--radius-xl)',
          background: 'var(--color-primary-lighter)',
          display: 'flex', alignItems: 'center', justifyContent: 'center',
          overflow: 'hidden', flexShrink: 0,
        }}>
          {parent.user?.photo || parent.user?.photo_url ? (
            <img src={parent.user.photo || parent.user.photo_url} alt={userName} style={{ width: '100%', height: '100%', objectFit: 'cover' }} />
          ) : (
            <span style={{ color: 'var(--color-primary)', fontWeight: '700', fontSize: '28px' }}>{userName?.charAt(0)}</span>
          )}
        </div>
        <div style={{ flex: 1, minWidth: 0 }}>
          <h1 style={{ fontSize: '22px', fontWeight: '700', letterSpacing: '-0.02em', marginBottom: '4px' }}>{userName}</h1>
          <p style={{ fontSize: '13px', color: 'var(--color-text-secondary)', marginBottom: '6px' }}>{userEmail}</p>
          <span className={`tc-badge ${parent.effective_status === 'active' ? 'tc-badge-success' : 'tc-badge-error'}`}>
            {parent.effective_status === 'active' ? 'Aktif' : 'Nonaktif'}
          </span>
        </div>
      </div>

      {/* Info Cards */}
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(300px, 1fr))', gap: '16px', marginBottom: '24px' }}>
        {/* Data Pribadi */}
        <div className="tc-card" style={{ padding: '20px' }}>
          <h3 style={{ fontSize: '14px', fontWeight: '700', marginBottom: '14px', color: 'var(--color-text)' }}>Data Pribadi</h3>
          <div>
            <InfoRow label="Nama Lengkap" value={userName} />
            <InfoRow label="Email" value={userEmail} />
            <InfoRow label="Telepon" value={parent.phone} />
            <InfoRow label="Alamat" value={parent.address} />
          </div>
        </div>

        {/* Kontak Darurat */}
        <div className="tc-card" style={{ padding: '20px' }}>
          <h3 style={{ fontSize: '14px', fontWeight: '700', marginBottom: '14px', color: 'var(--color-text)' }}>Kontak Darurat</h3>
          <div>
            <InfoRow label="Nama" value={parent.emergency_contact_name} />
            <InfoRow label="Telepon" value={parent.emergency_contact_phone} />
            <InfoRow label="Hubungan" value={parent.emergency_contact_relationship} />
          </div>
        </div>

        {/* Anak-anak */}
        <div className="tc-card" style={{ padding: '20px' }}>
          <h3 style={{ fontSize: '14px', fontWeight: '700', marginBottom: '14px', color: 'var(--color-text)' }}>Anak-anak</h3>
          <div>
            {parent.children && parent.children.length > 0 ? (
              parent.children.map((child) => (
                <div
                  key={child.id}
                  onClick={() => navigate(`/children/${child.id}`)}
                  style={{
                    display: 'flex', alignItems: 'center', gap: '10px', padding: '8px 0',
                    borderBottom: '1px solid var(--color-border-light)',
                    cursor: 'pointer',
                  }}
                >
                  <ChildPhoto child={child} width={40} alt={child.name} />
                  <div style={{ flex: 1, minWidth: 0 }}>
                    <p style={{ fontSize: '13px', fontWeight: '600', color: 'var(--color-text)' }}>{child.name}</p>
                  </div>
                  <span className={`tc-badge ${child.status === 'active' ? 'tc-badge-success' : 'tc-badge-info'}`}>
                    {child.status === 'active' ? 'Aktif' : 'Nonaktif'}
                  </span>
                </div>
              ))
            ) : (
              <p style={{ fontSize: '13px', color: 'var(--color-text-muted)', fontStyle: 'italic' }}>Belum ada anak terdaftar.</p>
            )}
          </div>
        </div>

        {/* Status Akun */}
        <div className="tc-card" style={{ padding: '20px' }}>
          <h3 style={{ fontSize: '14px', fontWeight: '700', marginBottom: '14px', color: 'var(--color-text)' }}>Status Akun</h3>
          <div>
            <InfoRow label="Status" value={parent.effective_status === 'active' ? 'Aktif' : 'Nonaktif'} />
            <InfoRow label="User Status" value={parent.user?.status === 'active' ? 'Aktif' : 'Nonaktif'} />
            <InfoRow label="Dibuat" value={parent.created_at ? new Date(parent.created_at).toLocaleDateString('id-ID') : '-'} />
            <InfoRow label="Diperbarui" value={parent.updated_at ? new Date(parent.updated_at).toLocaleDateString('id-ID') : '-'} />
          </div>
        </div>
      </div>
    </div>
  );
}
