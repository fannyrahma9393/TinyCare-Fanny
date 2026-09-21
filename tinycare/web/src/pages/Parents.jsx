import { useState, useEffect } from 'react';
import { Link } from 'react-router-dom';
import { useTranslation } from 'react-i18next';
import { parentsAPI } from '../services/api';
import { PageHeader, Modal, EmptyState } from '../components/PageHeader';

export default function Parents() {
  const { t } = useTranslation();
  const [parents, setParents] = useState([]);
  const [loading, setLoading] = useState(true);
  const [showModal, setShowModal] = useState(false);
  const [search, setSearch] = useState('');
  const [submitting, setSubmitting] = useState(false);
  const [formData, setFormData] = useState({
    name: '', email: '', password: '', phone: '', address: '',
    emergency_contact_name: '', emergency_contact_phone: '', emergency_contact_relationship: '',
  });
  const [errors, setErrors] = useState({});
  const [error, setError] = useState('');

  async function loadParents() {
    try {
      setLoading(true);
      const res = await parentsAPI.list({ search });
      setParents(res.data.data.data || []);
    } catch (error) {
      setError(error.response?.data?.message || t('Gagal memuat data orang tua.'));
    } finally {
      setLoading(false);
    }
  }

  useEffect(() => { loadParents(); }, []);
  useEffect(() => { const t = setTimeout(() => loadParents(), 300); return () => clearTimeout(t); }, [search]);

  const resetForm = () => {
    setFormData({ name: '', email: '', password: '', phone: '', address: '', emergency_contact_name: '', emergency_contact_phone: '', emergency_contact_relationship: '' });
    setErrors({});
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    setSubmitting(true);
    setErrors({});
    try {
      await parentsAPI.create(formData);
      setShowModal(false);
      resetForm();
      loadParents();
    } catch (error) {
      if (error.response?.status === 422) {
        setErrors(error.response.data.errors || {});
      } else {
        alert(error.response?.data?.message || t('Gagal menambahkan orang tua.'));
      }
    } finally {
      setSubmitting(false);
    }
  };

  const handleDelete = async (id) => {
    if (confirm(t('Yakin ingin menghapus orang tua ini?'))) {
      try {
        await parentsAPI.delete(id);
        loadParents();
      } catch (error) {
        alert(error.response?.data?.message || t('Gagal menghapus orang tua.'));
      }
    }
  };

  const getFieldError = (field) => errors[field]?.[0] || null;

  if (loading && parents.length === 0) {
    return <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'center', height: '300px' }}><div className="tc-spinner"></div></div>;
  }

  return (
    <div>
      <PageHeader
        title={t('Manajemen Orang Tua')}
        subtitle={t('Kelola akun orang tua yang terdaftar')}
        action={
          <button onClick={() => { resetForm(); setShowModal(true); }} className="tc-btn tc-btn-primary">
            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round"><line x1="12" y1="5" x2="12" y2="19"/><line x1="5" y1="12" x2="19" y2="12"/></svg>
            {t('Tambah Orang Tua')}
          </button>
        }
      />

      <div style={{ marginBottom: '16px' }}>
        <input type="text" placeholder={t('Cari nama atau email...')} value={search} onChange={(e) => setSearch(e.target.value)} className="tc-input" style={{ maxWidth: '360px' }} />
      </div>

      {error && (
        <div className="tc-error-state" style={{ marginBottom: '16px' }}>
          <p className="tc-empty-state-title">{error}</p>
          <button onClick={() => { setError(''); loadParents(); }} className="tc-btn tc-btn-secondary tc-btn-sm" style={{ marginTop: '12px' }}>{t('Coba Lagi')}</button>
        </div>
      )}

      <div className="tc-card" style={{ overflow: 'hidden' }}>
        <table className="tc-table">
          <thead>
            <tr>
              <th>{t('Nama')}</th>
              <th>{t('Email')}</th>
              <th>{t('Telepon')}</th>
              <th>{t('Anak')}</th>
              <th>{t('Status')}</th>
              <th>{t('Aksi')}</th>
            </tr>
          </thead>
          <tbody>
            {parents.map((parent) => (
              <tr key={parent.id}>
                <td>
                  <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
                    <div style={{
                      width: '34px', height: '34px', borderRadius: '8px',
                      background: 'var(--color-primary-lighter)',
                      display: 'flex', alignItems: 'center', justifyContent: 'center',
                    }}>
                      <span style={{ color: 'var(--color-primary)', fontWeight: '700', fontSize: '13px' }}>{parent.user?.name?.charAt(0)}</span>
                    </div>
                    <span style={{ fontWeight: '600' }}>{parent.user?.name}</span>
                  </div>
                </td>
                <td style={{ color: 'var(--color-text-secondary)', fontSize: '13px' }}>{parent.user?.email}</td>
                <td style={{ color: 'var(--color-text-secondary)', fontSize: '13px' }}>{parent.phone || '-'}</td>
                <td>
                  {parent.children && parent.children.length > 0 ? (
                    <div style={{ display: 'flex', flexWrap: 'wrap', gap: '4px' }}>
                      {parent.children.map((child) => (
                        <span key={child.id} className={`tc-badge ${child.status === 'active' ? 'tc-badge-success' : 'tc-badge-info'}`}>{child.name}</span>
                      ))}
                    </div>
                  ) : (
                    <span style={{ fontSize: '12px', color: 'var(--color-text-muted)', fontStyle: 'italic' }}>{t('Belum ada anak')}</span>
                  )}
                </td>
                <td>
                  <span className={`tc-badge ${parent.effective_status === 'active' ? 'tc-badge-success' : 'tc-badge-error'}`}>
                    {parent.effective_status === 'active' ? t('Aktif') : t('Nonaktif')}
                  </span>
                </td>
                <td>
                  <div style={{ display: 'flex', gap: '4px' }}>
                    <Link to={`/parents/${parent.id}`} className="tc-btn tc-btn-ghost" style={{ color: 'var(--color-info)', padding: '4px 8px', fontSize: '13px' }}>Detail</Link>
                    <button onClick={() => handleDelete(parent.id)} className="tc-btn tc-btn-ghost" style={{ color: 'var(--color-error)', padding: '4px 8px', fontSize: '13px' }}>
                      {t('Hapus')}
                    </button>
                  </div>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
        {parents.length === 0 && <EmptyState icon="👨‍👩‍👧" title={t('Belum ada orang tua terdaftar')} description={t("Klik 'Tambah Orang Tua' untuk menambahkan.")} />}
      </div>

      <Modal open={showModal} onClose={() => setShowModal(false)} title={t('Tambah Orang Tua Baru')} maxWidth="560px">
        <form onSubmit={handleSubmit}>
          <div style={{ display: 'flex', flexDirection: 'column', gap: '14px' }}>
            <div>
              <label className="tc-label">{t('Nama Lengkap *')}</label>
              <input type="text" value={formData.name} onChange={(e) => setFormData({ ...formData, name: e.target.value })} className="tc-input" style={getFieldError('name') ? { borderColor: 'var(--color-error)' } : {}} required />
              {getFieldError('name') && <p style={{ color: 'var(--color-error)', fontSize: '12px', marginTop: '4px' }}>{getFieldError('name')}</p>}
            </div>
            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '14px' }}>
              <div>
                <label className="tc-label">{t('Email *')}</label>
                <input type="email" value={formData.email} onChange={(e) => setFormData({ ...formData, email: e.target.value })} className="tc-input" style={getFieldError('email') ? { borderColor: 'var(--color-error)' } : {}} required />
                {getFieldError('email') && <p style={{ color: 'var(--color-error)', fontSize: '12px', marginTop: '4px' }}>{getFieldError('email')}</p>}
              </div>
              <div>
                <label className="tc-label">{t('Password *')}</label>
                <input type="password" value={formData.password} onChange={(e) => setFormData({ ...formData, password: e.target.value })} className="tc-input" style={getFieldError('password') ? { borderColor: 'var(--color-error)' } : {}} required minLength={8} />
                {getFieldError('password') && <p style={{ color: 'var(--color-error)', fontSize: '12px', marginTop: '4px' }}>{getFieldError('password')}</p>}
              </div>
            </div>
            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '14px' }}>
              <div>
                <label className="tc-label">{t('Telepon')}</label>
                <input type="text" value={formData.phone} onChange={(e) => setFormData({ ...formData, phone: e.target.value })} className="tc-input" />
              </div>
              <div>
                <label className="tc-label">{t('Alamat')}</label>
                <input type="text" value={formData.address} onChange={(e) => setFormData({ ...formData, address: e.target.value })} className="tc-input" />
              </div>
            </div>
          </div>
          <div style={{ display: 'flex', gap: '10px', marginTop: '20px' }}>
            <button type="button" onClick={() => setShowModal(false)} className="tc-btn tc-btn-secondary" style={{ flex: 1 }}>{t('Batal')}</button>
            <button type="submit" disabled={submitting} className="tc-btn tc-btn-primary" style={{ flex: 1 }}>
              {submitting ? t('Menyimpan...') : t('Simpan')}
            </button>
          </div>
        </form>
      </Modal>
    </div>
  );
}
