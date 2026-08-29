import { useState, useEffect } from 'react';
import { parentAPI } from '../../services/api';

export default function ParentAttendance() {
  const [children, setChildren] = useState([]);
  const [selectedChild, setSelectedChild] = useState('');
  const [attendance, setAttendance] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');

  useEffect(() => {
    parentAPI.children()
      .then((res) => {
        const list = res.data.data.data || [];
        setChildren(list);
        if (list.length > 0) setSelectedChild(list[0].id);
      })
      .catch(() => setError('Gagal memuat data anak.'))
      .finally(() => setLoading(false));
  }, []);

  useEffect(() => {
    if (!selectedChild) return;
    setLoading(true);
    setError('');
    parentAPI.childAttendance(selectedChild)
      .then((res) => setAttendance(res.data.data?.attendance?.data || []))
      .catch(() => { setAttendance([]); setError('Gagal memuat data kehadiran.'); })
      .finally(() => setLoading(false));
  }, [selectedChild]);

  if (loading && children.length === 0) return <div className="tc-loading-screen"><div className="tc-spinner tc-spinner-lg"></div><p>Memuat data...</p></div>;

  const statusBadge = (status) => {
    const map = { hadir: 'tc-badge-success', izin: 'tc-badge-warning', alpa: 'tc-badge-error', sakit: 'tc-badge-info' };
    return <span className={`tc-badge ${map[status] || 'tc-badge-neutral'}`}>{status}</span>;
  };

  return (
    <div>
      <div className="tc-page-header">
        <h1>Kehadiran</h1>
        <p>Riwayat kehadiran anak Anda di daycare.</p>
      </div>

      {children.length > 0 && (
        <div style={{ marginBottom: '20px' }}>
          <label className="tc-label">Pilih Anak</label>
          <select value={selectedChild} onChange={(e) => setSelectedChild(e.target.value)} className="tc-select" style={{ maxWidth: '260px' }}>
            {children.map((c) => <option key={c.id} value={c.id}>{c.name}</option>)}
          </select>
        </div>
      )}

      {error && (
        <div className="tc-card" style={{ padding: '20px', marginBottom: '16px', borderColor: 'var(--color-error)', background: 'var(--color-error-bg)' }}>
          <p style={{ color: 'var(--color-error)', fontSize: '13px' }}>{error}</p>
        </div>
      )}

      <div className="tc-card" style={{ overflow: 'hidden' }}>
        {attendance.length > 0 ? (
          <table className="tc-table">
            <thead><tr><th>Tanggal</th><th>Status</th><th>Masuk</th><th>Keluar</th><th>Catatan</th></tr></thead>
            <tbody>
              {attendance.map((r) => (
                <tr key={r.id}>
                  <td style={{ fontSize: '13px' }}>{new Date(r.date).toLocaleDateString('id-ID', { weekday: 'long', year: 'numeric', month: 'long', day: 'numeric' })}</td>
                  <td>{statusBadge(r.status)}</td>
                  <td style={{ fontSize: '13px', color: 'var(--color-text-secondary)' }}>{r.check_in_time || '-'}</td>
                  <td style={{ fontSize: '13px', color: 'var(--color-text-secondary)' }}>{r.check_out_time || '-'}</td>
                  <td style={{ fontSize: '13px', color: 'var(--color-text-secondary)' }}>{r.notes || '-'}</td>
                </tr>
              ))}
            </tbody>
          </table>
        ) : (
          <div className="tc-empty-state">
            <div className="tc-empty-state-icon"><svg width="28" height="28" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8"><path d="M9 11l3 3L22 4"/><path d="M21 12v7a2 2 0 01-2 2H5a2 2 0 01-2-2V5a2 2 0 012-2h11"/></svg></div>
            <p className="tc-empty-state-title">Belum ada catatan kehadiran</p>
            <p className="tc-empty-state-desc">Data kehadiran akan muncul setelah anak mulai beraktivitas.</p>
          </div>
        )}
      </div>
    </div>
  );
}
