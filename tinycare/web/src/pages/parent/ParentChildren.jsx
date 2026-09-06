import { useState, useEffect, useRef } from 'react';
import { parentAPI } from '../../services/api';
import { useNavigate } from 'react-router-dom';
import ChildPhoto from '../../components/ChildPhoto';
import { PageHeader, Modal } from '../../components/PageHeader';

const PHOTO_MAX_MB = 5;
const PHOTO_MAX_DIM = 1024;
const PHOTO_QUALITY = 0.8;

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

/** Downscale + re-encode an image file on a canvas, returning a small JPEG Blob. */
async function compressPhoto(file) {
  return new Promise((resolve, reject) => {
    const img = new Image();
    img.onload = () => {
      try {
        const longest = Math.max(img.width, img.height);
        let scale = 1;
        if (longest > PHOTO_MAX_DIM) scale = PHOTO_MAX_DIM / longest;
        const w = Math.max(1, Math.round(img.width * scale));
        const h = Math.max(1, Math.round(img.height * scale));

        const canvas = document.createElement('canvas');
        canvas.width = w;
        canvas.height = h;
        const ctx = canvas.getContext('2d');
        ctx.drawImage(img, 0, 0, w, h);

        canvas.toBlob(
          (blob) => {
            if (blob) {
              resolve(blob);
            } else {
              // Canvas compress failed; fall back to the original file.
              resolve(file);
            }
          },
          'image/jpeg',
          PHOTO_QUALITY
        );
      } catch (err) {
        reject(err);
      }
    };
    img.onerror = () => reject(new Error('Gagal memuat gambar.'));
    img.src = URL.createObjectURL(file);
  });
}

