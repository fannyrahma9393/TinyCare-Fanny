import { useState, useEffect } from 'react';
import { childrenAPI, parentsAPI } from '../services/api';
import { PageHeader, Modal, EmptyState } from '../components/PageHeader';

export default function Children() {
  const [children, setChildren] = useState([]);
  const [parents, setParents] = useState([]);
  const [loading, setLoading] = useState(true);
  const [showModal, setShowModal] = useState(false);
  const [formData, setFormData] = useState({
    name: '', birth_date: '', gender: 'male', address: '', health_info: '',
    emergency_contact_name: '', emergency_contact_phone: '', parent_ids: [],
  });

  async function loadChildren() {
    try {
      const res = await childrenAPI.list();
      setChildren(res.data.data.data || []);
    } catch (error) {
      console.error('Error loading children:', error);
    } finally {
      setLoading(false);
    }
  }

  async function loadParents() {
    try {
      const res = await parentsAPI.list({ per_page: 100 });
      setParents(res.data.data.data || []);
    } catch (error) {
      console.error('Error loading parents:', error);
    }
  }

  useEffect(() => {
    loadChildren();
    loadParents();
  }, []);

  const handleSubmit = async (e) => {
    e.preventDefault();
    try {
      await childrenAPI.create(formData);
      setShowModal(false);
      setFormData({ name: '', birth_date: '', gender: 'male', address: '', health_info: '', emergency_contact_name: '', emergency_contact_phone: '', parent_ids: [] });
      loadChildren();
    } catch (error) {
      alert(error.response?.data?.message || 'Gagal menambahkan anak.');
    }
  };

  const handleDelete = async (id) => {
    if (confirm('Yakin ingin menghapus anak ini?')) {
      try {
        await childrenAPI.delete(id);
        loadChildren();
      } catch {
        alert('Gagal menghapus anak.');
      }
    }
  };

  if (loading) {
    return <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'center', height: '300px' }}><div className="tc-spinner"></div></div>;
  }

  return (
    <div>
      <PageHeader
        title="Manajemen Anak"
        subtitle="Kelola data anak yang terdaftar di daycare"
        action={
          <button onClick={() => setShowModal(true)} className="tc-btn tc-btn-primary">
            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round"><line x1="12" y1="5" x2="12" y2="19"/><line x1="5" y1="12" x2="19" y2="12"/></svg>
            Tambah Anak
          </button>
        }
      />

      <div className="tc-card" style={{ overflow: 'hidden' }}>
        <table className="tc-table">
          <thead>
            <tr>
              <th>Anak</th>
              <th>Tanggal Lahir</th>
              <th>Gender</th>
              <th>Status</th>
              <th>Aksi</th>
            </tr>
          </thead>
          <tbody>
            {children.map((child) => (
              <tr key={child.id}>
                <td>
                  <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
                    <div style={{
                      width: '34px', height: '34px', borderRadius: '8px',
                      background: 'var(--color-primary-lighter)',
                      display: 'flex', alignItems: 'center', justifyContent: 'center',
                    }}>
                      <span style={{ color: 'var(--color-primary)', fontWeight: '700', fontSize: '13px' }}>{child.name?.charAt(0)}</span>
                    </div>
                    <span style={{ fontWeight: '600' }}>{child.name}</span>
                  </div>
                </td>
                <td style={{ color: 'var(--color-text-secondary)' }}>
                  {child.birth_date ? new Date(child.birth_date).toLocaleDateString('id-ID') : '-'}
                </td>
                <td style={{ color: 'var(--color-text-secondary)' }}>
                  {child.gender === 'male' ? 'Laki-laki' : 'Perempuan'}
                </td>
                <td>
                  <span className={`tc-badge ${child.status === 'active' ? 'tc-badge-success' : 'tc-badge-info'}`}>
                    {child.status === 'active' ? 'Aktif' : 'Nonaktif'}
                  </span>
                </td>
                <td>
                  <button onClick={() => handleDelete(child.id)} className="tc-btn tc-btn-ghost" style={{ color: 'var(--color-error)', padding: '4px 8px', fontSize: '13px' }}>
                    Hapus
                  </button>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
        {children.length === 0 && <EmptyState icon="👶" title="Belum ada data anak" description="Klik 'Tambah Anak' untuk menambahkan data." />}
      </div>

      <Modal open={showModal} onClose={() => setShowModal(false)} title="Tambah Anak Baru" maxWidth="560px">
        <form onSubmit={handleSubmit}>
          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '14px' }}>
            <div style={{ gridColumn: 'span 2' }}>
              <label className="tc-label">Nama Anak *</label>
              <input type="text" value={formData.name} onChange={(e) => setFormData({ ...formData, name: e.target.value })} className="tc-input" required />
            </div>
            <div>
              <label className="tc-label">Tanggal Lahir *</label>
              <input type="date" value={formData.birth_date} onChange={(e) => setFormData({ ...formData, birth_date: e.target.value })} className="tc-input" required />
            </div>
            <div>
              <label className="tc-label">Gender *</label>
              <select value={formData.gender} onChange={(e) => setFormData({ ...formData, gender: e.target.value })} className="tc-select">
                <option value="male">Laki-laki</option>
                <option value="female">Perempuan</option>
              </select>
            </div>
            <div style={{ gridColumn: 'span 2' }}>
              <label className="tc-label">Orang Tua *</label>
              <select multiple value={formData.parent_ids} onChange={(e) => setFormData({ ...formData, parent_ids: Array.from(e.target.selectedOptions, (o) => parseInt(o.value)) })} className="tc-select" required>
                {parents.map((parent) => (
                  <option key={parent.id} value={parent.id}>{parent.user?.name} ({parent.user?.email})</option>
                ))}
              </select>
            </div>
            <div style={{ gridColumn: 'span 2' }}>
              <label className="tc-label">Alamat</label>
              <textarea value={formData.address} onChange={(e) => setFormData({ ...formData, address: e.target.value })} className="tc-input" rows="2" />
            </div>
          </div>
          <div style={{ display: 'flex', gap: '10px', marginTop: '20px' }}>
            <button type="button" onClick={() => setShowModal(false)} className="tc-btn tc-btn-secondary" style={{ flex: 1 }}>Batal</button>
            <button type="submit" className="tc-btn tc-btn-primary" style={{ flex: 1 }}>Simpan</button>
          </div>
        </form>
      </Modal>
    </div>
  );
}
