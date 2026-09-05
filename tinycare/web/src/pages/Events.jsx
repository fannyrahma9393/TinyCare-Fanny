import { useState, useEffect } from 'react';
import { eventsAPI } from '../services/api';
import { PageHeader, Modal, EmptyState } from '../components/PageHeader';

export default function Events() {
  const [events, setEvents] = useState([]);
  const [loading, setLoading] = useState(true);
  const [showModal, setShowModal] = useState(false);
  const [formData, setFormData] = useState({ title: '', description: '', date: '', start_time: '', end_time: '', location: '', type: 'activity', status: 'scheduled' });
  const [error, setError] = useState('');

  async function loadEvents() {
    try { const res = await eventsAPI.list(); setEvents(res.data.data.data || []); }
    catch (error) { setError(error.response?.data?.message || 'Gagal memuat data jadwal.'); } finally { setLoading(false); }
  }

  useEffect(() => { loadEvents(); }, []);

  const handleSubmit = async (e) => {
    e.preventDefault();
    try { await eventsAPI.create(formData); setShowModal(false); setFormData({ title: '', description: '', date: '', start_time: '', end_time: '', location: '', type: 'activity', status: 'scheduled' }); loadEvents(); }
    catch (error) { alert(error.response?.data?.message || 'Gagal membuat event.'); }
  };

  const handleDelete = async (id) => {
    if (confirm('Yakin ingin menghapus event ini?')) {
      try { await eventsAPI.delete(id); loadEvents(); } catch { alert('Gagal menghapus event.'); }
    }
  };

  const typeConfig = {
    activity: { label: 'Kegiatan', color: 'var(--color-info)', bg: 'var(--color-info-bg)' },
    holiday: { label: 'Libur', color: 'var(--color-warning)', bg: 'var(--color-warning-bg)' },
    special: { label: 'Khusus', color: '#8b6fc0', bg: '#f3eef9' },
    meeting: { label: 'Meeting', color: 'var(--color-success)', bg: 'var(--color-success-bg)' },
  };
  const statusConfig = {
    scheduled: { label: 'Terjadwal', color: 'var(--color-info)', bg: 'var(--color-info-bg)' },
    ongoing: { label: 'Berlangsung', color: 'var(--color-warning)', bg: 'var(--color-warning-bg)' },
    completed: { label: 'Selesai', color: 'var(--color-success)', bg: 'var(--color-success-bg)' },
    cancelled: { label: 'Dibatalkan', color: 'var(--color-text-muted)', bg: 'var(--color-bg-alt)' },
  };

  if (loading) return <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'center', height: '300px' }}><div className="tc-spinner"></div></div>;

  return (
    <div>
      <PageHeader title="Manajemen Jadwal" subtitle="Kelola jadwal dan event daycare" action={<button onClick={() => setShowModal(true)} className="tc-btn tc-btn-primary">+ Buat Jadwal</button>} />

      {error && (
        <div className="tc-error-state" style={{ marginBottom: '16px' }}>
          <p className="tc-empty-state-title">{error}</p>
          <button onClick={() => { setError(''); loadEvents(); }} className="tc-btn tc-btn-secondary tc-btn-sm" style={{ marginTop: '12px' }}>Coba Lagi</button>
        </div>
      )}

      <div style={{ display: 'flex', flexDirection: 'column', gap: '12px' }}>
        {events.map((event) => {
          const type = typeConfig[event.type] || typeConfig.activity;
          const status = statusConfig[event.status] || statusConfig.scheduled;
          return (
            <div key={event.id} className="tc-card" style={{ padding: '20px' }}>
              <div style={{ display: 'flex', alignItems: 'flex-start', justifyContent: 'space-between' }}>
                <div style={{ flex: 1 }}>
                  <div style={{ display: 'flex', alignItems: 'center', gap: '8px', marginBottom: '6px', flexWrap: 'wrap' }}>
                    <h3 style={{ fontSize: '15px', fontWeight: '600' }}>{event.title}</h3>
                    <span className="tc-badge" style={{ background: type.bg, color: type.color }}>{type.label}</span>
                    <span className="tc-badge" style={{ background: status.bg, color: status.color }}>{status.label}</span>
                  </div>
                  {event.description && <p style={{ fontSize: '13px', color: 'var(--color-text-secondary)', marginBottom: '8px', lineHeight: '1.5' }}>{event.description}</p>}
                  <div style={{ display: 'flex', gap: '16px', fontSize: '12px', color: 'var(--color-text-muted)' }}>
                    <span>📅 {event.date}</span>
                    {event.start_time && <span>🕐 {event.start_time} - {event.end_time || '-'}</span>}
                    {event.location && <span>📍 {event.location}</span>}
                  </div>
                </div>
                <button onClick={() => handleDelete(event.id)} style={{ border: 'none', background: 'none', color: 'var(--color-text-muted)', cursor: 'pointer', padding: '4px' }}>✕</button>
              </div>
            </div>
          );
        })}
      </div>

      {events.length === 0 && <EmptyState icon="📅" title="Belum ada jadwal" description="Klik 'Buat Jadwal' untuk menambahkan." />}

      <Modal open={showModal} onClose={() => setShowModal(false)} title="Buat Jadwal Baru">
        <form onSubmit={handleSubmit}>
          <div style={{ display: 'flex', flexDirection: 'column', gap: '14px' }}>
            <div>
              <label className="tc-label">Judul *</label>
              <input type="text" value={formData.title} onChange={(e) => setFormData({ ...formData, title: e.target.value })} className="tc-input" required />
            </div>
            <div>
              <label className="tc-label">Deskripsi</label>
              <textarea value={formData.description} onChange={(e) => setFormData({ ...formData, description: e.target.value })} className="tc-input" rows="2" />
            </div>
            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr 1fr', gap: '14px' }}>
              <div>
                <label className="tc-label">Tanggal *</label>
                <input type="date" value={formData.date} onChange={(e) => setFormData({ ...formData, date: e.target.value })} className="tc-input" required />
              </div>
              <div>
                <label className="tc-label">Jam Mulai</label>
                <input type="time" value={formData.start_time} onChange={(e) => setFormData({ ...formData, start_time: e.target.value })} className="tc-input" />
              </div>
              <div>
                <label className="tc-label">Jam Selesai</label>
                <input type="time" value={formData.end_time} onChange={(e) => setFormData({ ...formData, end_time: e.target.value })} className="tc-input" />
              </div>
            </div>
            <div>
              <label className="tc-label">Lokasi</label>
              <input type="text" value={formData.location} onChange={(e) => setFormData({ ...formData, location: e.target.value })} className="tc-input" placeholder="Lokasi acara" />
            </div>
            <div>
              <label className="tc-label">Tipe</label>
              <div style={{ display: 'grid', gridTemplateColumns: 'repeat(4, 1fr)', gap: '8px' }}>
                {Object.entries(typeConfig).map(([key, config]) => (
                  <button key={key} type="button" onClick={() => setFormData({ ...formData, type: key })} style={{
                    padding: '8px', borderRadius: 'var(--radius-md)', border: `2px solid ${formData.type === key ? 'var(--color-primary)' : 'var(--color-border)'}`,
                    background: formData.type === key ? 'var(--color-primary-lighter)' : 'transparent', cursor: 'pointer', textAlign: 'center', fontSize: '12px', color: 'var(--color-text)',
                  }}>
                    {config.label}
                  </button>
                ))}
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
