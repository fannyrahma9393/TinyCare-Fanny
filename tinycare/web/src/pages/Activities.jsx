import { useState, useEffect } from 'react';
import { activitiesAPI, childrenAPI } from '../services/api';
import { PageHeader, Modal, EmptyState } from '../components/PageHeader';

export default function Activities() {
  const [activities, setActivities] = useState([]);
  const [children, setChildren] = useState([]);
  const [loading, setLoading] = useState(true);
  const [activeTab, setActiveTab] = useState('master');
  const [showModal, setShowModal] = useState(false);
  const [showChildModal, setShowChildModal] = useState(false);
  const [formData, setFormData] = useState({ name: '', description: '', category: 'bermain' });
  const [childActivityData, setChildActivityData] = useState({ child_id: '', activity_id: '', date: '', time: '', notes: '' });

  async function loadActivities() {
    try { const res = await activitiesAPI.list(); setActivities(res.data.data.data || []); }
    catch (error) { console.error('Error:', error); } finally { setLoading(false); }
  }
  async function loadChildren() {
    try { const res = await childrenAPI.list({ per_page: 100 }); setChildren(res.data.data.data || []); }
    catch (error) { console.error('Error:', error); }
  }

  useEffect(() => { loadActivities(); loadChildren(); }, []);

  const handleCreateActivity = async (e) => {
    e.preventDefault();
    try { await activitiesAPI.create(formData); setShowModal(false); setFormData({ name: '', description: '', category: 'bermain' }); loadActivities(); }
    catch (error) { alert(error.response?.data?.message || 'Gagal menambahkan aktivitas.'); }
  };

  const handleAddChildActivity = async (e) => {
    e.preventDefault();
    try { await activitiesAPI.addChildActivity(childActivityData.child_id, childActivityData); setShowChildModal(false); setChildActivityData({ child_id: '', activity_id: '', date: '', time: '', notes: '' }); alert('Aktivitas anak berhasil dicatat!'); }
    catch (error) { alert(error.response?.data?.message || 'Gagal mencatat aktivitas anak.'); }
  };

  const handleDelete = async (id) => {
    if (confirm('Yakin ingin menghapus aktivitas ini?')) {
      try { await activitiesAPI.delete(id); loadActivities(); } catch { alert('Gagal menghapus aktivitas.'); }
    }
  };

  const categoryConfig = {
    edukasi: { label: 'Edukasi', color: 'var(--color-info)', bg: 'var(--color-info-bg)' },
    bermain: { label: 'Bermain', color: 'var(--color-success)', bg: 'var(--color-success-bg)' },
    olahraga: { label: 'Olahraga', color: 'var(--color-warning)', bg: 'var(--color-warning-bg)' },
    seni: { label: 'Seni', color: '#8b6fc0', bg: '#f3eef9' },
    makan: { label: 'Makan', color: 'var(--color-accent)', bg: 'var(--color-accent-light)' },
    istirahat: { label: 'Istirahat', color: 'var(--color-text-muted)', bg: 'var(--color-bg-alt)' },
  };

  if (loading) return <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'center', height: '300px' }}><div className="tc-spinner"></div></div>;

  return (
    <div>
      <PageHeader
        title="Manajemen Aktivitas"
        subtitle="Kelola aktivitas dan catatan aktivitas anak"
        action={
          <button onClick={() => activeTab === 'master' ? setShowModal(true) : setShowChildModal(true)} className="tc-btn tc-btn-primary">
            + {activeTab === 'master' ? 'Tambah Aktivitas' : 'Catat Aktivitas Anak'}
          </button>
        }
      />

      <div style={{ display: 'flex', gap: '6px', marginBottom: '20px' }}>
        <button onClick={() => setActiveTab('master')} className={activeTab === 'master' ? 'tc-btn tc-btn-primary' : 'tc-btn tc-btn-secondary'} style={{ padding: '7px 14px', fontSize: '13px' }}>Master Aktivitas</button>
        <button onClick={() => setActiveTab('child')} className={activeTab === 'child' ? 'tc-btn tc-btn-primary' : 'tc-btn tc-btn-secondary'} style={{ padding: '7px 14px', fontSize: '13px' }}>Aktivitas Anak</button>
      </div>

      {activeTab === 'master' ? (
        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(260px, 1fr))', gap: '12px' }}>
          {activities.map((a) => {
            const cat = categoryConfig[a.category] || categoryConfig.bermain;
            return (
              <div key={a.id} className="tc-card" style={{ padding: '16px' }}>
                <div style={{ display: 'flex', alignItems: 'flex-start', justifyContent: 'space-between' }}>
                  <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
                    <div style={{ width: '36px', height: '36px', borderRadius: '8px', background: cat.bg, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                      <div style={{ width: '10px', height: '10px', borderRadius: '2px', background: cat.color }} />
                    </div>
                    <div>
                      <p style={{ fontSize: '13px', fontWeight: '600' }}>{a.name}</p>
                      <p style={{ fontSize: '11px', color: 'var(--color-text-muted)' }}>{cat.label}</p>
                    </div>
                  </div>
                  <button onClick={() => handleDelete(a.id)} style={{ border: 'none', background: 'none', color: 'var(--color-text-muted)', cursor: 'pointer', padding: '4px' }}>✕</button>
                </div>
                {a.description && <p style={{ fontSize: '12px', color: 'var(--color-text-secondary)', marginTop: '8px' }}>{a.description}</p>}
              </div>
            );
          })}
          {activities.length === 0 && <EmptyState icon="🎨" title="Belum ada aktivitas" description="Klik 'Tambah Aktivitas' untuk menambahkan." />}
        </div>
      ) : (
        <div className="tc-card" style={{ padding: '24px' }}>
          <h2 style={{ fontSize: '15px', fontWeight: '600', marginBottom: '16px' }}>Kategori Aktivitas</h2>
          <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(160px, 1fr))', gap: '12px' }}>
            {Object.entries(categoryConfig).map(([key, config]) => {
              const count = activities.filter(a => a.category === key).length;
              return (
                <div key={key} style={{ background: config.bg, borderRadius: 'var(--radius-md)', padding: '16px', textAlign: 'center' }}>
                  <div style={{ width: '40px', height: '40px', borderRadius: '10px', background: `${config.color}20`, display: 'flex', alignItems: 'center', justifyContent: 'center', margin: '0 auto 8px' }}>
                    <div style={{ width: '12px', height: '12px', borderRadius: '3px', background: config.color }} />
                  </div>
                  <p style={{ fontSize: '13px', fontWeight: '600' }}>{config.label}</p>
                  <p style={{ fontSize: '11px', color: 'var(--color-text-muted)' }}>{count} aktivitas</p>
                </div>
              );
            })}
          </div>
        </div>
      )}

      <Modal open={showModal} onClose={() => setShowModal(false)} title="Tambah Aktivitas Baru">
        <form onSubmit={handleCreateActivity}>
          <div style={{ display: 'flex', flexDirection: 'column', gap: '14px' }}>
            <div>
              <label className="tc-label">Nama Aktivitas *</label>
              <input type="text" value={formData.name} onChange={(e) => setFormData({ ...formData, name: e.target.value })} className="tc-input" required />
            </div>
            <div>
              <label className="tc-label">Deskripsi</label>
              <textarea value={formData.description} onChange={(e) => setFormData({ ...formData, description: e.target.value })} className="tc-input" rows="2" />
            </div>
            <div>
              <label className="tc-label">Kategori *</label>
              <div style={{ display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)', gap: '8px' }}>
                {Object.entries(categoryConfig).map(([key, config]) => (
                  <button key={key} type="button" onClick={() => setFormData({ ...formData, category: key })} style={{
                    padding: '10px', borderRadius: 'var(--radius-md)', border: `2px solid ${formData.category === key ? 'var(--color-primary)' : 'var(--color-border)'}`,
                    background: formData.category === key ? 'var(--color-primary-lighter)' : 'transparent', cursor: 'pointer', textAlign: 'center', fontSize: '12px', color: 'var(--color-text)',
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

      <Modal open={showChildModal} onClose={() => setShowChildModal(false)} title="Catat Aktivitas Anak">
        <form onSubmit={handleAddChildActivity}>
          <div style={{ display: 'flex', flexDirection: 'column', gap: '14px' }}>
            <div>
              <label className="tc-label">Anak *</label>
              <select value={childActivityData.child_id} onChange={(e) => setChildActivityData({ ...childActivityData, child_id: e.target.value })} className="tc-select" required>
                <option value="">-- Pilih Anak --</option>
                {children.map((c) => <option key={c.id} value={c.id}>{c.name}</option>)}
              </select>
            </div>
            <div>
              <label className="tc-label">Aktivitas *</label>
              <select value={childActivityData.activity_id} onChange={(e) => setChildActivityData({ ...childActivityData, activity_id: e.target.value })} className="tc-select" required>
                <option value="">-- Pilih Aktivitas --</option>
                {activities.map((a) => <option key={a.id} value={a.id}>{a.name}</option>)}
              </select>
            </div>
            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '14px' }}>
              <div>
                <label className="tc-label">Tanggal *</label>
                <input type="date" value={childActivityData.date} onChange={(e) => setChildActivityData({ ...childActivityData, date: e.target.value })} className="tc-input" required />
              </div>
              <div>
                <label className="tc-label">Waktu</label>
                <input type="time" value={childActivityData.time} onChange={(e) => setChildActivityData({ ...childActivityData, time: e.target.value })} className="tc-input" />
              </div>
            </div>
            <div>
              <label className="tc-label">Catatan</label>
              <textarea value={childActivityData.notes} onChange={(e) => setChildActivityData({ ...childActivityData, notes: e.target.value })} className="tc-input" rows="2" />
            </div>
          </div>
          <div style={{ display: 'flex', gap: '10px', marginTop: '20px' }}>
            <button type="button" onClick={() => setShowChildModal(false)} className="tc-btn tc-btn-secondary" style={{ flex: 1 }}>Batal</button>
            <button type="submit" className="tc-btn tc-btn-primary" style={{ flex: 1 }}>Simpan</button>
          </div>
        </form>
      </Modal>
    </div>
  );
}
