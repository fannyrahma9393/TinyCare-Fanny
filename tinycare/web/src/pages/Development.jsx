import { useState, useEffect } from 'react';
import { developmentAPI, childrenAPI } from '../services/api';
import { PageHeader, Modal, EmptyState } from '../components/PageHeader';

export default function Development() {
  const [categories, setCategories] = useState([]);
  const [children, setChildren] = useState([]);
  const [loading, setLoading] = useState(true);
  const [selectedChild, setSelectedChild] = useState('');
  const [childDevelopment, setChildDevelopment] = useState(null);
  const [loadingDevelopment, setLoadingDevelopment] = useState(false);
  const [showAssessmentModal, setShowAssessmentModal] = useState(false);
  const [submitting, setSubmitting] = useState(false);
  const [error, setError] = useState('');
  const [success, setSuccess] = useState('');
  const [formData, setFormData] = useState({ development_category_id: '', indicator: '', notes: '', progress: 'belum', observation_date: new Date().toISOString().split('T')[0] });

  async function loadCategories() { try { const res = await developmentAPI.categories(); setCategories(res.data.data || []); } catch (e) { console.error(e); } }
  async function loadChildren() { try { const res = await childrenAPI.list({ per_page: 100 }); setChildren(res.data.data.data || []); } catch (e) { console.error(e); } }
  async function loadChildDevelopment() {
    setLoadingDevelopment(true); setError('');
    try { const res = await developmentAPI.childDevelopment(selectedChild); setChildDevelopment(res.data.data); }
    catch (err) { setError(err.response?.data?.message || 'Gagal memuat data.'); setChildDevelopment(null); }
    finally { setLoadingDevelopment(false); }
  }

  useEffect(() => { Promise.all([loadCategories(), loadChildren()]).finally(() => setLoading(false)); }, []);
  useEffect(() => { if (selectedChild) loadChildDevelopment(); else setChildDevelopment(null); }, [selectedChild]);

  const handleAddAssessment = async (e) => {
    e.preventDefault(); setSubmitting(true); setError('');
    try {
      await developmentAPI.addAssessment(selectedChild, formData);
      setSuccess('Penilaian berhasil disimpan.'); setShowAssessmentModal(false);
      setFormData({ development_category_id: '', indicator: '', notes: '', progress: 'belum', observation_date: new Date().toISOString().split('T')[0] });
      loadChildDevelopment(); setTimeout(() => setSuccess(''), 3000);
    } catch (err) {
      if (err.response?.status === 422) { const errors = err.response.data.errors; if (errors) { const first = Object.values(errors)[0]; setError(Array.isArray(first) ? first[0] : first); } else { setError(err.response.data.message || 'Data tidak valid.'); } }
      else { setError(err.response?.data?.message || 'Gagal menyimpan.'); }
    } finally { setSubmitting(false); }
  };

  const handleDeleteAssessment = async (id) => {
    if (!confirm('Yakin ingin menghapus penilaian ini?')) return;
    try { await developmentAPI.deleteAssessment(id); setSuccess('Penilaian berhasil dihapus.'); loadChildDevelopment(); setTimeout(() => setSuccess(''), 3000); }
    catch (err) { alert(err.response?.data?.message || 'Gagal menghapus.'); }
  };

  const categoryIcons = { motorik: '🏃', bahasa: '💬', sosial: '👫', kognitif: '🧠', kemandirian: '💪' };
  const progressConfig = {
    belum: { label: 'Belum', color: 'var(--color-text-muted)', bg: 'var(--color-bg-alt)' },
    mulai: { label: 'Mulai', color: 'var(--color-warning)', bg: 'var(--color-warning-bg)' },
    berkembang: { label: 'Berkembang', color: 'var(--color-accent)', bg: 'var(--color-accent-light)' },
    baik: { label: 'Baik', color: 'var(--color-success)', bg: 'var(--color-success-bg)' },
    sangat_baik: { label: 'Sangat Baik', color: 'var(--color-primary-dark)', bg: 'var(--color-primary-lighter)' },
  };

  if (loading) return <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'center', height: '300px' }}><div className="tc-spinner"></div></div>;

  return (
    <div>
      <PageHeader
        title="Perkembangan Anak"
        subtitle="Pantau dan catat perkembangan anak per kategori"
        action={
          <div style={{ display: 'flex', gap: '10px', alignItems: 'center' }}>
            <select value={selectedChild} onChange={(e) => setSelectedChild(e.target.value)} className="tc-select" style={{ width: '200px' }}>
              <option value="">-- Pilih Anak --</option>
              {children.map((c) => <option key={c.id} value={c.id}>{c.name}</option>)}
            </select>
            {selectedChild && <button onClick={() => { setError(''); setSuccess(''); setShowAssessmentModal(true); }} className="tc-btn tc-btn-primary">+ Tambah Penilaian</button>}
          </div>
        }
      />

      {success && <div style={{ padding: '10px 14px', background: 'var(--color-success-bg)', border: '1px solid var(--color-success)', borderRadius: 'var(--radius-md)', color: 'var(--color-success)', fontSize: '13px', marginBottom: '16px' }}>{success}</div>}
      {error && !showAssessmentModal && <div style={{ padding: '10px 14px', background: 'var(--color-error-bg)', border: '1px solid var(--color-error)', borderRadius: 'var(--radius-md)', color: 'var(--color-error)', fontSize: '13px', marginBottom: '16px' }}>{error}</div>}

      {!selectedChild ? (
        <EmptyState icon="📈" title="Pilih anak" description="Gunakan dropdown di atas untuk memilih anak." />
      ) : loadingDevelopment ? (
        <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'center', height: '200px' }}><div className="tc-spinner"></div></div>
      ) : childDevelopment ? (
        <div>
          <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(200px, 1fr))', gap: '12px', marginBottom: '24px' }}>
            {childDevelopment.categories?.map((cat) => {
              const pct = cat.average_progress;
              const barColor = pct >= 75 ? 'var(--color-success)' : pct >= 50 ? 'var(--color-warning)' : pct >= 25 ? 'var(--color-accent)' : 'var(--color-text-muted)';
              return (
                <div key={cat.id} className="tc-card" style={{ padding: '16px' }}>
                  <div style={{ display: 'flex', alignItems: 'center', gap: '8px', marginBottom: '12px' }}>
                    <span style={{ fontSize: '20px' }}>{categoryIcons[cat.name] || '📊'}</span>
                    <h3 style={{ fontSize: '13px', fontWeight: '600', textTransform: 'capitalize' }}>{cat.name}</h3>
                  </div>
                  <div style={{ marginBottom: '8px' }}>
                    <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: '12px', marginBottom: '4px' }}>
                      <span style={{ color: 'var(--color-text-muted)' }}>Progress</span>
                      <span style={{ fontWeight: '600' }}>{pct}%</span>
                    </div>
                    <div style={{ width: '100%', height: '4px', borderRadius: '2px', background: 'var(--color-bg-alt)' }}>
                      <div style={{ height: '4px', borderRadius: '2px', background: barColor, width: `${pct}%`, transition: 'width 0.5s ease' }} />
                    </div>
                  </div>
                  {cat.latest_assessment && <p style={{ fontSize: '11px', color: 'var(--color-text-muted)' }}>Terakhir: <strong>{cat.latest_assessment.progress_label}</strong></p>}
                  <p style={{ fontSize: '11px', color: 'var(--color-text-muted)', marginTop: '4px' }}>{cat.total_assessments} penilaian</p>
                </div>
              );
            })}
          </div>

          <div className="tc-card" style={{ padding: '20px' }}>
            <h2 style={{ fontSize: '14px', fontWeight: '600', marginBottom: '12px' }}>Riwayat Penilaian Terbaru</h2>
            <div style={{ display: 'flex', flexDirection: 'column', gap: '8px' }}>
              {childDevelopment.categories?.flatMap(cat => cat.recent_assessments?.map((a) => (
                <div key={a.id} style={{ display: 'flex', alignItems: 'center', gap: '12px', padding: '10px', borderRadius: 'var(--radius-md)', background: 'var(--color-bg-alt)' }}>
                  <span style={{ fontSize: '16px' }}>{categoryIcons[cat.name] || '📊'}</span>
                  <div style={{ flex: 1, minWidth: 0 }}>
                    <p style={{ fontSize: '13px', fontWeight: '600' }}>{a.indicator}</p>
                    <p style={{ fontSize: '11px', color: 'var(--color-text-muted)', textTransform: 'capitalize' }}>{cat.name} • {a.observation_date}</p>
                  </div>
                  <span className="tc-badge" style={{ background: progressConfig[a.progress]?.bg, color: progressConfig[a.progress]?.color }}>{a.progress_label}</span>
                  <button onClick={() => handleDeleteAssessment(a.id)} style={{ border: 'none', background: 'none', color: 'var(--color-text-muted)', cursor: 'pointer', padding: '4px', fontSize: '12px' }}>✕</button>
                </div>
              ))) || []}
            </div>
          </div>
        </div>
      ) : (
        <EmptyState icon="📊" title="Belum ada data perkembangan" />
      )}

      <Modal open={showAssessmentModal} onClose={() => setShowAssessmentModal(false)} title="Tambah Penilaian Perkembangan">
        {error && <div style={{ padding: '10px 14px', background: 'var(--color-error-bg)', border: '1px solid var(--color-error)', borderRadius: 'var(--radius-md)', color: 'var(--color-error)', fontSize: '13px', marginBottom: '14px' }}>{error}</div>}
        <form onSubmit={handleAddAssessment}>
          <div style={{ display: 'flex', flexDirection: 'column', gap: '14px' }}>
            <div>
              <label className="tc-label">Kategori *</label>
              <select value={formData.development_category_id} onChange={(e) => setFormData({ ...formData, development_category_id: e.target.value })} className="tc-select" required>
                <option value="">-- Pilih Kategori --</option>
                {categories.map((c) => <option key={c.id} value={c.id}>{c.name}</option>)}
              </select>
            </div>
            <div>
              <label className="tc-label">Indikator *</label>
              <input type="text" value={formData.indicator} onChange={(e) => setFormData({ ...formData, indicator: e.target.value })} className="tc-input" placeholder="Contoh: Berjalan dengan stabil" required />
            </div>
            <div>
              <label className="tc-label">Progress *</label>
              <div style={{ display: 'grid', gridTemplateColumns: 'repeat(5, 1fr)', gap: '6px' }}>
                {Object.entries(progressConfig).map(([key, config]) => (
                  <button key={key} type="button" onClick={() => setFormData({ ...formData, progress: key })} style={{
                    padding: '8px', borderRadius: 'var(--radius-md)', border: `2px solid ${formData.progress === key ? 'var(--color-primary)' : 'var(--color-border)'}`,
                    background: formData.progress === key ? 'var(--color-primary-lighter)' : 'transparent', cursor: 'pointer', textAlign: 'center', fontSize: '11px', fontWeight: '500', color: 'var(--color-text)',
                  }}>
                    {config.label}
                  </button>
                ))}
              </div>
            </div>
            <div>
              <label className="tc-label">Tanggal Observasi *</label>
              <input type="date" value={formData.observation_date} onChange={(e) => setFormData({ ...formData, observation_date: e.target.value })} className="tc-input" required />
            </div>
            <div>
              <label className="tc-label">Catatan</label>
              <textarea value={formData.notes} onChange={(e) => setFormData({ ...formData, notes: e.target.value })} className="tc-input" rows="2" placeholder="Catatan observasi (opsional)" />
            </div>
          </div>
          <div style={{ display: 'flex', gap: '10px', marginTop: '20px' }}>
            <button type="button" onClick={() => setShowAssessmentModal(false)} className="tc-btn tc-btn-secondary" style={{ flex: 1 }}>Batal</button>
            <button type="submit" disabled={submitting} className="tc-btn tc-btn-primary" style={{ flex: 1 }}>{submitting ? 'Menyimpan...' : 'Simpan'}</button>
          </div>
        </form>
      </Modal>
    </div>
  );
}
