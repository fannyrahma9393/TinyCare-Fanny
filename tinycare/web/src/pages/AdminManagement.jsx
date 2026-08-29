import { useState, useEffect } from 'react';
import { adminManagementAPI } from '../services/api';
import { useAuth } from '../context/AuthContext';

export default function AdminManagement() {
  const { user } = useAuth();
  const [admins, setAdmins] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [showForm, setShowForm] = useState(false);
  const [form, setForm] = useState({ name: '', email: '', password: '', password_confirmation: '', phone: '', position: '', admin_role: 'admin' });
  const [formLoading, setFormLoading] = useState(false);
  const [actionLoading, setActionLoading] = useState(null);
  const [toast, setToast] = useState(null);

  const isMaster = user?.role === 'admin_master';

  useEffect(() => { loadAdmins(); }, []);

  async function loadAdmins() {
    setLoading(true);
    setError('');
    try {
      const res = await adminManagementAPI.list();
      setAdmins(res.data.data.data || []);
    } catch (err) {
      setError(err.response?.data?.message || 'Gagal memuat data admin.');
    } finally {
      setLoading(false);
    }
  }

  async function handleCreate(e) {
    e.preventDefault();
    if (form.password !== form.password_confirmation) {
      setToast({ type: 'error', message: 'Password dan konfirmasi tidak cocok.' });
      return;
    }
    setFormLoading(true);
    try {
      await adminManagementAPI.create(form);
      setToast({ type: 'success', message: 'Admin berhasil ditambahkan.' });
      setShowForm(false);
      setForm({ name: '', email: '', password: '', password_confirmation: '', phone: '', position: '', admin_role: 'admin' });
      loadAdmins();
    } catch (err) {
      const errors = err.response?.data?.errors;
      const msg = err.response?.data?.message;
      if (errors) {
        const first = Object.values(errors)[0];
        setToast({ type: 'error', message: Array.isArray(first) ? first[0] : first });
      } else {
        setToast({ type: 'error', message: msg || 'Gagal menambahkan admin.' });
      }
    } finally {
      setFormLoading(false);
    }
  }

  async function handleToggleActive(admin) {
    const isActive = admin.user?.status === 'active';
    setActionLoading(admin.id);
    try {
      if (isActive) {
        await adminManagementAPI.deactivate(admin.id);
        setToast({ type: 'success', message: `${admin.user.name} berhasil dinonaktifkan.` });
      } else {
        await adminManagementAPI.activate(admin.id);
        setToast({ type: 'success', message: `${admin.user.name} berhasil diaktifkan.` });
      }
      loadAdmins();
    } catch (err) {
      setToast({ type: 'error', message: err.response?.data?.message || 'Gagal mengubah status.' });
    } finally {
      setActionLoading(null);
    }
  }

  if (!isMaster) {
    return (
      <div className="tc-empty-state" style={{ padding: '48px' }}>
        <div className="tc-empty-state-icon">
          <svg width="28" height="28" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8"><circle cx="12" cy="12" r="10"/><line x1="12" y1="8" x2="12" y2="12"/><line x1="12" y1="16" x2="12.01" y2="16"/></svg>
        </div>
        <p className="tc-empty-state-title">Akses Ditolak</p>
        <p className="tc-empty-state-desc">Hanya admin_master yang dapat mengelola admin.</p>
      </div>
    );
  }

  const inputStyle = {
    width: '100%', padding: '10px 14px', fontSize: '13px', borderRadius: '10px',
    border: '1.5px solid var(--color-border)', background: 'var(--color-surface)',
    color: 'var(--color-text)', boxSizing: 'border-box',
  };

  return (
    <div>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', marginBottom: '24px' }}>
        <div>
          <h1 style={{ fontSize: '22px', fontWeight: '700', marginBottom: '4px' }}>Kelola Admin</h1>
          <p style={{ fontSize: '13px', color: 'var(--color-text-muted)' }}>Kelola admin dan admin_master TinyCare</p>
        </div>
        <button onClick={() => setShowForm(!showForm)} className="tc-btn tc-btn-primary">
          {showForm ? 'Tutup' : '+ Tambah Admin'}
        </button>
      </div>

      {toast && (
        <div style={{
          padding: '12px 16px', borderRadius: '12px', marginBottom: '16px',
          background: toast.type === 'success' ? 'var(--color-success-bg)' : 'var(--color-error-bg)',
          color: toast.type === 'success' ? 'var(--color-success)' : 'var(--color-error)',
          fontSize: '13px', fontWeight: '500', display: 'flex', alignItems: 'center', gap: '8px',
        }}>
          {toast.type === 'success' ? '✓' : '✕'} {toast.message}
          <button onClick={() => setToast(null)} style={{ marginLeft: 'auto', background: 'none', border: 'none', cursor: 'pointer', color: 'inherit' }}>×</button>
        </div>
      )}

      {/* Create Form */}
      {showForm && (
        <div className="tc-card" style={{ padding: '24px', marginBottom: '20px' }}>
          <h3 style={{ fontSize: '15px', fontWeight: '700', marginBottom: '16px' }}>Tambah Admin Baru</h3>
          <form onSubmit={handleCreate}>
            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '14px' }}>
              <div>
                <label style={{ display: 'block', fontSize: '12px', fontWeight: '600', marginBottom: '4px' }}>Nama *</label>
                <input type="text" value={form.name} onChange={(e) => setForm({ ...form, name: e.target.value })} style={inputStyle} required />
              </div>
              <div>
                <label style={{ display: 'block', fontSize: '12px', fontWeight: '600', marginBottom: '4px' }}>Email *</label>
                <input type="email" value={form.email} onChange={(e) => setForm({ ...form, email: e.target.value })} style={inputStyle} required />
              </div>
              <div>
                <label style={{ display: 'block', fontSize: '12px', fontWeight: '600', marginBottom: '4px' }}>Password *</label>
                <input type="password" value={form.password} onChange={(e) => setForm({ ...form, password: e.target.value })} style={inputStyle} required minLength="8" />
              </div>
              <div>
                <label style={{ display: 'block', fontSize: '12px', fontWeight: '600', marginBottom: '4px' }}>Konfirmasi Password *</label>
                <input type="password" value={form.password_confirmation} onChange={(e) => setForm({ ...form, password_confirmation: e.target.value })} style={inputStyle} required minLength="8" />
              </div>
              <div>
                <label style={{ display: 'block', fontSize: '12px', fontWeight: '600', marginBottom: '4px' }}>Phone</label>
                <input type="text" value={form.phone} onChange={(e) => setForm({ ...form, phone: e.target.value })} style={inputStyle} />
              </div>
              <div>
                <label style={{ display: 'block', fontSize: '12px', fontWeight: '600', marginBottom: '4px' }}>Posisi</label>
                <input type="text" value={form.position} onChange={(e) => setForm({ ...form, position: e.target.value })} style={inputStyle} />
              </div>
              <div>
                <label style={{ display: 'block', fontSize: '12px', fontWeight: '600', marginBottom: '4px' }}>Role</label>
                <select value={form.admin_role} onChange={(e) => setForm({ ...form, admin_role: e.target.value })} style={inputStyle}>
                  <option value="admin">Admin</option>
                  <option value="admin_master">Admin Master</option>
                </select>
              </div>
            </div>
            <div style={{ marginTop: '16px', display: 'flex', gap: '10px', justifyContent: 'flex-end' }}>
              <button type="button" onClick={() => setShowForm(false)} className="tc-btn tc-btn-secondary tc-btn-sm">Batal</button>
              <button type="submit" disabled={formLoading} className="tc-btn tc-btn-primary tc-btn-sm">
                {formLoading ? 'Menyimpan...' : 'Simpan'}
              </button>
            </div>
          </form>
        </div>
      )}

      {/* Admin List */}
      {loading ? (
        <div className="tc-loading-screen"><div className="tc-spinner tc-spinner-lg"></div></div>
      ) : error ? (
        <div className="tc-error-state">
          <p className="tc-empty-state-title">{error}</p>
          <button onClick={loadAdmins} className="tc-btn tc-btn-secondary tc-btn-sm" style={{ marginTop: '12px' }}>Coba Lagi</button>
        </div>
      ) : admins.length === 0 ? (
        <div className="tc-empty-state">
          <p className="tc-empty-state-title">Belum ada admin</p>
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
              {admins.map((a) => {
                const isActive = a.user?.status === 'active';
                const isSelf = a.user_id === user?.id;
                return (
                  <tr key={a.id} style={{ borderBottom: '1px solid var(--color-border-light)' }}>
                    <td style={{ padding: '12px 16px', fontWeight: '500' }}>{a.user?.name}</td>
                    <td style={{ padding: '12px 16px', color: 'var(--color-text-secondary)' }}>{a.user?.email}</td>
                    <td style={{ padding: '12px 16px' }}>
                      <span className="tc-badge" style={{
                        background: a.user?.role?.name === 'admin_master' ? 'var(--color-primary-subtle)' : 'var(--color-info-bg)',
                        color: a.user?.role?.name === 'admin_master' ? 'var(--color-primary)' : 'var(--color-info)',
                      }}>
                        {a.user?.role?.name === 'admin_master' ? 'Admin Master' : 'Admin'}
                      </span>
                    </td>
                    <td style={{ padding: '12px 16px' }}>
                      <span className="tc-badge" style={{
                        background: isActive ? 'var(--color-success-bg)' : 'var(--color-bg-alt)',
                        color: isActive ? 'var(--color-success)' : 'var(--color-text-muted)',
                      }}>
                        {isActive ? 'Aktif' : 'Nonaktif'}
                      </span>
                    </td>
                    <td style={{ padding: '12px 16px', textAlign: 'right' }}>
                      {!isSelf && (
                        <button onClick={() => handleToggleActive(a)} disabled={actionLoading === a.id}
                          className={`tc-btn tc-btn-sm ${isActive ? 'tc-btn-secondary' : 'tc-btn-primary'}`}
                          style={isActive ? { color: 'var(--color-error)' } : {}}>
                          {actionLoading === a.id ? '...' : isActive ? 'Nonaktifkan' : 'Aktifkan'}
                        </button>
                      )}
                      {isSelf && <span style={{ fontSize: '12px', color: 'var(--color-text-muted)' }}>Akun Anda</span>}
                    </td>
                  </tr>
                );
              })}
            </tbody>
          </table>
        </div>
      )}
    </div>
  );
}
