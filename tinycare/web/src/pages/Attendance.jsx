import { useState, useEffect } from 'react';
import { attendanceAPI, childrenAPI } from '../services/api';
import { PageHeader, Modal, EmptyState } from '../components/PageHeader';

export default function Attendance() {
  const [attendance, setAttendance] = useState([]);
  const [children, setChildren] = useState([]);
  const [loading, setLoading] = useState(true);
  const [selectedDate, setSelectedDate] = useState(new Date().toISOString().split('T')[0]);
  const [showModal, setShowModal] = useState(false);
  const [formData, setFormData] = useState({ child_id: '', status: 'hadir', check_in_time: '', check_out_time: '', notes: '' });
  const [error, setError] = useState('');

  async function loadAttendance() {
    setLoading(true);
    try { const res = await attendanceAPI.list({ date: selectedDate }); setAttendance(res.data.data.data || []); }
    catch (error) { setError(error.response?.data?.message || 'Gagal memuat data kehadiran.'); } finally { setLoading(false); }
  }
  async function loadChildren() {
    try { const res = await childrenAPI.list({ per_page: 100 }); setChildren(res.data.data.data || []); }
    catch (error) { setError(error.response?.data?.message || 'Gagal memuat data anak.'); }
  }

  useEffect(() => { loadAttendance(); loadChildren(); }, [selectedDate]);

  const handleSubmit = async (e) => {
    e.preventDefault();
    try { await attendanceAPI.create({ ...formData, date: selectedDate }); setShowModal(false); setFormData({ child_id: '', status: 'hadir', check_in_time: '', check_out_time: '', notes: '' }); loadAttendance(); }
    catch (error) { alert(error.response?.data?.message || 'Gagal mencatat kehadiran.'); }
  };

  const statusConfig = {
    hadir: { label: 'Hadir', color: 'var(--color-success)', bg: 'var(--color-success-bg)' },
    izin: { label: 'Izin', color: 'var(--color-warning)', bg: 'var(--color-warning-bg)' },
    sakit: { label: 'Sakit', color: 'var(--color-error)', bg: 'var(--color-error-bg)' },
    tidak_hadir: { label: 'Tidak Hadir', color: 'var(--color-text-muted)', bg: 'var(--color-bg-alt)' },
  };

  const summary = { hadir: attendance.filter(a => a.status === 'hadir').length, izin: attendance.filter(a => a.status === 'izin').length, sakit: attendance.filter(a => a.status === 'sakit').length, tidak_hadir: attendance.filter(a => a.status === 'tidak_hadir').length };

  if (loading) return <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'center', height: '300px' }}><div className="tc-spinner"></div></div>;

  return (
    <div>
      <PageHeader
        title="Manajemen Kehadiran"
        subtitle="Catat dan pantau kehadiran anak harian"
        action={
          <div style={{ display: 'flex', gap: '10px', alignItems: 'center' }}>
            <input type="date" value={selectedDate} onChange={(e) => setSelectedDate(e.target.value)} className="tc-input" style={{ width: '180px' }} />
            <button onClick={() => setShowModal(true)} className="tc-btn tc-btn-primary">+ Catat</button>
          </div>
        }
      />

      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(4, 1fr)', gap: '12px', marginBottom: '24px' }}>
        {Object.entries(statusConfig).map(([status, config]) => (
          <div key={status} className="tc-card" style={{ padding: '16px', textAlign: 'center' }}>
            <p style={{ fontSize: '28px', fontWeight: '700', color: 'var(--color-text)', marginBottom: '2px' }}>{summary[status]}</p>
            <p style={{ fontSize: '12px', color: 'var(--color-text-muted)', fontWeight: '500' }}>{config.label}</p>
          </div>
        ))}
      </div>

      {error && (
        <div className="tc-error-state" style={{ marginBottom: '16px' }}>
          <p className="tc-empty-state-title">{error}</p>
          <button onClick={() => { setError(''); loadAttendance(); loadChildren(); }} className="tc-btn tc-btn-secondary tc-btn-sm" style={{ marginTop: '12px' }}>Coba Lagi</button>
        </div>
      )}

      <div className="tc-card" style={{ overflow: 'hidden' }}>
        <div style={{ padding: '16px 20px', borderBottom: '1px solid var(--color-border-light)' }}>
          <h2 style={{ fontSize: '14px', fontWeight: '600' }}>
            Kehadiran {new Date(selectedDate).toLocaleDateString('id-ID', { weekday: 'long', year: 'numeric', month: 'long', day: 'numeric' })}
          </h2>
        </div>
        <table className="tc-table">
          <thead><tr><th>Anak</th><th>Status</th><th>Masuk</th><th>Keluar</th><th>Catatan</th></tr></thead>
          <tbody>
            {attendance.map((r) => (
              <tr key={r.id}>
                <td>
                  <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
                    <div style={{ width: '30px', height: '30px', borderRadius: '8px', background: 'var(--color-primary-lighter)', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                      <span style={{ color: 'var(--color-primary)', fontWeight: '700', fontSize: '12px' }}>{r.child?.name?.charAt(0)}</span>
                    </div>
                    <span style={{ fontWeight: '600', fontSize: '13px' }}>{r.child?.name}</span>
                  </div>
                </td>
                <td>
                  <span className="tc-badge" style={{ background: statusConfig[r.status]?.bg, color: statusConfig[r.status]?.color }}>
                    {statusConfig[r.status]?.label}
                  </span>
                </td>
                <td style={{ fontSize: '13px', color: 'var(--color-text-secondary)' }}>{r.check_in_time || '-'}</td>
                <td style={{ fontSize: '13px', color: 'var(--color-text-secondary)' }}>{r.check_out_time || '-'}</td>
                <td style={{ fontSize: '13px', color: 'var(--color-text-secondary)', maxWidth: '160px', overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>{r.notes || '-'}</td>
              </tr>
            ))}
          </tbody>
        </table>
        {attendance.length === 0 && <EmptyState icon="✅" title="Belum ada catatan kehadiran" description="Klik 'Catat' untuk menambahkan." />}
      </div>

      <Modal open={showModal} onClose={() => setShowModal(false)} title="Catat Kehadiran">
        <form onSubmit={handleSubmit}>
          <div style={{ display: 'flex', flexDirection: 'column', gap: '14px' }}>
            <div>
              <label className="tc-label">Pilih Anak *</label>
              <select value={formData.child_id} onChange={(e) => setFormData({ ...formData, child_id: e.target.value })} className="tc-select" required>
                <option value="">-- Pilih Anak --</option>
                {children.map((c) => <option key={c.id} value={c.id}>{c.name}</option>)}
              </select>
            </div>
            <div>
              <label className="tc-label">Status *</label>
              <div style={{ display: 'grid', gridTemplateColumns: 'repeat(4, 1fr)', gap: '8px' }}>
                {Object.entries(statusConfig).map(([s, c]) => (
                  <button key={s} type="button" onClick={() => setFormData({ ...formData, status: s })} style={{
                    padding: '10px', borderRadius: 'var(--radius-md)', border: `2px solid ${formData.status === s ? 'var(--color-primary)' : 'var(--color-border)'}`,
                    background: formData.status === s ? 'var(--color-primary-lighter)' : 'transparent',
                    cursor: 'pointer', textAlign: 'center', fontSize: '12px', fontWeight: '500', color: 'var(--color-text)',
                    transition: 'all 0.15s ease',
                  }}>
                    {c.label}
                  </button>
                ))}
              </div>
            </div>
            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '14px' }}>
              <div>
                <label className="tc-label">Jam Masuk</label>
                <input type="time" value={formData.check_in_time} onChange={(e) => setFormData({ ...formData, check_in_time: e.target.value })} className="tc-input" />
              </div>
              <div>
                <label className="tc-label">Jam Keluar</label>
                <input type="time" value={formData.check_out_time} onChange={(e) => setFormData({ ...formData, check_out_time: e.target.value })} className="tc-input" />
              </div>
            </div>
            <div>
              <label className="tc-label">Catatan</label>
              <textarea value={formData.notes} onChange={(e) => setFormData({ ...formData, notes: e.target.value })} className="tc-input" rows="2" />
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
