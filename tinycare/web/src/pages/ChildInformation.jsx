import { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { useTranslation } from 'react-i18next';
import { childrenAPI } from '../services/api';
import api from '../services/api';
import { PageHeader, Modal, EmptyState } from '../components/PageHeader';
import ChildPhoto from '../components/ChildPhoto';

export default function ChildInformation() {
  const { t } = useTranslation();
  const navigate = useNavigate();
  const [children, setChildren] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [showModal, setShowModal] = useState(false);
  const [submitting, setSubmitting] = useState(false);
  const [modalError, setModalError] = useState('');
  const [submitResult, setSubmitResult] = useState(null);
  const [formData, setFormData] = useState({
    child_id: '', title: '', content: '', priority: 'normal',
  });

  async function loadChildren() {
    try {
      const res = await childrenAPI.list({ per_page: 100 });
      setChildren(res.data.data.data || []);
      setError('');
    } catch (err) {
      setError(err.response?.data?.message || t('Gagal memuat data anak.'));
    } finally {
      setLoading(false);
    }
  }

  useEffect(() => {
    loadChildren();
  }, []);

  const handleSubmit = async (e) => {
    e.preventDefault();
    setSubmitting(true);
    setModalError('');
    setSubmitResult(null);
    try {
      const res = await api.post('/admin/child-information', formData);
      setShowModal(false);
      setFormData({ child_id: '', title: '', content: '', priority: 'normal' });
      setSubmitResult(res.data.notify || null);
    } catch (err) {
      if (err.response?.status === 422) {
        const errors = err.response.data.errors;
        if (errors) {
          const first = Object.values(errors)[0];
          setModalError(Array.isArray(first) ? first[0] : first);
        } else {
          setModalError(err.response.data.message || t('Data tidak valid.'));
        }
      } else {
        setModalError(err.response?.data?.message || t('Gagal menambahkan informasi.'));
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
      <PageHeader
        title={t('Informasi Anak')}
        subtitle={t('Pilih anak untuk mengelola informasi penting')}
        action={
          <button onClick={() => { setModalError(''); setShowModal(true); }} className="tc-btn tc-btn-primary">
            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round"><line x1="12" y1="5" x2="12" y2="19"/><line x1="5" y1="12" x2="19" y2="12"/></svg>
            {t('Tambah Informasi')}
          </button>
        }
      />

      {error && (
        <div className="tc-error-state" style={{ padding: '24px', marginBottom: '16px' }}>
          <p className="tc-empty-state-title">{error}</p>
          <button onClick={loadChildren} className="tc-btn tc-btn-secondary tc-btn-sm" style={{ marginTop: '12px' }}>{t('Coba Lagi')}</button>
        </div>
      )}

      {submitResult && (
        <div className="tc-card" style={{ padding: '14px 16px', marginBottom: '16px', borderLeft: '4px solid var(--color-success)' }}>
          <p style={{ fontSize: '14px', fontWeight: '700', color: 'var(--color-success)', marginBottom: '4px' }}>
            {t('✓ Informasi tersimpan')}
          </p>
          {submitResult.fcm_configured ? (
            submitResult.fcm_failed > 0 ? (
              <p style={{ fontSize: '13px', color: 'var(--color-text-secondary)' }}>
                {t('⚠ Notifikasi push gagal dikirim ke {{count}} perangkat. Notifikasi di aplikasi tetap tersimpan.', { count: submitResult.fcm_failed })}
              </p>
            ) : (
              <p style={{ fontSize: '13px', color: 'var(--color-text-secondary)' }}>
                {t('🔔 Push dikirim ke {{parents}} orang tua ({{devices}} perangkat) dan notifikasi aplikasi tersimpan.', { parents: submitResult.targeted_parents ?? 0, devices: submitResult.fcm_sent ?? 0 })}
              </p>
            )
          ) : (
            <p style={{ fontSize: '13px', color: 'var(--color-text-secondary)' }}>
              {t('ℹ Push belum dikonfigurasi. Notifikasi di aplikasi tetap tersimpan untuk {{parents}} orang tua.', { parents: submitResult.targeted_parents ?? 0 })}
            </p>
          )}
          <button onClick={() => setSubmitResult(null)} className="tc-btn tc-btn-secondary tc-btn-sm" style={{ marginTop: '8px' }}>{t('Tutup')}</button>
        </div>
      )}

      {!error && children.length > 0 && (
        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(220px, 1fr))', gap: '16px' }}>
          {children.map((child) => (
            <div
              key={child.id}
              className="tc-card tc-card-hover"
              style={{ padding: '16px', cursor: 'pointer', overflow: 'hidden' }}
              onClick={() => navigate(`/child-information/${child.id}`)}
            >
              <div style={{ display: 'flex', justifyContent: 'center', marginBottom: '14px' }}>
                <ChildPhoto child={child} width={120} alt={child.name} />
              </div>
              <h3 style={{ fontSize: '15px', fontWeight: '700', marginBottom: '4px' }}>{child.name}</h3>
              <span className={`tc-badge ${child.status === 'active' ? 'tc-badge-success' : 'tc-badge-info'}`}>
                {t(child.status === 'active' ? 'Status: Aktif' : 'Status: Nonaktif')}
              </span>
            </div>
          ))}
        </div>
      )}

      {!error && children.length === 0 && (
        <EmptyState
          icon="👶"
          title={t('Belum ada data anak')}
          description={t('Tambahkan data anak terlebih dahulu untuk mengelola informasi.')}
          action={
            <button onClick={() => setShowModal(true)} className="tc-btn tc-btn-primary">{t('Tambah Informasi')}</button>
          }
        />
      )}

      <Modal open={showModal} onClose={() => setShowModal(false)} title={t('Tambah Informasi Anak')} maxWidth="560px">
        {modalError && <div style={{ padding: '10px 14px', background: 'var(--color-error-bg)', border: '1px solid var(--color-error)', borderRadius: 'var(--radius-md)', color: 'var(--color-error)', fontSize: '13px', marginBottom: '14px' }}>{modalError}</div>}
        <form onSubmit={handleSubmit}>
          <div style={{ display: 'flex', flexDirection: 'column', gap: '14px' }}>
            <div>
              <label className="tc-label">{t('Anak *')}</label>
              <select value={formData.child_id} onChange={(e) => setFormData({ ...formData, child_id: e.target.value })} className="tc-select" required>
                <option value="">{t('-- Pilih Anak --')}</option>
                {children.map((c) => <option key={c.id} value={c.id}>{c.name}</option>)}
              </select>
            </div>
            <div>
              <label className="tc-label">{t('Judul *')}</label>
              <input type="text" value={formData.title} onChange={(e) => setFormData({ ...formData, title: e.target.value })} className="tc-input" placeholder={t('Contoh: Alergi makanan')} required />
            </div>
            <div>
              <label className="tc-label">{t('Konten *')}</label>
              <textarea value={formData.content} onChange={(e) => setFormData({ ...formData, content: e.target.value })} className="tc-input" rows="3" placeholder={t('Detail informasi')} required />
            </div>
            <div>
              <label className="tc-label">{t('Prioritas *')}</label>
              <select value={formData.priority} onChange={(e) => setFormData({ ...formData, priority: e.target.value })} className="tc-select">
                <option value="normal">{t('Normal')}</option>
                <option value="important">{t('Penting')}</option>
                <option value="urgent">{t('Urgent')}</option>
              </select>
            </div>
          </div>
          <div style={{ display: 'flex', gap: '10px', marginTop: '20px' }}>
            <button type="button" onClick={() => setShowModal(false)} className="tc-btn tc-btn-secondary" style={{ flex: 1 }}>{t('Batal')}</button>
            <button type="submit" disabled={submitting} className="tc-btn tc-btn-primary" style={{ flex: 1 }}>{submitting ? t('Menyimpan...') : t('Simpan')}</button>
          </div>
        </form>
      </Modal>
    </div>
  );
}