export default function ParentChildren() {
  const [children, setChildren] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [showModal, setShowModal] = useState(false);
  const [submitting, setSubmitting] = useState(false);
  const [formData, setFormData] = useState({
    name: '', birth_date: '', gender: 'male', address: '',
    health_info: '', emergency_contact_name: '', emergency_contact_phone: '',
  });
  const [photoFile, setPhotoFile] = useState(null);
  const [photoPreview, setPhotoPreview] = useState(null);
  const [photoError, setPhotoError] = useState('');
  const fileInputRef = useRef(null);
  const navigate = useNavigate();

  const loadChildren = () => {
    parentAPI.children()
      .then((res) => {
        const list = res.data.data?.data || res.data.data || [];
        setChildren(Array.isArray(list) ? list : []);
        setError('');
      })
      .catch(() => setError('Gagal memuat data anak.'))
      .finally(() => setLoading(false));
  };

  useEffect(() => {
    loadChildren();
    // eslint-disable-next-line react-hooks/exhaustive-deps
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
    setFormData({ name: '', birth_date: '', gender: 'male', address: '', health_info: '', emergency_contact_name: '', emergency_contact_phone: '' });
    removePhoto();
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    setSubmitting(true);
    try {
      const fd = new FormData();
      fd.append('name', formData.name.trim());
      fd.append('birth_date', formData.birth_date);
      fd.append('gender', formData.gender);
      if (formData.address) fd.append('address', formData.address);
      if (formData.health_info) fd.append('health_info', formData.health_info);
      if (formData.emergency_contact_name) fd.append('emergency_contact_name', formData.emergency_contact_name);
      if (formData.emergency_contact_phone) fd.append('emergency_contact_phone', formData.emergency_contact_phone);

      if (photoFile) {
        try {
          const compressed = await compressPhoto(photoFile);
          fd.append('photo', compressed, 'photo.jpg');
        } catch (compressErr) {
          // Compression failed; upload the original (still validated by size).
          fd.append('photo', photoFile);
        }
      }

      await parentAPI.addChild(fd);
      setShowModal(false);
      resetForm();
      loadChildren();
    } catch (error) {
      if (error.response?.status === 422) {
        const errors = error.response.data.errors;
        const first = errors ? Object.values(errors)[0] : error.response.data.message;
        alert(Array.isArray(first) ? first[0] : (first || 'Data tidak valid.'));
      } else {
        alert(error.response?.data?.message || 'Gagal menambahkan anak.');
      }
    } finally {
      setSubmitting(false);
    }
  };

  if (loading) return <div className="tc-loading-screen"><div className="tc-spinner tc-spinner-lg"></div><p>Memuat data anak...</p></div>;

  if (error && children.length === 0) return (
    <div className="tc-error-state">
      <div className="tc-error-state-icon"><svg width="28" height="28" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8"><circle cx="12" cy="12" r="10"/><line x1="12" y1="8" x2="12" y2="12"/><line x1="12" y1="16" x2="12.01" y2="16"/></svg></div>
      <p className="tc-empty-state-title">{error}</p>
    </div>
  );

  return (
    <div>
      <PageHeader
        title="Anak Saya"
        subtitle="Daftar anak yang terdaftar di daycare."
        action={
          <button onClick={() => { resetForm(); setShowModal(true); }} className="tc-btn tc-btn-primary">
            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round"><line x1="12" y1="5" x2="12" y2="19"/><line x1="5" y1="12" x2="19" y2="12"/></svg>
            Tambah Anak
          </button>
        }
      />

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
            <p className="tc-empty-state-desc">Tambahkan data anak Anda dengan menekan tombol "Tambah Anak".</p>
          </div>
        </div>
      )}

      {/* Add Child Modal */}
      <Modal open={showModal} onClose={() => { setShowModal(false); resetForm(); }} title="Tambah Anak">
        <form onSubmit={handleSubmit} style={{ display: 'flex', flexDirection: 'column', gap: '14px' }}>
          {/* Photo */}
          <div style={{ display: 'flex', alignItems: 'center', gap: '16px' }}>
            <div style={{
              width: '96px', height: '96px', borderRadius: 'var(--radius-lg)',
              background: 'var(--color-bg-alt)', border: '1px solid var(--color-border)',
              display: 'flex', alignItems: 'center', justifyContent: 'center', overflow: 'hidden', flexShrink: 0,
            }}>
              {photoPreview ? (
                <img src={photoPreview} alt="Preview" style={{ width: '100%', height: '100%', objectFit: 'cover', display: 'block' }} />
              ) : (
                <span style={{ color: 'var(--color-text-muted)', fontSize: '12px' }}>Foto</span>
              )}
            </div>
            <div style={{ display: 'flex', flexDirection: 'column', gap: '6px', flex: 1 }}>
              <input
                ref={fileInputRef}
                type="file"
                accept="image/jpeg,image/png,image/gif"
                onChange={handlePhotoChange}
                style={{ display: 'none' }}
                id="parent-child-photo"
              />
              {photoFile ? (
                <button type="button" onClick={removePhoto} className="tc-btn tc-btn-secondary tc-btn-sm">
                  Hapus Foto
                </button>
              ) : (
                <label htmlFor="parent-child-photo">
                  <span className="tc-btn tc-btn-secondary tc-btn-sm" style={{ cursor: 'pointer', display: 'inline-block' }}>Unggah Foto</span>
                </label>
              )}
              <p style={{ fontSize: '11px', color: 'var(--color-text-muted)' }}>Foto dikompres otomatis agar ukurannya kecil.</p>
              {photoError && <p style={{ fontSize: '12px', color: 'var(--color-error)' }}>{photoError}</p>}
            </div>
          </div>

          <input type="text" required placeholder="Nama Anak *" value={formData.name} onChange={(e) => setFormData({ ...formData, name: e.target.value })} className="tc-input" />

          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '12px' }}>
            <div>
              <label style={{ fontSize: '13px', fontWeight: '600', display: 'block', marginBottom: '6px' }}>Jenis Kelamin *</label>
              <select value={formData.gender} onChange={(e) => setFormData({ ...formData, gender: e.target.value })} className="tc-input">
                <option value="male">Laki-laki</option>
                <option value="female">Perempuan</option>
              </select>
            </div>
            <div>
              <label style={{ fontSize: '13px', fontWeight: '600', display: 'block', marginBottom: '6px' }}>Tanggal Lahir *</label>
              <input type="date" required value={formData.birth_date} max={new Date().toISOString().split('T')[0]} onChange={(e) => setFormData({ ...formData, birth_date: e.target.value })} className="tc-input" />
            </div>
          </div>

          <input type="text" placeholder="Alamat" value={formData.address} onChange={(e) => setFormData({ ...formData, address: e.target.value })} className="tc-input" />
          <input type="text" placeholder="Informasi Kesehatan / Alergi" value={formData.health_info} onChange={(e) => setFormData({ ...formData, health_info: e.target.value })} className="tc-input" />
          <input type="text" placeholder="Nama Kontak Darurat" value={formData.emergency_contact_name} onChange={(e) => setFormData({ ...formData, emergency_contact_name: e.target.value })} className="tc-input" />
          <input type="text" placeholder="Telepon Kontak Darurat" value={formData.emergency_contact_phone} onChange={(e) => setFormData({ ...formData, emergency_contact_phone: e.target.value })} className="tc-input" />

          <div style={{ display: 'flex', gap: '10px', justifyContent: 'flex-end', marginTop: '8px' }}>
            <button type="button" onClick={() => { setShowModal(false); resetForm(); }} className="tc-btn tc-btn-secondary">Batal</button>
            <button type="submit" disabled={submitting} className="tc-btn tc-btn-primary">
              {submitting ? 'Menyimpan...' : 'Simpan Anak'}
            </button>
          </div>
        </form>
      </Modal>
    </div>
  );
}
