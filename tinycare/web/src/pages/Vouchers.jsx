import { useState, useEffect } from 'react';
import { vouchersAPI } from '../services/api';
import { PageHeader, Modal, EmptyState, StatusBadge } from '../components/PageHeader';

export default function Vouchers() {
  const [vouchers, setVouchers] = useState([]);
  const [loading, setLoading] = useState(true);
  const [showModal, setShowModal] = useState(false);
  const [formData, setFormData] = useState({
    code: '', description: '', discount_type: 'nominal', discount_value: '',
    min_transaction: '0', max_usage: '', start_date: '', end_date: '', status: 'active',
  });

  async function loadVouchers() {
    try {
      const res = await vouchersAPI.list();
      setVouchers(res.data.data.data || []);
    } catch (error) {
      console.error('Error loading vouchers:', error);
    } finally {
      setLoading(false);
    }
  }

  useEffect(() => { loadVouchers(); }, []);

  const handleSubmit = async (e) => {
    e.preventDefault();
    try {
      await vouchersAPI.create({
        ...formData,
        discount_value: parseFloat(formData.discount_value),
        min_transaction: parseFloat(formData.min_transaction),
        max_usage: parseInt(formData.max_usage),
      });
      setShowModal(false);
      setFormData({ code: '', description: '', discount_type: 'nominal', discount_value: '', min_transaction: '0', max_usage: '', start_date: '', end_date: '', status: 'active' });
      loadVouchers();
    } catch (error) {
      alert(error.response?.data?.message || 'Gagal menambahkan voucher.');
    }
  };

  const handleDelete = async (id) => {
    if (confirm('Yakin ingin menghapus voucher ini?')) {
      try { await vouchersAPI.delete(id); loadVouchers(); } catch { alert('Gagal menghapus voucher.'); }
    }
  };

  const formatDiscount = (v) => v.discount_type === 'percentage' ? `${v.discount_value}%` : new Intl.NumberFormat('id-ID', { style: 'currency', currency: 'IDR' }).format(v.discount_value);

  if (loading) return <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'center', height: '300px' }}><div className="tc-spinner"></div></div>;

  const statusCfg = { active: { label: 'Aktif', color: 'var(--color-success)', bg: 'var(--color-success-bg)' }, inactive: { label: 'Nonaktif', color: 'var(--color-text-muted)', bg: 'var(--color-bg-alt)' } };

  return (
    <div>
      <PageHeader title="Manajemen Voucher" subtitle="Kelola voucher diskon untuk pelanggan" action={<button onClick={() => setShowModal(true)} className="tc-btn tc-btn-primary">+ Tambah Voucher</button>} />

      <div className="tc-card" style={{ overflow: 'hidden' }}>
        <table className="tc-table">
          <thead>
            <tr>
              <th>Kode</th>
              <th>Diskon</th>
              <th>Min. Transaksi</th>
              <th>Penggunaan</th>
              <th>Berlaku</th>
              <th>Status</th>
              <th>Aksi</th>
            </tr>
          </thead>
          <tbody>
            {vouchers.map((v) => (
              <tr key={v.id}>
                <td>
                  <div>
                    <p style={{ fontFamily: 'monospace', fontWeight: '700', fontSize: '13px' }}>{v.code}</p>
                    <p style={{ fontSize: '11px', color: 'var(--color-text-muted)' }}>{v.description}</p>
                  </div>
                </td>
                <td style={{ fontWeight: '700', color: 'var(--color-primary)', fontSize: '15px' }}>{formatDiscount(v)}</td>
                <td style={{ color: 'var(--color-text-secondary)', fontSize: '13px' }}>{new Intl.NumberFormat('id-ID', { style: 'currency', currency: 'IDR' }).format(v.min_transaction)}</td>
                <td style={{ fontSize: '13px' }}>{v.current_usage}/{v.max_usage}</td>
                <td style={{ fontSize: '12px', color: 'var(--color-text-secondary)' }}>
                  <div>{new Date(v.start_date).toLocaleDateString('id-ID')}</div>
                  <div style={{ color: 'var(--color-text-muted)' }}>s/d {new Date(v.end_date).toLocaleDateString('id-ID')}</div>
                </td>
                <td><StatusBadge status={v.status} config={statusCfg} /></td>
                <td><button onClick={() => handleDelete(v.id)} className="tc-btn tc-btn-ghost" style={{ color: 'var(--color-error)', padding: '4px 8px', fontSize: '13px' }}>Hapus</button></td>
              </tr>
            ))}
          </tbody>
        </table>
        {vouchers.length === 0 && <EmptyState icon="🎫" title="Belum ada voucher" description="Klik 'Tambah Voucher' untuk menambahkan." />}
      </div>

      <Modal open={showModal} onClose={() => setShowModal(false)} title="Tambah Voucher Baru" maxWidth="560px">
        <form onSubmit={handleSubmit}>
          <div style={{ display: 'flex', flexDirection: 'column', gap: '14px' }}>
            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '14px' }}>
              <div>
                <label className="tc-label">Kode Voucher *</label>
                <input type="text" value={formData.code} onChange={(e) => setFormData({ ...formData, code: e.target.value.toUpperCase() })} className="tc-input" style={{ fontFamily: 'monospace', textTransform: 'uppercase' }} required />
              </div>
              <div>
                <label className="tc-label">Jenis Diskon *</label>
                <select value={formData.discount_type} onChange={(e) => setFormData({ ...formData, discount_type: e.target.value })} className="tc-select">
                  <option value="nominal">Nominal (Rp)</option>
                  <option value="percentage">Persen (%)</option>
                </select>
              </div>
            </div>
            <div>
              <label className="tc-label">Deskripsi</label>
              <input type="text" value={formData.description} onChange={(e) => setFormData({ ...formData, description: e.target.value })} className="tc-input" />
            </div>
            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '14px' }}>
              <div>
                <label className="tc-label">Nilai Diskon *</label>
                <input type="number" value={formData.discount_value} onChange={(e) => setFormData({ ...formData, discount_value: e.target.value })} className="tc-input" required min="0" />
              </div>
              <div>
                <label className="tc-label">Min. Transaksi</label>
                <input type="number" value={formData.min_transaction} onChange={(e) => setFormData({ ...formData, min_transaction: e.target.value })} className="tc-input" min="0" />
              </div>
            </div>
            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr 1fr', gap: '14px' }}>
              <div>
                <label className="tc-label">Max. Penggunaan *</label>
                <input type="number" value={formData.max_usage} onChange={(e) => setFormData({ ...formData, max_usage: e.target.value })} className="tc-input" required min="1" />
              </div>
              <div>
                <label className="tc-label">Tanggal Mulai *</label>
                <input type="date" value={formData.start_date} onChange={(e) => setFormData({ ...formData, start_date: e.target.value })} className="tc-input" required />
              </div>
              <div>
                <label className="tc-label">Tanggal Berakhir *</label>
                <input type="date" value={formData.end_date} onChange={(e) => setFormData({ ...formData, end_date: e.target.value })} className="tc-input" required />
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
