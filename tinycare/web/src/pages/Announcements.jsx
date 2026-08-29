import { useState, useEffect } from 'react';
import { announcementsAPI } from '../services/api';
import { PageHeader, Modal, EmptyState } from '../components/PageHeader';

export default function Announcements() {
  const [announcements, setAnnouncements] = useState([]);
  const [loading, setLoading] = useState(true);
  const [showModal, setShowModal] = useState(false);
  const [formData, setFormData] = useState({ title: '', content: '', priority: 'normal', publish_date: '', expire_date: '', is_published: true });

  async function loadAnnouncements() {
    try { const res = await announcementsAPI.list(); setAnnouncements(res.data.data.data || []); }
    catch (error) { console.error('Error:', error); } finally { setLoading(false); }
  }

  useEffect(() => { loadAnnouncements(); }, []);

  const handleSubmit = async (e) => {
    e.preventDefault();
    try { await announcementsAPI.create(formData); setShowModal(false); setFormData({ title: '', content: '', priority: 'normal', publish_date: '', expire_date: '', is_published: true }); loadAnnouncements(); }
    catch (error) { alert(error.response?.data?.message || 'Gagal membuat pengumuman.'); }
  };

  const handleDelete = async (id) => {
    if (confirm('Yakin ingin menghapus pengumuman ini?')) {
      try { await announcementsAPI.delete(id); loadAnnouncements(); } catch { alert('Gagal menghapus.'); }
    }
  };

  const priorityConfig = {
    low: { label: 'Rendah', color: 'var(--color-text-muted)', bg: 'var(--color-bg-alt)' },
    normal: { label: 'Normal', color: 'var(--color-info)', bg: 'var(--color-info-bg)' },
    high: { label: 'Tinggi', color: 'var(--color-warning)', bg: 'var(--color-warning-bg)' },
    urgent: { label: 'Mendesak', color: 'var(--color-error)', bg: 'var(--color-error-bg)' },
  };

  if (loading) return <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'center', height: '300px' }}><div className="tc-spinner"></div></div>;

  return (
    <div>
      <PageHeader title="Manajemen Pengumuman" subtitle="Buat dan kelola pengumuman untuk orang tua" action={<button onClick={() => setShowModal(true)} className="tc-btn tc-btn-primary">+ Buat Pengumuman</button>} />

      <div style={{ display: 'flex', flexDirection: 'column', gap: '12px' }}>
        {announcements.map((item) => {
          const priority = priorityConfig[item.priority] || priorityConfig.normal;
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
                    {item.publish_date && <span>Publish: {new Date(item.publish_date).toLocaleDateString('id-ID')}</span>}
                    {item.expire_date && <span>Berakhir: {new Date(item.expire_date).toLocaleDateString('id-ID')}</span>}
                  </div>
                </div>
                <button onClick={() => handleDelete(item.id)} style={{ border: 'none', background: 'none', color: 'var(--color-text-muted)', cursor: 'pointer', padding: '4px' }}>✕</button>
              </div>
            </div>
          );
        })}
      </div>

      {announcements.length === 0 && <EmptyState icon="📢" title="Belum ada pengumuman" description="Klik 'Buat Pengumuman' untuk menambahkan." />}

      <Modal open={showModal} onClose={() => setShowModal(false)} title="Buat Pengumuman Baru">
        <form onSubmit={handleSubmit}>
          <div style={{ display: 'flex', flexDirection: 'column', gap: '14px' }}>
            <div>
              <label className="tc-label">Judul *</label>
              <input type="text" value={formData.title} onChange={(e) => setFormData({ ...formData, title: e.target.value })} className="tc-input" required />
            </div>
            <div>
              <label className="tc-label">Isi Pengumuman *</label>
              <textarea value={formData.content} onChange={(e) => setFormData({ ...formData, content: e.target.value })} className="tc-input" rows="4" required />
            </div>
            <div>
              <label className="tc-label">Prioritas</label>
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
                <label className="tc-label">Tanggal Publish</label>
                <input type="date" value={formData.publish_date} onChange={(e) => setFormData({ ...formData, publish_date: e.target.value })} className="tc-input" />
              </div>
              <div>
                <label className="tc-label">Tanggal Berakhir</label>
                <input type="date" value={formData.expire_date} onChange={(e) => setFormData({ ...formData, expire_date: e.target.value })} className="tc-input" />
              </div>
            </div>
            <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
              <input type="checkbox" id="is_published" checked={formData.is_published} onChange={(e) => setFormData({ ...formData, is_published: e.target.checked })} style={{ accentColor: 'var(--color-primary)' }} />
              <label htmlFor="is_published" style={{ fontSize: '13px', color: 'var(--color-text-secondary)' }}>Langsung publish</label>
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
