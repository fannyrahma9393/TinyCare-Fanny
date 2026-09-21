import { useState, useEffect, useRef } from 'react';
import { announcementsAPI, childrenAPI, parentsAPI } from '../services/api';
import { PageHeader, Modal, EmptyState } from '../components/PageHeader';
import { useTranslation } from 'react-i18next';

export default function Announcements() {
  const { t } = useTranslation();
  const [announcements, setAnnouncements] = useState([]);
  const [children, setChildren] = useState([]);
  const [parents, setParents] = useState([]);
  const [loading, setLoading] = useState(true);
  const [showModal, setShowModal] = useState(false);
  const [formData, setFormData] = useState({
    title: '', content: '', priority: 'normal', publish_date: '', expire_date: '',
    targetType: 'all', parent_ids: [], child_ids: [],
  });
  const [error, setError] = useState('');
  // Which action the last submit button click wants (Draft vs Publish). Read
  // in the form onSubmit after native HTML5 validation has passed.
  const submitAction = useRef(false);

  async function loadAnnouncements() {
    try { const res = await announcementsAPI.list(); setAnnouncements(res.data.data.data || []); }
    catch (error) { setError(error.response?.data?.message || t('Gagal memuat data pengumuman.')); } finally { setLoading(false); }
  }

  useEffect(() => { loadAnnouncements(); }, []);

  useEffect(() => {
    childrenAPI.list({ per_page: 100 })
      .then((res) => setChildren(res.data.data?.data || []))
      .catch(() => setChildren([]));
    parentsAPI.list({ per_page: 100 })
      .then((res) => setParents(res.data.data?.data || []))
      .catch(() => setParents([]));
  }, []);

  const toggleId = (listKey, id) => {
    setFormData((prev) => {
      const ids = prev[listKey].includes(id)
        ? prev[listKey].filter((v) => v !== id)
        : [...prev[listKey], id];
      return { ...prev, [listKey]: ids };
    });
  };

  const resetForm = () => {
    setFormData({
      title: '', content: '', priority: 'normal', publish_date: '', expire_date: '',
      targetType: 'all', parent_ids: [], child_ids: [],
    });
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    const publish = submitAction.current;
    const payload = {
      title: formData.title,
      content: formData.content,
      priority: formData.priority,
      publish_date: formData.publish_date || null,
      expire_date: formData.expire_date || null,
      is_published: publish,
    };
    if (formData.targetType === 'parents' && formData.parent_ids.length > 0) {
      payload.parent_ids = formData.parent_ids;
    }
    if (formData.targetType === 'children' && formData.child_ids.length > 0) {
      payload.child_ids = formData.child_ids;
    }
    try {
      await announcementsAPI.create(payload);
      setShowModal(false);
      resetForm();
      loadAnnouncements();
    } catch (error) {
      alert(error.response?.data?.message || t('Gagal membuat pengumuman.'));
    }
  };

  const handleDelete = async (id) => {
    if (confirm(t('Yakin ingin menghapus pengumuman ini?'))) {
      try { await announcementsAPI.delete(id); loadAnnouncements(); } catch { alert(t('Gagal menghapus.')); }
    }
  };

  const priorityConfig = {
    low: { label: t('Rendah'), color: 'var(--color-text-muted)', bg: 'var(--color-bg-alt)' },
    normal: { label: t('Normal'), color: 'var(--color-info)', bg: 'var(--color-info-bg)' },
    high: { label: t('Tinggi'), color: 'var(--color-warning)', bg: 'var(--color-warning-bg)' },
    urgent: { label: t('Mendesak'), color: 'var(--color-error)', bg: 'var(--color-error-bg)' },
  };

  if (loading) return <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'center', height: '300px' }}><div className="tc-spinner"></div></div>;

  return (
    <div>
      <PageHeader title={t('Manajemen Pengumuman')} subtitle={t('Buat dan kelola pengumuman untuk orang tua')} action={<button onClick={() => setShowModal(true)} className="tc-btn tc-btn-primary">{t('+ Buat Pengumuman')}</button>} />

      {error && (
        <div className="tc-error-state" style={{ marginBottom: '16px' }}>
          <p className="tc-empty-state-title">{error}</p>
          <button onClick={() => { setError(''); loadAnnouncements(); }} className="tc-btn tc-btn-secondary tc-btn-sm" style={{ marginTop: '12px' }}>{t('Coba Lagi')}</button>
        </div>
      )}

      <div style={{ display: 'flex', flexDirection: 'column', gap: '12px' }}>
        {announcements.map((item) => {
          const priority = priorityConfig[item.priority] || priorityConfig.normal;
          const isBroadcast = !item.children?.length && !item.parents?.length;
          return (
            <div key={item.id} className="tc-card" style={{ padding: '20px' }}>
              <div style={{ display: 'flex', alignItems: 'flex-start', justifyContent: 'space-between' }}>
                <div style={{ flex: 1 }}>
                  <div style={{ display: 'flex', alignItems: 'center', gap: '8px', marginBottom: '6px', flexWrap: 'wrap' }}>
                    <h3 style={{ fontSize: '15px', fontWeight: '600' }}>{item.title}</h3>
                    <span className="tc-badge" style={{ background: priority.bg, color: priority.color }}>{priority.label}</span>
                    {item.is_published ? (
                      <span className="tc-badge tc-badge-success">Published</span>
                    ) : (
                      <span className="tc-badge tc-badge-info">Draft</span>
                    )}
                  </div>
                  <p style={{ fontSize: '13px', color: 'var(--color-text-secondary)', marginBottom: '8px', lineHeight: '1.5' }}>{item.content}</p>
                  <div style={{ display: 'flex', gap: '16px', fontSize: '12px', color: 'var(--color-text-muted)' }}>
                    {item.publish_date && <span>{t('Publish: {{date}}', { date: new Date(item.publish_date).toLocaleDateString('id-ID') })}</span>}
                    {item.expire_date && <span>{t('Berakhir: {{date}}', { date: new Date(item.expire_date).toLocaleDateString('id-ID') })}</span>}
                  </div>
                  {!isBroadcast && (
                    <div style={{ marginTop: '8px', display: 'flex', alignItems: 'center', gap: '6px', flexWrap: 'wrap' }}>
                      <span style={{ fontSize: '12px', color: 'var(--color-text-muted)' }}>{t('Target:')}</span>
                      {item.parents?.map((p) => (
                        <span key={p.id} className="tc-badge tc-badge-warning">{p.user?.name || p.user?.email || t('Orang Tua #{{id}}', { id: p.id })}</span>
                      ))}
                      {item.children?.map((c) => (
                        <span key={c.id} className="tc-badge tc-badge-info">{c.name}</span>
                      ))}
                    </div>
                  )}
                  {isBroadcast && (
                    <p style={{ marginTop: '8px', fontSize: '12px', color: 'var(--color-text-muted)' }}>{t('Dikirim ke seluruh orang tua')}</p>
                  )}
                </div>
                <button onClick={() => handleDelete(item.id)} style={{ border: 'none', background: 'none', color: 'var(--color-text-muted)', cursor: 'pointer', padding: '4px' }}>✕</button>
              </div>
            </div>
          );
        })}
      </div>

      {announcements.length === 0 && <EmptyState icon="📢" title={t('Belum ada pengumuman')} description={t("Klik 'Buat Pengumuman' untuk menambahkan.")} />}

      <Modal open={showModal} onClose={() => { setShowModal(false); resetForm(); }} title={t('Buat Pengumuman Baru')}>
        <form onSubmit={handleSubmit}>
          <div style={{ display: 'flex', flexDirection: 'column', gap: '14px' }}>
            <div>
              <label className="tc-label">{t('Judul *')}</label>
              <input type="text" value={formData.title} onChange={(e) => setFormData({ ...formData, title: e.target.value })} className="tc-input" required />
            </div>
            <div>
              <label className="tc-label">{t('Isi Pengumuman *')}</label>
              <textarea value={formData.content} onChange={(e) => setFormData({ ...formData, content: e.target.value })} className="tc-input" rows="4" required />
            </div>
            <div>
              <label className="tc-label">{t('Prioritas')}</label>
              <div style={{ display: 'grid', gridTemplateColumns: 'repeat(4, 1fr)', gap: '8px' }}>
                {Object.entries(priorityConfig).map(([key, config]) => (
                  <button key={key} type="button" onClick={() => setFormData({ ...formData, priority: key })} style={{
                    padding: '8px', borderRadius: 'var(--radius-md)', border: `2px solid ${formData.priority === key ? 'var(--color-primary)' : 'var(--color-border)'}`,
                    background: formData.priority === key ? 'var(--color-primary-lighter)' : 'transparent', cursor: 'pointer', textAlign: 'center', fontSize: '12px', color: 'var(--color-text)',
                  }}>
                    {config.label}
                  </button>
                ))}
              </div>
            </div>
            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '14px' }}>
              <div>
                <label className="tc-label">{t('Tanggal Publish')}</label>
                <input type="date" value={formData.publish_date} onChange={(e) => setFormData({ ...formData, publish_date: e.target.value })} className="tc-input" />
              </div>
              <div>
                <label className="tc-label">{t('Tanggal Berakhir')}</label>
                <input type="date" value={formData.expire_date} onChange={(e) => setFormData({ ...formData, expire_date: e.target.value })} className="tc-input" />
              </div>
            </div>
            <div>
              <label className="tc-label">{t('Target Penerima')}</label>
              <div style={{ display: 'flex', flexDirection: 'column', gap: '8px', fontSize: '13px' }}>
                <label style={{ display: 'flex', alignItems: 'center', gap: '8px', cursor: 'pointer' }}>
                  <input type="radio" name="targetType" checked={formData.targetType === 'all'} onChange={() => setFormData({ ...formData, targetType: 'all' })} style={{ accentColor: 'var(--color-primary)' }} />
                  {t('Semua Orang Tua')}
                </label>
                <label style={{ display: 'flex', alignItems: 'center', gap: '8px', cursor: 'pointer' }}>
                  <input type="radio" name="targetType" checked={formData.targetType === 'parents'} onChange={() => setFormData({ ...formData, targetType: 'parents' })} style={{ accentColor: 'var(--color-primary)' }} />
                  {t('Orang Tua tertentu')}
                </label>
                <label style={{ display: 'flex', alignItems: 'center', gap: '8px', cursor: 'pointer' }}>
                  <input type="radio" name="targetType" checked={formData.targetType === 'children'} onChange={() => setFormData({ ...formData, targetType: 'children' })} style={{ accentColor: 'var(--color-primary)' }} />
                  {t('Anak tertentu')}
                </label>
              </div>

              {formData.targetType === 'parents' && (
                <div style={{ marginTop: '10px' }}>
                  <p style={{ fontSize: '12px', color: 'var(--color-text-muted)', marginBottom: '8px' }}>
                    {t('Hanya orang tua yang dipilih yang menerima pengumuman, notifikasi, dan push.')}
                  </p>
                  {parents.length > 0 ? (
                    <div style={{ display: 'flex', flexDirection: 'column', gap: '6px', maxHeight: '180px', overflowY: 'auto', border: '1px solid var(--color-border)', borderRadius: 'var(--radius-md)', padding: '10px' }}>
                      {parents.map((parent) => (
                        <label key={parent.id} style={{ display: 'flex', alignItems: 'center', gap: '8px', fontSize: '13px', cursor: 'pointer' }}>
                          <input type="checkbox" checked={formData.parent_ids.includes(parent.id)} onChange={() => toggleId('parent_ids', parent.id)} style={{ accentColor: 'var(--color-primary)' }} />
                          {parent.user?.name || parent.user?.email || t('Orang Tua #{{id}}', { id: parent.id })}
                          <span style={{ color: 'var(--color-text-muted)', fontSize: '12px' }}>{parent.user?.email || ''}</span>
                        </label>
                      ))}
                    </div>
                  ) : (
                    <p style={{ fontSize: '12px', color: 'var(--color-text-muted)' }}>{t('Tidak ada orang tua terdaftar.')}</p>
                  )}
                </div>
              )}

              {formData.targetType === 'children' && (
                <div style={{ marginTop: '10px' }}>
                  <p style={{ fontSize: '12px', color: 'var(--color-text-muted)', marginBottom: '8px' }}>
                    {t('Pengumuman dikirim ke orang tua dari anak yang dipilih.')}
                  </p>
                  {children.length > 0 ? (
                    <div style={{ display: 'flex', flexDirection: 'column', gap: '6px', maxHeight: '180px', overflowY: 'auto', border: '1px solid var(--color-border)', borderRadius: 'var(--radius-md)', padding: '10px' }}>
                      {children.map((child) => (
                        <label key={child.id} style={{ display: 'flex', alignItems: 'center', gap: '8px', fontSize: '13px', cursor: 'pointer' }}>
                          <input type="checkbox" checked={formData.child_ids.includes(child.id)} onChange={() => toggleId('child_ids', child.id)} style={{ accentColor: 'var(--color-primary)' }} />
                          {child.name}
                          <span style={{ color: 'var(--color-text-muted)', fontSize: '12px' }}>{child.gender === 'male' ? t('Laki-laki') : t('Perempuan')}</span>
                        </label>
                      ))}
                    </div>
                  ) : (
                    <p style={{ fontSize: '12px', color: 'var(--color-text-muted)' }}>{t("Tidak ada anak — pilih 'Semua Orang Tua'.")}</p>
                  )}
                </div>
              )}
            </div>
            <div style={{
              padding: '12px 14px', borderRadius: 'var(--radius-md)',
              background: 'var(--color-info-bg)', fontSize: '12px', color: 'var(--color-text-secondary)',
            }}>
              <strong>{t('Publish + Kirim')}</strong> {t('langsung menampilkan pengumuman dan mengirim notifikasi + push ke target.')}
              <strong> {t('Simpan Draft')}</strong> {t('hanya menyimpan sebagai draft tanpa mengirim apa pun.')}
            </div>
          </div>
          <div style={{ display: 'flex', gap: '10px', marginTop: '20px' }}>
            <button type="button" onClick={() => { setShowModal(false); resetForm(); }} className="tc-btn tc-btn-secondary" style={{ flex: 1 }}>{t('Batal')}</button>
            <button
              type="submit"
              className="tc-btn tc-btn-secondary"
              style={{ flex: 1 }}
              onClick={() => { submitAction.current = false; }}
            >
              {t('Simpan Draft')}
            </button>
            <button
              type="submit"
              className="tc-btn tc-btn-primary"
              style={{ flex: 1 }}
              onClick={() => { submitAction.current = true; }}
            >
              {t('Publish + Kirim')}
            </button>
          </div>
        </form>
      </Modal>
    </div>
  );
}