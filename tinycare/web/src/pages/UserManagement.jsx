import { useState, useEffect } from 'react';
import { useSearchParams } from 'react-router-dom';
import { userManagementAPI } from '../services/api';

export default function UserManagement() {
  const [users, setUsers] = useState([]);
  const [summary, setSummary] = useState({});
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [searchParams] = useSearchParams();
  const [filter, setFilter] = useState(searchParams.get('filter') || 'all');
  const [search, setSearch] = useState('');
  const [actionLoading, setActionLoading] = useState(null);
  const [rejectModal, setRejectModal] = useState(null);
  const [rejectReason, setRejectReason] = useState('');
  const [toast, setToast] = useState(null);

  useEffect(() => { loadUsers(); }, [filter, search]);

  useEffect(() => {
    setFilter(searchParams.get('filter') || 'all');
  }, [searchParams]);

  async function loadUsers() {
    setLoading(true);
    setError('');
    try {
      const res = await userManagementAPI.list({ filter, search: search || undefined });
      setUsers(res.data.data.data || []);
      setSummary(res.data.summary || {});
    } catch (err) {
      setError(err.response?.data?.message || 'Gagal memuat data pengguna.');
    } finally {
      setLoading(false);
    }
  }

  async function handleApprove(userId) {
    setActionLoading(userId);
    try {
      await userManagementAPI.approve(userId);
      setToast({ type: 'success', message: 'Akun berhasil disetujui.' });
      loadUsers();
    } catch (err) {
      setToast({ type: 'error', message: err.response?.data?.message || 'Gagal menyetujui akun.' });
    } finally {
      setActionLoading(null);
    }
  }

  async function handleReject() {
    if (!rejectModal) return;
    setActionLoading(rejectModal.id);
    try {
      await userManagementAPI.reject(rejectModal.id, { reason: rejectReason });
      setToast({ type: 'success', message: 'Akun berhasil ditolak.' });
      setRejectModal(null);
      setRejectReason('');
      loadUsers();
    } catch (err) {
      setToast({ type: 'error', message: err.response?.data?.message || 'Gagal menolak akun.' });
    } finally {
      setActionLoading(null);
    }
  }

  async function handleToggleStatus(user) {
    const target = user.status === 'active' ? 'inactive' : 'active';
    if (!window.confirm(target === 'inactive'
      ? `Nonaktifkan akun ${user.name}? Pengguna tidak dapat login selama nonaktif.`
      : `Aktifkan akun ${user.name}?`)) return;

    setActionLoading(user.id);
    try {
      if (target === 'active') {
        await userManagementAPI.activate(user.id);
      } else {
        await userManagementAPI.deactivate(user.id);
      }
      setToast({ type: 'success', message: target === 'active' ? 'Akun berhasil diaktifkan.' : 'Akun berhasil dinonaktifkan.' });
      loadUsers();
    } catch (err) {
      setToast({ type: 'error', message: err.response?.data?.message || 'Gagal mengubah status akun.' });
    } finally {
      setActionLoading(null);
    }
  }

  const filters = [
    { key: 'all', label: 'Semua' },
    { key: 'parent', label: 'Orang Tua' },
    { key: 'pending', label: 'Menunggu' },
    { key: 'active', label: 'Aktif' },
    { key: 'inactive', label: 'Nonaktif' },
    { key: 'admin', label: 'Admin' },
  ];

  const statusColors = {
    active: { bg: 'var(--color-success-bg)', color: 'var(--color-success)' },
    pending: { bg: 'var(--color-warning-bg)', color: 'var(--color-warning)' },
    rejected: { bg: 'var(--color-error-bg)', color: 'var(--color-error)' },
    inactive: { bg: 'var(--color-bg-alt)', color: 'var(--color-text-muted)' },
  };

  const statusLabels = { active: 'Aktif', pending: 'Menunggu', rejected: 'Ditolak', inactive: 'Nonaktif' };

  return (
    <div>
      <h1 style={{ fontSize: '22px', fontWeight: '700', marginBottom: '4px' }}>Pengguna</h1>
      <p style={{ fontSize: '13px', color: 'var(--color-text-muted)', marginBottom: '24px' }}>Kelola pengguna TinyCare</p>

      {/* Toast */}
      {toast && (
        <div style={{
          padding: '12px 16px', borderRadius: '12px', marginBottom: '16px',
          background: toast.type === 'success' ? 'var(--color-success-bg)' : 'var(--color-error-bg)',
          color: toast.type === 'success' ? 'var(--color-success)' : 'var(--color-error)',
          fontSize: '13px', fontWeight: '500', display: 'flex', alignItems: 'center', gap: '8px',
        }}>
          {toast.type === 'success' ? '✓' : '✕'} {toast.message}
          <button onClick={() => setToast(null)} style={{ marginLeft: 'auto', background: 'none', border: 'none', cursor: 'pointer', color: 'inherit', fontSize: '16px' }}>×</button>
        </div>
      )}

      {/* Summary Cards */}
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(160px, 1fr))', gap: '12px', marginBottom: '24px' }}>
        {[
          { label: 'Total Pengguna', value: summary.total ?? '-', color: 'var(--color-primary)' },
          { label: 'Orang Tua Aktif', value: summary.active_parents ?? '-', color: 'var(--color-success)' },
          { label: 'Menunggu', value: summary.pending_parents ?? '-', color: 'var(--color-warning)' },
          { label: 'Admin', value: summary.admins ?? '-', color: 'var(--color-info)' },
        ].map((item) => (
          <div key={item.label} className="tc-card tc-card-hover" style={{ padding: '16px' }}>
            <p style={{ fontSize: '11px', fontWeight: '600', color: 'var(--color-text-muted)', textTransform: 'uppercase', letterSpacing: '0.05em', marginBottom: '8px' }}>{item.label}</p>
            <p style={{ fontSize: '28px', fontWeight: '700', lineHeight: 1, color: item.color }}>{item.value}</p>
          </div>
        ))}
      </div>

      {/* Filters + Search */}
      <div style={{ display: 'flex', gap: '12px', marginBottom: '16px', flexWrap: 'wrap', alignItems: 'center' }}>
        <div style={{ display: 'flex', gap: '6px' }}>
          {filters.map((f) => (
            <button key={f.key} onClick={() => setFilter(f.key)} className={`tc-btn ${filter === f.key ? 'tc-btn-primary' : 'tc-btn-secondary'} tc-btn-sm`}>
              {f.label}
            </button>
          ))}
        </div>
        <input
          type="text" value={search} onChange={(e) => setSearch(e.target.value)}
          placeholder="Cari nama atau email..."
          style={{
            flex: 1, minWidth: '200px', padding: '8px 14px', fontSize: '13px',
            borderRadius: '10px', border: '1.5px solid var(--color-border)',
            background: 'var(--color-surface)', color: 'var(--color-text)',
          }}
        />
      </div>

      {/* Table */}
      {loading ? (
        <div className="tc-loading-screen"><div className="tc-spinner tc-spinner-lg"></div></div>
      ) : error ? (
        <div className="tc-error-state">
          <p className="tc-empty-state-title">{error}</p>
          <button onClick={loadUsers} className="tc-btn tc-btn-secondary tc-btn-sm" style={{ marginTop: '12px' }}>Coba Lagi</button>
        </div>
      ) : users.length === 0 ? (
        <div className="tc-empty-state">
          <p className="tc-empty-state-title">Tidak ada pengguna ditemukan</p>
        </div>
      ) : (
        <div className="tc-card" style={{ overflow: 'hidden' }}>
          <table style={{ width: '100%', borderCollapse: 'collapse', fontSize: '13px' }}>
            <thead>
              <tr style={{ borderBottom: '1px solid var(--color-border-light)' }}>
                <th style={{ padding: '12px 16px', textAlign: 'left', fontWeight: '600', color: 'var(--color-text-muted)', fontSize: '11px', textTransform: 'uppercase', letterSpacing: '0.05em' }}>Nama</th>
                <th style={{ padding: '12px 16px', textAlign: 'left', fontWeight: '600', color: 'var(--color-text-muted)', fontSize: '11px', textTransform: 'uppercase', letterSpacing: '0.05em' }}>Email</th>
                <th style={{ padding: '12px 16px', textAlign: 'left', fontWeight: '600', color: 'var(--color-text-muted)', fontSize: '11px', textTransform: 'uppercase', letterSpacing: '0.05em' }}>Role</th>
                <th style={{ padding: '12px 16px', textAlign: 'left', fontWeight: '600', color: 'var(--color-text-muted)', fontSize: '11px', textTransform: 'uppercase', letterSpacing: '0.05em' }}>Status</th>
                <th style={{ padding: '12px 16px', textAlign: 'right', fontWeight: '600', color: 'var(--color-text-muted)', fontSize: '11px', textTransform: 'uppercase', letterSpacing: '0.05em' }}>Aksi</th>
              </tr>
            </thead>
            <tbody>
              {users.map((u) => {
                const sc = statusColors[u.status] || statusColors.inactive;
                const isPending = u.status === 'pending';
                return (
                  <tr key={u.id} style={{ borderBottom: '1px solid var(--color-border-light)' }}>
                    <td style={{ padding: '12px 16px', fontWeight: '500' }}>{u.name}</td>
                    <td style={{ padding: '12px 16px', color: 'var(--color-text-secondary)' }}>{u.email}</td>
                    <td style={{ padding: '12px 16px' }}>
                      <span style={{ fontSize: '12px', fontWeight: '500', color: u.role?.name === 'admin_master' ? 'var(--color-primary)' : u.role?.name === 'admin' ? 'var(--color-info)' : 'var(--color-text-secondary)' }}>
                        {u.role?.name === 'admin_master' ? 'Admin Master' : u.role?.name === 'admin' ? 'Admin' : 'Orang Tua'}
                      </span>
                    </td>
                    <td style={{ padding: '12px 16px' }}>
                      <span className="tc-badge" style={{ background: sc.bg, color: sc.color }}>{statusLabels[u.status] || u.status}</span>
                    </td>
                    <td style={{ padding: '12px 16px', textAlign: 'right' }}>
                      <div style={{ display: 'flex', gap: '6px', justifyContent: 'flex-end', flexWrap: 'wrap' }}>
                        {isPending && (
                          <>
                            <button onClick={() => handleApprove(u.id)} disabled={actionLoading === u.id} className="tc-btn tc-btn-primary tc-btn-sm">
                              {actionLoading === u.id ? '...' : 'Setujui'}
                            </button>
                            <button onClick={() => setRejectModal(u)} disabled={actionLoading === u.id} className="tc-btn tc-btn-secondary tc-btn-sm" style={{ color: 'var(--color-error)' }}>
                              Tolak
                            </button>
                          </>
                        )}
                        {u.status === 'active' && (
                          <button onClick={() => handleToggleStatus(u)} disabled={actionLoading === u.id} className="tc-btn tc-btn-secondary tc-btn-sm" style={{ color: 'var(--color-warning)' }}>
                            Nonaktifkan
                          </button>
                        )}
                        {u.status === 'inactive' && (
                          <button onClick={() => handleToggleStatus(u)} disabled={actionLoading === u.id} className="tc-btn tc-btn-secondary tc-btn-sm" style={{ color: 'var(--color-success)' }}>
                            Aktifkan
                          </button>
                        )}
                      </div>
                    </td>
                  </tr>
                );
              })}
            </tbody>
          </table>
        </div>
      )}

      {/* Reject Modal */}
      {rejectModal && (
        <div style={{ position: 'fixed', inset: 0, background: 'rgba(0,0,0,0.4)', display: 'flex', alignItems: 'center', justifyContent: 'center', zIndex: 1000, padding: '24px' }}
          onClick={() => { setRejectModal(null); setRejectReason(''); }}>
          <div style={{ background: 'var(--color-surface)', borderRadius: '16px', padding: '28px', maxWidth: '420px', width: '100%' }} onClick={(e) => e.stopPropagation()}>
            <h3 style={{ fontSize: '16px', fontWeight: '700', marginBottom: '12px' }}>Tolak Akun</h3>
            <p style={{ fontSize: '13px', color: 'var(--color-text-secondary)', marginBottom: '16px' }}>
              Apakah Anda yakin ingin menolak akun <strong>{rejectModal.name}</strong>?
            </p>
            <textarea value={rejectReason} onChange={(e) => setRejectReason(e.target.value)}
              placeholder="Alasan penolakan (opsional)"
              style={{ width: '100%', padding: '10px 14px', fontSize: '13px', borderRadius: '10px', border: '1.5px solid var(--color-border)', background: 'var(--color-surface)', color: 'var(--color-text)', boxSizing: 'border-box', minHeight: '80px', resize: 'vertical' }}
            />
            <div style={{ display: 'flex', gap: '10px', marginTop: '16px', justifyContent: 'flex-end' }}>
              <button onClick={() => { setRejectModal(null); setRejectReason(''); }} className="tc-btn tc-btn-secondary tc-btn-sm">Batal</button>
              <button onClick={handleReject} disabled={actionLoading === rejectModal.id} className="tc-btn tc-btn-sm" style={{ background: 'var(--color-error)', color: 'white' }}>
                {actionLoading === rejectModal.id ? 'Menolak...' : 'Tolak'}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
