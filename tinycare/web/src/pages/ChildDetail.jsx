import { useState, useEffect, useRef } from 'react';
import { useNavigate, useParams } from 'react-router-dom';
import { useTranslation } from 'react-i18next';
import { childrenAPI } from '../services/api';
import ChildPhoto from '../components/ChildPhoto';

const PHOTO_ACCEPT = 'image/jpeg,image/png,image/gif';
const PHOTO_MAX_MB = 5;

function validatePhotoFile(file, t) {
  if (!file) return null;
  if (file.size > PHOTO_MAX_MB * 1024 * 1024) return t('Ukuran foto maksimal {{max}}MB.', { max: PHOTO_MAX_MB });
  if (!['image/jpeg', 'image/png', 'image/gif'].includes(file.type)) return t('Format foto harus JPG, PNG, atau GIF.');
  return null;
}

export default function ChildDetail() {
  const { t } = useTranslation();
  const { id } = useParams();
  const navigate = useNavigate();
  const [child, setChild] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');

  const [showEditModal, setShowEditModal] = useState(false);
  const [editForm, setEditForm] = useState({
    name: '', birth_date: '', gender: 'male', address: '', health_info: '',
    emergency_contact_name: '', emergency_contact_phone: '', emergency_contact_relationship: '', status: 'active',
  });
  const [editPhotoFile, setEditPhotoFile] = useState(null);
  const [editPhotoPreview, setEditPhotoPreview] = useState(null);
  const [editPhotoError, setEditPhotoError] = useState('');
  const [editSubmitting, setEditSubmitting] = useState(false);
  const [editError, setEditError] = useState('');
  const editFileRef = useRef(null);

  async function loadChild() {
    try {
      const res = await childrenAPI.get(id);
      setChild(res.data.data);
      setError('');
    } catch (err) {
      setError(err.response?.data?.message || t('Gagal memuat data anak.'));
    } finally {
      setLoading(false);
    }
  }

  useEffect(() => {
    loadChild();
  }, [id]);

  const openEditModal = () => {
    if (!child) return;
    setEditForm({
      name: child.name || '',
      birth_date: child.birth_date ? child.birth_date.split('T')[0] : '',
      gender: child.gender || 'male',
      address: child.address || '',
      health_info: child.health_info || '',
      emergency_contact_name: child.emergency_contact_name || '',
      emergency_contact_phone: child.emergency_contact_phone || '',
      emergency_contact_relationship: child.emergency_contact_relationship || '',
      status: child.status || 'active',
    });
    setEditPhotoFile(null);
    setEditPhotoPreview(null);
    setEditPhotoError('');
    setEditError('');
    if (editFileRef.current) editFileRef.current.value = '';
    setShowEditModal(true);
  };

  const handleEditPhotoChange = (e) => {
    const file = e.target.files?.[0];
    setEditPhotoError('');
    if (!file) { setEditPhotoFile(null); setEditPhotoPreview(null); return; }
    const err = validatePhotoFile(file, t);
    if (err) {
      setEditPhotoError(err);
      setEditPhotoFile(null);
      setEditPhotoPreview(null);
      if (editFileRef.current) editFileRef.current.value = '';
      return;
    }
    setEditPhotoFile(file);
    setEditPhotoPreview(URL.createObjectURL(file));
  };

  const removeEditPhoto = () => {
    setEditPhotoFile(null);
    setEditPhotoPreview(null);
    setEditPhotoError('');
    if (editFileRef.current) editFileRef.current.value = '';
  };

  const handleEditSubmit = async (e) => {
    e.preventDefault();
    setEditSubmitting(true);
    setEditError('');
    try {
      const fd = new FormData();
      fd.append('name', editForm.name);
      fd.append('birth_date', editForm.birth_date);
      fd.append('gender', editForm.gender);
      fd.append('status', editForm.status);
      if (editForm.address) fd.append('address', editForm.address);
      if (editForm.health_info) fd.append('health_info', editForm.health_info);
      if (editForm.emergency_contact_name) fd.append('emergency_contact_name', editForm.emergency_contact_name);
      if (editForm.emergency_contact_phone) fd.append('emergency_contact_phone', editForm.emergency_contact_phone);
      if (editForm.emergency_contact_relationship) fd.append('emergency_contact_relationship', editForm.emergency_contact_relationship);
      if (editPhotoFile) fd.append('photo', editPhotoFile);

      await childrenAPI.update(id, fd);
      setShowEditModal(false);
      loadChild();
    } catch (err) {
      if (err.response?.status === 422) {
        const errors = err.response.data.errors;
        if (errors) {
          const first = Object.values(errors)[0];
          setEditError(Array.isArray(first) ? first[0] : first);
        } else {
          setEditError(err.response.data.message || t('Data tidak valid.'));
        }
      } else {
        setEditError(err.response?.data?.message || t('Gagal menyimpan perubahan.'));
      }
    } finally {
      setEditSubmitting(false);
    }
  };

  const handleToggleStatus = async () => {
    if (!child) return;
    const targetStatus = child.status === 'active' ? 'inactive' : 'active';
    if (targetStatus === 'inactive') {
      if (!confirm(t('Nonaktifkan {{name}}? Orang tua terkait juga akan dinonaktifkan jika ini anak satu-satunya.', { name: child.name }))) return;
    } else {
      if (!confirm(t('Aktifkan {{name}} kembali?', { name: child.name }))) return;
    }
    try {
      await childrenAPI.update(child.id, { status: targetStatus });
      setChild({ ...child, status: targetStatus });
    } catch (e) {
      alert(e.response?.data?.message || t('Gagal mengubah status anak.'));
    }
  };

  if (loading) {
    return <div className="tc-loading-screen"><div className="tc-spinner tc-spinner-lg"></div><p>{t('Memuat data anak...')}</p></div>;
  }

  if (error) {
    return (
      <div>
        <button onClick={() => navigate('/children')} style={{ background: 'none', border: 'none', color: 'var(--color-primary)', cursor: 'pointer', fontSize: '13px', marginBottom: '16px', display: 'flex', alignItems: 'center', gap: '4px', fontWeight: 500 }}>
          <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><polyline points="15 18 9 12 15 6"/></svg>
          {t('Kembali')}
        </button>
        <div className="tc-error-state">
          <div className="tc-error-state-icon"><svg width="28" height="28" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8"><circle cx="12" cy="12" r="10"/><line x1="12" y1="8" x2="12" y2="12"/><line x1="12" y1="16" x2="12.01" y2="16"/></svg></div>
          <p className="tc-empty-state-title">{error}</p>
          <button onClick={loadChild} className="tc-btn tc-btn-secondary tc-btn-sm" style={{ marginTop: '12px' }}>{t('Coba Lagi')}</button>
        </div>
      </div>
    );
  }

  if (!child) {
    return (
      <div>
        <button onClick={() => navigate('/children')} style={{ background: 'none', border: 'none', color: 'var(--color-primary)', cursor: 'pointer', fontSize: '13px', marginBottom: '16px', display: 'flex', alignItems: 'center', gap: '4px', fontWeight: 500 }}>
          <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><polyline points="15 18 9 12 15 6"/></svg>
          {t('Kembali')}
        </button>
        <div className="tc-card"><div className="tc-empty-state"><p className="tc-empty-state-title">{t('Anak tidak ditemukan.')}</p></div></div>
      </div>
    );
  }

  const InfoRow = ({ label, value }) => (
    <div style={{ display: 'flex', justifyContent: 'space-between', padding: '8px 0', borderBottom: '1px solid var(--color-border-light)' }}>
      <span style={{ fontSize: '13px', color: 'var(--color-text-secondary)' }}>{label}</span>
      <span style={{ fontSize: '13px', fontWeight: '500', color: 'var(--color-text)', textAlign: 'right' }}>{value || '-'}</span>
    </div>
  );

  return (
    <div>
      <button onClick={() => navigate('/children')} style={{ background: 'none', border: 'none', color: 'var(--color-primary)', cursor: 'pointer', fontSize: '13px', marginBottom: '16px', display: 'flex', alignItems: 'center', gap: '4px', fontWeight: 500 }}>
        <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><polyline points="15 18 9 12 15 6"/></svg>
        {t('Kembali ke Daftar Anak')}
      </button>

      {/* Header Section */}
      <div style={{ display: 'flex', alignItems: 'center', gap: '20px', marginBottom: '28px', flexWrap: 'wrap' }}>
        <ChildPhoto child={child} width={120} alt={child.name} />
        <div style={{ flex: 1, minWidth: 0 }}>
          <h1 style={{ fontSize: '22px', fontWeight: '700', letterSpacing: '-0.02em', marginBottom: '6px' }}>{child.name}</h1>
          <div style={{ display: 'flex', alignItems: 'center', gap: '8px', flexWrap: 'wrap' }}>
            <span className={`tc-badge ${child.status === 'active' ? 'tc-badge-success' : 'tc-badge-info'}`}>
              {child.status === 'active' ? t('Aktif') : t('Nonaktif')}
            </span>
          </div>
        </div>
        <button onClick={openEditModal} className="tc-btn tc-btn-primary">
          <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7"/><path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z"/></svg>
          {t('Edit')}
        </button>
      </div>

      {/* Info Cards */}
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(300px, 1fr))', gap: '16px', marginBottom: '24px' }}>
        {/* Identitas */}
        <div className="tc-card" style={{ padding: '20px' }}>
          <h3 style={{ fontSize: '14px', fontWeight: '700', marginBottom: '14px', color: 'var(--color-text)' }}>{t('Identitas')}</h3>
          <div>
            <InfoRow label={t('Nama')} value={child.name} />
            <InfoRow label={t('Tanggal Lahir')} value={child.birth_date ? new Date(child.birth_date).toLocaleDateString('id-ID', { day: 'numeric', month: 'long', year: 'numeric' }) : null} />
            <InfoRow label={t('Gender')} value={child.gender === 'male' ? t('Laki-laki') : t('Perempuan')} />
            <InfoRow label={t('Alamat')} value={child.address} />
          </div>
        </div>

        {/* Informasi Kesehatan */}
        <div className="tc-card" style={{ padding: '20px' }}>
          <h3 style={{ fontSize: '14px', fontWeight: '700', marginBottom: '14px', color: 'var(--color-text)' }}>{t('Informasi Kesehatan')}</h3>
          <div>
            <div style={{ fontSize: '13px', color: child.health_info ? 'var(--color-text)' : 'var(--color-text-muted)', fontStyle: child.health_info ? 'normal' : 'italic', lineHeight: 1.6 }}>
              {child.health_info || t('Tidak ada informasi kesehatan yang tercatat.')}
            </div>
          </div>
        </div>

        {/* Kontak Darurat */}
        <div className="tc-card" style={{ padding: '20px' }}>
          <h3 style={{ fontSize: '14px', fontWeight: '700', marginBottom: '14px', color: 'var(--color-text)' }}>{t('Kontak Darurat')}</h3>
          <div>
            <InfoRow label={t('Nama')} value={child.emergency_contact_name} />
            <InfoRow label={t('Telepon')} value={child.emergency_contact_phone} />
            <InfoRow label={t('Hubungan')} value={child.emergency_contact_relationship} />
          </div>
        </div>

        {/* Status */}
        <div className="tc-card" style={{ padding: '20px' }}>
          <h3 style={{ fontSize: '14px', fontWeight: '700', marginBottom: '14px', color: 'var(--color-text)' }}>{t('Status')}</h3>
          <div>
            <InfoRow label={t('Status Akun')} value={child.status === 'active' ? t('Aktif') : t('Nonaktif')} />
            <InfoRow label={t('Dibuat')} value={child.created_at ? new Date(child.created_at).toLocaleDateString('id-ID') : '-'} />
            <InfoRow label={t('Diperbarui')} value={child.updated_at ? new Date(child.updated_at).toLocaleDateString('id-ID') : '-'} />
          </div>
        </div>

        {/* Orang Tua */}
        <div className="tc-card" style={{ padding: '20px' }}>
          <h3 style={{ fontSize: '14px', fontWeight: '700', marginBottom: '14px', color: 'var(--color-text)' }}>{t('Orang Tua')}</h3>
          <div>
            {child.parents && child.parents.length > 0 ? (
              child.parents.map((parent) => (
                <div key={parent.id} style={{ display: 'flex', alignItems: 'center', gap: '10px', padding: '8px 0', borderBottom: '1px solid var(--color-border-light)' }}>
                  <div style={{
                    width: '32px', height: '32px', borderRadius: 'var(--radius-md)',
                    background: 'var(--color-primary-lighter)',
                    display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0,
                  }}>
                    <span style={{ color: 'var(--color-primary)', fontWeight: '700', fontSize: '12px' }}>{parent.user?.name?.charAt(0)}</span>
                  </div>
                  <div style={{ minWidth: 0 }}>
                    <p style={{ fontSize: '13px', fontWeight: '600', color: 'var(--color-text)' }}>{parent.user?.name}</p>
                    <p style={{ fontSize: '12px', color: 'var(--color-text-muted)' }}>{parent.user?.email}</p>
                  </div>
                </div>
              ))
            ) : (
              <p style={{ fontSize: '13px', color: 'var(--color-text-muted)', fontStyle: 'italic' }}>{t('Tidak ada orang tua terdaftar.')}</p>
            )}
          </div>
        </div>

        {/* Paket */}
        <div className="tc-card" style={{ padding: '20px' }}>
          <h3 style={{ fontSize: '14px', fontWeight: '700', marginBottom: '14px', color: 'var(--color-text)' }}>{t('Paket')}</h3>
          <div>
            {child.child_packages && child.child_packages.length > 0 ? (
              child.child_packages.map((cp) => (
                <div key={cp.id} style={{ padding: '8px 0', borderBottom: '1px solid var(--color-border-light)' }}>
                  <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                    <p style={{ fontSize: '13px', fontWeight: '600', color: 'var(--color-text)' }}>{cp.package?.name}</p>
                    <span className={`tc-badge ${cp.status === 'active' ? 'tc-badge-success' : cp.status === 'expired' ? 'tc-badge-error' : 'tc-badge-info'}`} style={{ fontSize: '11px' }}>
                      {cp.status === 'active' ? t('Aktif') : cp.status === 'expired' ? 'Expired' : t('Dibatalkan')}
                    </span>
                  </div>
                  <p style={{ fontSize: '12px', color: 'var(--color-text-muted)' }}>
                    Rp {new Intl.NumberFormat('id-ID').format(cp.package?.price || 0)} · {cp.start_date ? t('Mulai {{date}}', { date: new Date(cp.start_date).toLocaleDateString('id-ID') }) : ''}
                    {cp.end_date ? ` · ${t('Sampai {{date}}', { date: new Date(cp.end_date).toLocaleDateString('id-ID') })}` : ''}
                  </p>
                </div>
              ))
            ) : (
              <p style={{ fontSize: '13px', color: 'var(--color-text-muted)', fontStyle: 'italic' }}>{t('Belum ada paket aktif.')}</p>
            )}
          </div>
        </div>
      </div>

      {/* Quick Links */}
      <div className="tc-card" style={{ padding: '20px', marginBottom: '24px' }}>
        <h3 style={{ fontSize: '14px', fontWeight: '700', marginBottom: '14px', color: 'var(--color-text)' }}>{t('Akses Cepat')}</h3>
        <div style={{ display: 'flex', gap: '10px', flexWrap: 'wrap' }}>
          <button onClick={() => navigate(`/development?child=${child.id}`)} className="tc-btn tc-btn-secondary">
            <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round"><polyline points="22 12 18 12 15 21 9 3 6 12 2 12"/></svg>
            {t('Perkembangan')}
          </button>
          <button onClick={() => navigate(`/daily-stories?child=${child.id}`)} className="tc-btn tc-btn-secondary">
            <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round"><path d="M2 3h6a4 4 0 0 1 4 4v14a3 3 0 0 0-3-3H2z"/><path d="M22 3h-6a4 4 0 0 0-4 4v14a3 3 0 0 1 3-3h7z"/></svg>
            Daily Story
          </button>
          <button onClick={() => navigate(`/child-information/${child.id}`)} className="tc-btn tc-btn-secondary">
            <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round"><circle cx="12" cy="12" r="10"/><line x1="12" y1="16" x2="12" y2="12"/><line x1="12" y1="8" x2="12.01" y2="8"/></svg>
            {t('Informasi Anak')}
          </button>
        </div>
      </div>

      {/* Toggle Status Button */}
      <div style={{ display: 'flex', gap: '10px' }}>
        <button
          onClick={handleToggleStatus}
          className={`tc-btn ${child.status === 'active' ? 'tc-btn-ghost' : 'tc-btn-primary'}`}
          style={child.status === 'active' ? { color: 'var(--color-warning)', borderColor: 'var(--color-warning)' } : {}}
        >
          {child.status === 'active' ? t('Nonaktifkan') : t('Aktifkan')}
        </button>
      </div>

      {/* Edit Modal */}
      {showEditModal && (
        <div style={{ position: 'fixed', inset: 0, zIndex: 1000, display: 'flex', alignItems: 'center', justifyContent: 'center', background: 'rgba(0,0,0,0.5)' }}
          onClick={(e) => { if (e.target === e.currentTarget) setShowEditModal(false); }}>
          <div className="tc-card" style={{ width: '100%', maxWidth: '560px', maxHeight: '90vh', overflow: 'auto', padding: '24px' }}>
            <h2 style={{ fontSize: '16px', fontWeight: '700', marginBottom: '18px' }}>{t('Edit Data Anak')}</h2>
            {editError && (
              <div style={{ padding: '10px 14px', background: 'var(--color-error-bg)', border: '1px solid var(--color-error)', borderRadius: 'var(--radius-md)', color: 'var(--color-error)', fontSize: '13px', marginBottom: '14px' }}>{editError}</div>
            )}
            <form onSubmit={handleEditSubmit}>
              <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '14px' }}>
                {/* Photo */}
                <div style={{ gridColumn: 'span 2' }}>
                  <label className="tc-label">{t('Foto Profil Anak')}</label>
                  <div style={{ display: 'flex', alignItems: 'center', gap: '14px' }}>
                    <div style={{
                      width: '60px', height: '90px', borderRadius: 'var(--radius-lg)',
                      overflow: 'hidden', flexShrink: 0, border: '2px dashed var(--color-border)',
                    }}>
                      {editPhotoPreview ? (
                        <img src={editPhotoPreview} alt="Preview" style={{ width: '100%', height: '100%', objectFit: 'cover', display: 'block' }} />
                      ) : (child.photo_url || child.photo || child.image_url) ? (
                        <img src={child.photo_url || child.photo || child.image_url} alt={child.name} style={{ width: '100%', height: '100%', objectFit: 'cover', display: 'block' }} />
                      ) : (
                        <img src="/placeholder-avatar.svg" alt="Placeholder" style={{ width: '100%', height: '100%', objectFit: 'cover', display: 'block' }} />
                      )}
                    </div>
                    <div style={{ flex: 1, display: 'flex', flexDirection: 'column', gap: '6px' }}>
                      <input ref={editFileRef} type="file" accept={PHOTO_ACCEPT} onChange={handleEditPhotoChange} className="tc-input" style={{ fontSize: '13px', padding: '8px 10px' }} />
                      {editPhotoPreview && (
                        <button type="button" onClick={removeEditPhoto} className="tc-btn tc-btn-ghost tc-btn-sm" style={{ fontSize: '12px', color: 'var(--color-error)', alignSelf: 'flex-start' }}>
                          {t('Hapus Foto Baru')}
                        </button>
                      )}
                      {editPhotoError && <p style={{ fontSize: '12px', color: 'var(--color-error)' }}>{editPhotoError}</p>}
                      <p style={{ fontSize: '11px', color: 'var(--color-text-muted)' }}>{t('Kosongkan jika tidak ingin mengganti foto.')}</p>
                    </div>
                  </div>
                </div>

                <div style={{ gridColumn: 'span 2' }}>
                  <label className="tc-label">{t('Nama Anak *')}</label>
                  <input type="text" value={editForm.name} onChange={(e) => setEditForm({ ...editForm, name: e.target.value })} className="tc-input" required />
                </div>
                <div>
                  <label className="tc-label">{t('Tanggal Lahir *')}</label>
                  <input type="date" value={editForm.birth_date} onChange={(e) => setEditForm({ ...editForm, birth_date: e.target.value })} className="tc-input" required />
                </div>
                <div>
                  <label className="tc-label">{t('Gender *')}</label>
                  <select value={editForm.gender} onChange={(e) => setEditForm({ ...editForm, gender: e.target.value })} className="tc-select">
                    <option value="male">{t('Laki-laki')}</option>
                    <option value="female">{t('Perempuan')}</option>
                  </select>
                </div>
                <div>
                  <label className="tc-label">{t('Status')}</label>
                  <select value={editForm.status} onChange={(e) => setEditForm({ ...editForm, status: e.target.value })} className="tc-select">
                    <option value="active">{t('Aktif')}</option>
                    <option value="inactive">{t('Nonaktif')}</option>
                  </select>
                </div>
                <div>
                  <label className="tc-label">{t('Kontak Darurat - Nama')}</label>
                  <input type="text" value={editForm.emergency_contact_name} onChange={(e) => setEditForm({ ...editForm, emergency_contact_name: e.target.value })} className="tc-input" />
                </div>
                <div>
                  <label className="tc-label">{t('Kontak Darurat - Telepon')}</label>
                  <input type="text" value={editForm.emergency_contact_phone} onChange={(e) => setEditForm({ ...editForm, emergency_contact_phone: e.target.value })} className="tc-input" />
                </div>
                <div>
                  <label className="tc-label">{t('Kontak Darurat - Hubungan')}</label>
                  <input type="text" value={editForm.emergency_contact_relationship} onChange={(e) => setEditForm({ ...editForm, emergency_contact_relationship: e.target.value })} className="tc-input" />
                </div>
                <div style={{ gridColumn: 'span 2' }}>
                  <label className="tc-label">{t('Informasi Kesehatan')}</label>
                  <textarea value={editForm.health_info} onChange={(e) => setEditForm({ ...editForm, health_info: e.target.value })} className="tc-input" rows="2" />
                </div>
                <div style={{ gridColumn: 'span 2' }}>
                  <label className="tc-label">{t('Alamat')}</label>
                  <textarea value={editForm.address} onChange={(e) => setEditForm({ ...editForm, address: e.target.value })} className="tc-input" rows="2" />
                </div>
              </div>
              <div style={{ display: 'flex', gap: '10px', marginTop: '20px' }}>
                <button type="button" onClick={() => setShowEditModal(false)} className="tc-btn tc-btn-secondary" style={{ flex: 1 }}>{t('Batal')}</button>
                <button type="submit" disabled={editSubmitting} className="tc-btn tc-btn-primary" style={{ flex: 1 }}>{editSubmitting ? t('Menyimpan...') : t('Simpan')}</button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
}
