import { useState, useEffect } from 'react';
import { packagesAPI } from '../services/api';
import { PageHeader, Modal, EmptyState } from '../components/PageHeader';

export default function Packages() {
  const [packages, setPackages] = useState([]);
  const [loading, setLoading] = useState(true);
  const [showModal, setShowModal] = useState(false);
  const [formData, setFormData] = useState({ name: '', description: '', price: '', duration_days: '', facilities: '', quota: '', status: 'active' });
  const [error, setError] = useState('');

  async function loadPackages() {
    try {
      const res = await packagesAPI.list();
      setPackages(res.data.data.data || []);
    } catch (error) {
      setError(error.response?.data?.message || 'Gagal memuat data paket.');
    } finally {
      setLoading(false);
    }
  }

  useEffect(() => { loadPackages(); }, []);

  const handleSubmit = async (e) => {
    e.preventDefault();
    try {
      await packagesAPI.create({ ...formData, price: parseFloat(formData.price), duration_days: parseInt(formData.duration_days), quota: formData.quota ? parseInt(formData.quota) : null });
      setShowModal(false);
      setFormData({ name: '', description: '', price: '', duration_days: '', facilities: '', quota: '', status: 'active' });
      loadPackages();
    } catch (error) {
      alert(error.response?.data?.message || 'Gagal menambahkan paket.');
    }
  };

  const handleDelete = async (id) => {
    if (confirm('Yakin ingin menghapus paket ini?')) {
      try {
        await packagesAPI.delete(id);
        loadPackages();
      } catch (error) {
        alert(error.response?.data?.message || 'Gagal menghapus paket.');
      }
    }
  };

  const formatPrice = (price) => new Intl.NumberFormat('id-ID', { style: 'currency', currency: 'IDR' }).format(price);

  if (loading) {
    return <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'center', height: '300px' }}><div className="tc-spinner"></div></div>;
  }

  return (
    <div>
      <PageHeader
        title="Manajemen Paket"
        subtitle="Kelola paket daycare yang tersedia"
        action={<button onClick={() => setShowModal(true)} className="tc-btn tc-btn-primary">+ Tambah Paket</button>}
      />

      {error && (
        <div className="tc-error-state" style={{ marginBottom: '16px' }}>
          <p className="tc-empty-state-title">{error}</p>
          <button onClick={() => { setError(''); loadPackages(); }} className="tc-btn tc-btn-secondary tc-btn-sm" style={{ marginTop: '12px' }}>Coba Lagi</button>
        </div>
      )}

      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(300px, 1fr))', gap: '16px' }}>
        {packages.map((pkg) => (
          <div key={pkg.id} className="tc-card" style={{ padding: '24px' }}>
            <div style={{ display: 'flex', alignItems: 'flex-start', justifyContent: 'space-between', marginBottom: '16px' }}>
              <div>
                <h3 style={{ fontSize: '16px', fontWeight: '700', marginBottom: '2px' }}>{pkg.name}</h3>
                <p style={{ fontSize: '12px', color: 'var(--color-text-muted)' }}>{pkg.duration_days} hari</p>
              </div>
              <span className={`tc-badge ${pkg.status === 'active' ? 'tc-badge-success' : 'tc-badge-info'}`}>
                {pkg.status === 'active' ? 'Aktif' : 'Nonaktif'}
              </span>
            </div>
            <p style={{ fontSize: '22px', fontWeight: '700', color: 'var(--color-primary)', marginBottom: '8px' }}>{formatPrice(pkg.price)}</p>
            <p style={{ fontSize: '13px', color: 'var(--color-text-secondary)', marginBottom: '12px' }}>{pkg.description || '-'}</p>
            {pkg.facilities && (
              <p style={{ fontSize: '12px', color: 'var(--color-text-muted)', marginBottom: '4px' }}>
                <strong style={{ color: 'var(--color-text-secondary)' }}>Fasilitas:</strong> {pkg.facilities}
              </p>
            )}
            {pkg.quota && (
              <p style={{ fontSize: '12px', color: 'var(--color-text-muted)' }}>Kuota: {pkg.quota} anak</p>
            )}
            <div style={{ marginTop: '16px', paddingTop: '12px', borderTop: '1px solid var(--color-border-light)' }}>
              <button onClick={() => handleDelete(pkg.id)} className="tc-btn tc-btn-ghost" style={{ color: 'var(--color-error)', padding: '6px 12px', fontSize: '13px' }}>
                Hapus
              </button>
            </div>
          </div>
        ))}
      </div>

      {packages.length === 0 && <EmptyState icon="📦" title="Belum ada paket" description="Klik 'Tambah Paket' untuk menambahkan." />}

      <Modal open={showModal} onClose={() => setShowModal(false)} title="Tambah Paket Baru">
        <form onSubmit={handleSubmit}>
          <div style={{ display: 'flex', flexDirection: 'column', gap: '14px' }}>
            <div>
              <label className="tc-label">Nama Paket *</label>
              <input type="text" value={formData.name} onChange={(e) => setFormData({ ...formData, name: e.target.value })} className="tc-input" required />
            </div>
            <div>
              <label className="tc-label">Deskripsi</label>
              <textarea value={formData.description} onChange={(e) => setFormData({ ...formData, description: e.target.value })} className="tc-input" rows="2" />
            </div>
            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '14px' }}>
              <div>
                <label className="tc-label">Harga (Rp) *</label>
                <input type="number" value={formData.price} onChange={(e) => setFormData({ ...formData, price: e.target.value })} className="tc-input" required min="0" />
              </div>
              <div>
                <label className="tc-label">Durasi (hari) *</label>
                <input type="number" value={formData.duration_days} onChange={(e) => setFormData({ ...formData, duration_days: e.target.value })} className="tc-input" required min="1" />
              </div>
            </div>
            <div>
              <label className="tc-label">Fasilitas</label>
              <textarea value={formData.facilities} onChange={(e) => setFormData({ ...formData, facilities: e.target.value })} className="tc-input" rows="2" placeholder="AC, CCTV, Ruang Bermain, dll" />
            </div>
            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '14px' }}>
              <div>
                <label className="tc-label">Kuota (opsional)</label>
                <input type="number" value={formData.quota} onChange={(e) => setFormData({ ...formData, quota: e.target.value })} className="tc-input" min="0" placeholder="Kosongkan = unlimited" />
              </div>
              <div>
                <label className="tc-label">Status</label>
                <select value={formData.status} onChange={(e) => setFormData({ ...formData, status: e.target.value })} className="tc-select">
                  <option value="active">Aktif</option>
                  <option value="inactive">Nonaktif</option>
                </select>
              </div>
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
