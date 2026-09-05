import { useState, useEffect, useRef } from 'react';
import { Link } from 'react-router-dom';
import { childrenAPI, parentsAPI, packagesAPI } from '../services/api';
import { PageHeader, Modal, EmptyState } from '../components/PageHeader';
import ChildPhoto from '../components/ChildPhoto';

const PHOTO_ACCEPT = 'image/jpeg,image/png,image/gif';
const PHOTO_MAX_MB = 5;

function validatePhotoFile(file) {
  if (!file) return null;
  if (file.size > PHOTO_MAX_MB * 1024 * 1024) {
    return `Ukuran foto maksimal ${PHOTO_MAX_MB}MB.`;
  }
  if (!['image/jpeg', 'image/png', 'image/gif'].includes(file.type)) {
    return 'Format foto harus JPG, PNG, atau GIF.';
  }
  return null;
}

export default function Children() {
  const [children, setChildren] = useState([]);
  const [parents, setParents] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [showModal, setShowModal] = useState(false);
  const [packages, setPackages] = useState([]);
  const [formData, setFormData] = useState({
    name: '', birth_date: '', gender: 'male', address: '', health_info: '',
    emergency_contact_name: '', emergency_contact_phone: '', parent_ids: [],
    status: 'active',
  });
  const [selectedPackage, setSelectedPackage] = useState('');
  const [packageStartDate, setPackageStartDate] = useState('');
  const [photoFile, setPhotoFile] = useState(null);
  const [photoPreview, setPhotoPreview] = useState(null);
  const [photoError, setPhotoError] = useState('');
  const fileInputRef = useRef(null);

  async function loadChildren() {
    try {
      const res = await childrenAPI.list();
      setChildren(res.data.data.data || []);
      setError('');
    } catch (error) {
      setError(error.response?.data?.message || 'Gagal memuat data anak.');
    } finally {
      setLoading(false);
    }
  }

  async function loadParents() {
    try {
      const res = await parentsAPI.list({ per_page: 100 });
      setParents(res.data.data.data || []);
    } catch (error) {
      setError(error.response?.data?.message || 'Gagal memuat data orang tua.');
    }
  }

  async function loadPackages() {
    try {
      const res = await packagesAPI.list({ per_page: 100, status: 'active' });
      setPackages(res.data.data.data || []);
    } catch (error) {
      setError(error.response?.data?.message || 'Gagal memuat data paket.');
    }
  }

  useEffect(() => {
    loadChildren();
    loadParents();
    loadPackages();
  }, []);

  const handlePhotoChange = (e) => {
    const file = e.target.files?.[0];
    setPhotoError('');
    if (!file) {
      setPhotoFile(null);
      setPhotoPreview(null);
      return;
    }
    const err = validatePhotoFile(file);
    if (err) {
      setPhotoError(err);
      setPhotoFile(null);
      setPhotoPreview(null);
      if (fileInputRef.current) fileInputRef.current.value = '';
      return;
    }
    setPhotoFile(file);
    setPhotoPreview(URL.createObjectURL(file));
  };

  const removePhoto = () => {
    setPhotoFile(null);
    setPhotoPreview(null);
    setPhotoError('');
    if (fileInputRef.current) fileInputRef.current.value = '';
  };

  const resetForm = () => {
    setFormData({ name: '', birth_date: '', gender: 'male', address: '', health_info: '', emergency_contact_name: '', emergency_contact_phone: '', parent_ids: [], status: 'active' });
    setSelectedPackage('');
    setPackageStartDate('');
    removePhoto();
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    try {
      const fd = new FormData();
      fd.append('name', formData.name);
      fd.append('birth_date', formData.birth_date);
      fd.append('gender', formData.gender);
      fd.append('status', formData.status);
      if (formData.address) fd.append('address', formData.address);
      if (formData.health_info) fd.append('health_info', formData.health_info);
      if (formData.emergency_contact_name) fd.append('emergency_contact_name', formData.emergency_contact_name);
      if (formData.emergency_contact_phone) fd.append('emergency_contact_phone', formData.emergency_contact_phone);
      if (formData.emergency_contact_relationship) fd.append('emergency_contact_relationship', formData.emergency_contact_relationship);
      formData.parent_ids.forEach((id) => fd.append('parent_ids[]', id));
      if (photoFile) fd.append('photo', photoFile);

      const res = await childrenAPI.create(fd);
      const newChildId = res.data.data?.id;

      if (selectedPackage && newChildId) {
        try {
          await packagesAPI.assignToChild(newChildId, {
            package_id: parseInt(selectedPackage),
            start_date: packageStartDate || new Date().toISOString().split('T')[0],
          });
        } catch (pkgErr) {
          alert('Anak berhasil ditambahkan, namun gagal menetapkan paket: ' + (pkgErr.response?.data?.message || 'Error'));
        }
      }

      setShowModal(false);
      resetForm();
      loadChildren();
    } catch (error) {
      if (error.response?.status === 422) {
        const errors = error.response.data.errors;
        if (errors) {
          const first = Object.values(errors)[0];
          alert(Array.isArray(first) ? first[0] : first);
        } else {
          alert(error.response.data.message || 'Data tidak valid.');
        }
      } else {
        alert(error.response?.data?.message || 'Gagal menambahkan anak.');
      }
    }
  };

  const handleDelete = async (id) => {
    if (confirm('Yakin ingin menghapus anak ini?')) {
      try {
        await childrenAPI.delete(id);
        loadChildren();
      } catch (e) {
        alert(e.response?.data?.message || 'Gagal menghapus anak.');
      }
    }
  };

  const handleToggleStatus = async (child) => {
    const targetStatus = child.status === 'active' ? 'inactive' : 'active';
    if (targetStatus === 'inactive') {
      if (!confirm(`Nonaktifkan ${child.name}? Orang tua terkait juga akan dinonaktifkan jika ini anak satu-satunya.`)) return;
    } else {
      if (!confirm(`Aktifkan ${child.name} kembali?`)) return;
    }
    try {
      await childrenAPI.update(child.id, { status: targetStatus });
      loadChildren();
    } catch (e) {
      alert(e.response?.data?.message || 'Gagal mengubah status anak.');
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
        {error && (
          <div className="tc-error-state" style={{ margin: '16px' }}>
            <p className="tc-empty-state-title">{error}</p>
            <button onClick={loadChildren} className="tc-btn tc-btn-secondary tc-btn-sm" style={{ marginTop: '12px' }}>Coba Lagi</button>
          </div>
        )}
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
                    <ChildPhoto child={child} width={40} />
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
                  <div style={{ display: 'flex', gap: '4px' }}>
                    <Link to={`/children/${child.id}`} className="tc-btn tc-btn-ghost" style={{ color: 'var(--color-info)', padding: '4px 8px', fontSize: '13px' }}>Detail</Link>
                    <button
                      onClick={() => handleToggleStatus(child)}
                      className="tc-btn tc-btn-ghost"
                      style={{ padding: '4px 8px', fontSize: '13px', color: child.status === 'active' ? 'var(--color-warning)' : 'var(--color-success)' }}
                    >
                      {child.status === 'active' ? 'Nonaktifkan' : 'Aktifkan'}
                    </button>
                    <button onClick={() => handleDelete(child.id)} className="tc-btn tc-btn-ghost" style={{ color: 'var(--color-error)', padding: '4px 8px', fontSize: '13px' }}>
                      Hapus
                    </button>
                  </div>
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
            {/* Photo Upload */}
            <div style={{ gridColumn: 'span 2' }}>
              <label className="tc-label">Foto Profil Anak</label>
              <div style={{ display: 'flex', alignItems: 'center', gap: '14px' }}>
                <div style={{
                  width: '60px', height: '90px', borderRadius: 'var(--radius-lg)',
                  overflow: 'hidden', flexShrink: 0, border: '2px dashed var(--color-border)',
                }}>
                  {photoPreview ? (
                    <img src={photoPreview} alt="Preview" style={{ width: '100%', height: '100%', objectFit: 'cover', display: 'block' }} />
                  ) : (
                    <img src="/placeholder-avatar.svg" alt="Placeholder" style={{ width: '100%', height: '100%', objectFit: 'cover', display: 'block' }} />
                  )}
                </div>
                <div style={{ flex: 1, display: 'flex', flexDirection: 'column', gap: '6px' }}>
                  <input
                    ref={fileInputRef}
                    type="file"
                    accept={PHOTO_ACCEPT}
                    onChange={handlePhotoChange}
                    className="tc-input"
                    style={{ fontSize: '13px', padding: '8px 10px' }}
                  />
                  {photoPreview && (
                    <button type="button" onClick={removePhoto} className="tc-btn tc-btn-ghost tc-btn-sm" style={{ fontSize: '12px', color: 'var(--color-error)', alignSelf: 'flex-start' }}>
                      Hapus Foto
                    </button>
                  )}
                  {photoError && <p style={{ fontSize: '12px', color: 'var(--color-error)' }}>{photoError}</p>}
                  <p style={{ fontSize: '11px', color: 'var(--color-text-muted)' }}>Opsional. Format: JPG, PNG, GIF. Maks {PHOTO_MAX_MB}MB.</p>
                </div>
              </div>
            </div>

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
            <div>
              <label className="tc-label">Status</label>
              <select value={formData.status} onChange={(e) => setFormData({ ...formData, status: e.target.value })} className="tc-select">
                <option value="active">Aktif</option>
                <option value="inactive">Nonaktif</option>
              </select>
            </div>
            <div>
              <label className="tc-label">Paket</label>
              <select value={selectedPackage} onChange={(e) => setSelectedPackage(e.target.value)} className="tc-select">
                <option value="">-- Tidak ada paket --</option>
                {packages.map((pkg) => (
                  <option key={pkg.id} value={pkg.id}>{pkg.name} — Rp {new Intl.NumberFormat('id-ID').format(pkg.price)}</option>
                ))}
              </select>
            </div>
            {selectedPackage && (
              <div style={{ gridColumn: 'span 2' }}>
                <label className="tc-label">Tanggal Mulai Paket</label>
                <input type="date" value={packageStartDate} onChange={(e) => setPackageStartDate(e.target.value)} className="tc-input" required={!!selectedPackage} />
              </div>
            )}
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
