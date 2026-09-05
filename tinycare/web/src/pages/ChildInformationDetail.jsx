import { useState, useEffect } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import api from '../services/api';
import { PageHeader, Modal, EmptyState } from '../components/PageHeader';
import ChildPhoto from '../components/ChildPhoto';

export default function ChildInformationDetail() {
  const { childId } = useParams();
  const navigate = useNavigate();
  const [child, setChild] = useState(null);
  const [information, setInformation] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [showModal, setShowModal] = useState(false);
  const [submitting, setSubmitting] = useState(false);
  const [modalError, setModalError] = useState('');
  const [formData, setFormData] = useState({
    title: '', content: '', priority: 'normal',
  });

  const priorityConfig = {
    normal: { label: 'Normal', badge: 'tc-badge-info' },
    important: { label: 'Penting', badge: 'tc-badge-warning' },
    urgent: { label: 'Urgent', badge: 'tc-badge-error' },
  };

  async function loadData() {
    setLoading(true);
    setError('');
    try {
      const [childRes, infoRes] = await Promise.all([
        api.get(`/admin/children/${childId}`),
        api.get(`/admin/child-information`, { params: { child_id: childId } }),
      ]);
      setChild(childRes.data.data);
      setInformation(infoRes.data.data?.data || infoRes.data.data || []);
    } catch (err) {
      setError(err.response?.data?.message || 'Gagal memuat data.');
    } finally {
      setLoading(false);
    }
  }

  useEffect(() => {
    loadData();
  }, [childId]);

  const handleSubmit = async (e) => {
    e.preventDefault();
    setSubmitting(true);
    setModalError('');
    try {
      await api.post('/admin/child-information', {
        child_id: parseInt(childId), ...formData,
      });
      setShowModal(false);
      setFormData({ title: '', content: '', priority: 'normal' });
      loadData();
    } catch (err) {
      if (err.response?.status === 422) {
        const errors = err.response.data.errors;
        if (errors) {
          const first = Object.values(errors)[0];
          setModalError(Array.isArray(first) ? first[0] : first);
        } else {
          setModalError(err.response.data.message || 'Data tidak valid.');
        }
      } else {
        setModalError(err.response?.data?.message || 'Gagal menambahkan informasi.');
      }
    } finally {
      setSubmitting(false);
    }
  };

  if (loading) {
    return <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'center', height: '300px' }}><div className="tc-spinner"></div></div>;
  }

  return (
    <div>
      <button
        onClick={() => navigate('/child-information')}
        style={{ background: 'none', border: 'none', color: 'var(--color-primary)', cursor: 'pointer', fontSize: '13px', marginBottom: '16px', display: 'flex', alignItems: 'center', gap: '4px', fontWeight: 500 }}
      >
        <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><polyline points="15 18 9 12 15 6"/></svg>
        Kembali ke Daftar Anak
      </button>

      {error ? (
        <div className="tc-error-state" style={{ padding: '24px' }}>
          <p className="tc-empty-state-title">{error}</p>
          <button onClick={loadData} className="tc-btn tc-btn-secondary tc-btn-sm" style={{ marginTop: '12px' }}>Coba Lagi</button>
        </div>
      ) : !child ? (
        <EmptyState icon="👶" title="Anak tidak ditemukan" />
      ) : (
        <>
          <PageHeader
            title="Informasi Anak"
            subtitle={`Kelola informasi untuk ${child.name}`}
            action={
              <button onClick={() => { setModalError(''); setShowModal(true); }} className="tc-btn tc-btn-primary">
                <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round"><line x1="12" y1="5" x2="12" y2="19"/><line x1="5" y1="12" x2="19" y2="12"/></svg>
                Tambah Informasi
              </button>
            }
          />

          <div style={{ display: 'flex', alignItems: 'center', gap: '16px', marginBottom: '24px', flexWrap: 'wrap' }}>
            <ChildPhoto child={child} width={120} alt={child.name} />
            <div>
              <h1 style={{ fontSize: '22px', fontWeight: '700', letterSpacing: '-0.02em', marginBottom: '4px' }}>{child.name}</h1>
              <span className={`tc-badge ${child.status === 'active' ? 'tc-badge-success' : 'tc-badge-info'}`}>
                {child.status === 'active' ? 'Status: Aktif' : 'Status: Nonaktif'}
              </span>
            </div>
          </div>

          {information.length > 0 ? (
            <div className="tc-card" style={{ padding: '20px' }}>
              <h2 style={{ fontSize: '14px', fontWeight: '700', marginBottom: '14px' }}>Daftar Informasi</h2>
              <div style={{ display: 'flex', flexDirection: 'column', gap: '10px' }}>
                {information.map((item) => {
                  const priority = priorityConfig[item.priority] || priorityConfig.normal;
                  return (
                    <div key={item.id} style={{
                      display: 'flex', alignItems: 'flex-start', gap: '12px',
                      padding: '14px', borderRadius: 'var(--radius-md)', background: 'var(--color-bg-alt)',
                    }}>
                      <div style={{ flex: 1, minWidth: 0 }}>
                        <div style={{ display: 'flex', alignItems: 'center', gap: '10px', marginBottom: '4px', flexWrap: 'wrap' }}>
                          <p style={{ fontSize: '14px', fontWeight: '600' }}>{item.title}</p>
                          <span className={`tc-badge ${priority.badge}`}>{priority.label}</span>
                        </div>
                        <p style={{ fontSize: '13px', color: 'var(--color-text-secondary)', whiteSpace: 'pre-wrap' }}>{item.content}</p>
                        {item.created_at && (
                          <p style={{ fontSize: '11px', color: 'var(--color-text-muted)', marginTop: '8px' }}>
                            {new Date(item.created_at).toLocaleDateString('id-ID', { year: 'numeric', month: 'long', day: 'numeric' })}
                          </p>
                        )}
                      </div>
                    </div>
                  );
                })}
              </div>
            </div>
          ) : (
            <EmptyState
              icon="📝"
              title="Belum ada informasi"
              description="Klik 'Tambah Informasi' untuk menambahkan informasi untuk anak ini."
              action={
                <button onClick={() => { setModalError(''); setShowModal(true); }} className="tc-btn tc-btn-primary">Tambah Informasi</button>
              }
            />
          )}
        </>
      )}

      <Modal open={showModal} onClose={() => setShowModal(false)} title="Tambah Informasi Anak" maxWidth="560px">
        {modalError && <div style={{ padding: '10px 14px', background: 'var(--color-error-bg)', border: '1px solid var(--color-error)', borderRadius: 'var(--radius-md)', color: 'var(--color-error)', fontSize: '13px', marginBottom: '14px' }}>{modalError}</div>}
        {child && (
          <p style={{ fontSize: '13px', color: 'var(--color-text-secondary)', marginBottom: '14px' }}>
            Untuk: <strong>{child.name}</strong>
          </p>
        )}
        <form onSubmit={handleSubmit}>
          <div style={{ display: 'flex', flexDirection: 'column', gap: '14px' }}>
            <div>
              <label className="tc-label">Judul *</label>
              <input type="text" value={formData.title} onChange={(e) => setFormData({ ...formData, title: e.target.value })} className="tc-input" placeholder="Contoh: Alergi makanan" required />
            </div>
            <div>
              <label className="tc-label">Konten *</label>
              <textarea value={formData.content} onChange={(e) => setFormData({ ...formData, content: e.target.value })} className="tc-input" rows="3" placeholder="Detail informasi" required />
            </div>
            <div>
              <label className="tc-label">Prioritas *</label>
              <select value={formData.priority} onChange={(e) => setFormData({ ...formData, priority: e.target.value })} className="tc-select">
                <option value="normal">Normal</option>
                <option value="important">Penting</option>
                <option value="urgent">Urgent</option>
              </select>
            </div>
          </div>
          <div style={{ display: 'flex', gap: '10px', marginTop: '20px' }}>
            <button type="button" onClick={() => setShowModal(false)} className="tc-btn tc-btn-secondary" style={{ flex: 1 }}>Batal</button>
            <button type="submit" disabled={submitting} className="tc-btn tc-btn-primary" style={{ flex: 1 }}>{submitting ? 'Menyimpan...' : 'Simpan'}</button>
          </div>
        </form>
      </Modal>
    </div>
  );
}
