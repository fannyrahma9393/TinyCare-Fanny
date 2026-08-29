import { useState, useEffect } from 'react';
import { invoicesAPI, childrenAPI } from '../services/api';
import { PageHeader, Modal, EmptyState } from '../components/PageHeader';

export default function Invoices() {
  const [invoices, setInvoices] = useState([]);
  const [children, setChildren] = useState([]);
  const [loading, setLoading] = useState(true);
  const [showModal, setShowModal] = useState(false);
  const [filter, setFilter] = useState('');
  const [formData, setFormData] = useState({ child_id: '', package_id: '', due_date: '', voucher_code: '', notes: '' });

  async function loadInvoices() {
    setLoading(true);
    try { const params = { per_page: 50 }; if (filter) params.status = filter; const res = await invoicesAPI.list(params); setInvoices(res.data.data.data || []); }
    catch (error) { console.error('Error:', error); } finally { setLoading(false); }
  }
  async function loadChildren() {
    try { const res = await childrenAPI.list({ per_page: 100 }); setChildren(res.data.data.data || []); }
    catch (error) { console.error('Error:', error); }
  }

  useEffect(() => { loadInvoices(); loadChildren(); }, [filter]);

  const handleSubmit = async (e) => {
    e.preventDefault();
    try { await invoicesAPI.create(formData); setShowModal(false); setFormData({ child_id: '', package_id: '', due_date: '', voucher_code: '', notes: '' }); loadInvoices(); }
    catch (error) { alert(error.response?.data?.message || 'Gagal membuat invoice.'); }
  };

  const handleStatusUpdate = async (id, status) => {
    if (confirm(`Yakin ingin mengubah status ke "${status}"?`)) {
      try { await invoicesAPI.updateStatus(id, { status }); loadInvoices(); }
      catch (error) { alert(error.response?.data?.message || 'Gagal mengubah status.'); }
    }
  };

  const statusConfig = {
    pending: { label: 'Menunggu', color: 'var(--color-warning)', bg: 'var(--color-warning-bg)' },
    paid: { label: 'Lunas', color: 'var(--color-success)', bg: 'var(--color-success-bg)' },
    failed: { label: 'Gagal', color: 'var(--color-error)', bg: 'var(--color-error-bg)' },
    expired: { label: 'Kedaluwarsa', color: 'var(--color-text-muted)', bg: 'var(--color-bg-alt)' },
    cancelled: { label: 'Dibatalkan', color: 'var(--color-text-muted)', bg: 'var(--color-bg-alt)' },
  };

  const formatCurrency = (amount) => new Intl.NumberFormat('id-ID', { style: 'currency', currency: 'IDR' }).format(amount);

  if (loading) return <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'center', height: '300px' }}><div className="tc-spinner"></div></div>;

  return (
    <div>
      <PageHeader title="Manajemen Invoice" subtitle="Kelola tagihan dan pembayaran" action={<button onClick={() => setShowModal(true)} className="tc-btn tc-btn-primary">+ Buat Invoice</button>} />

      <div style={{ display: 'flex', gap: '6px', marginBottom: '20px', flexWrap: 'wrap' }}>
        {[{ value: '', label: 'Semua' }, { value: 'pending', label: 'Menunggu' }, { value: 'paid', label: 'Lunas' }, { value: 'failed', label: 'Gagal' }, { value: 'cancelled', label: 'Dibatalkan' }].map((tab) => (
          <button key={tab.value} onClick={() => setFilter(tab.value)} className={filter === tab.value ? 'tc-btn tc-btn-primary' : 'tc-btn tc-btn-secondary'} style={{ padding: '7px 14px', fontSize: '13px' }}>{tab.label}</button>
        ))}
      </div>

      <div className="tc-card" style={{ overflow: 'hidden' }}>
        <table className="tc-table">
          <thead>
            <tr>
              <th>No. Invoice</th>
              <th>Anak</th>
              <th>Paket</th>
              <th>Subtotal</th>
              <th>Diskon</th>
              <th>Total</th>
              <th>Jatuh Tempo</th>
              <th>Status</th>
              <th>Aksi</th>
            </tr>
          </thead>
          <tbody>
            {invoices.map((invoice) => {
              const status = statusConfig[invoice.status] || statusConfig.pending;
              return (
                <tr key={invoice.id}>
                  <td style={{ fontFamily: 'monospace', fontWeight: '600', fontSize: '13px' }}>{invoice.invoice_number}</td>
                  <td style={{ fontSize: '13px' }}>{invoice.child?.name}</td>
                  <td style={{ fontSize: '13px', color: 'var(--color-text-secondary)' }}>{invoice.package?.name}</td>
                  <td style={{ fontSize: '13px', color: 'var(--color-text-secondary)' }}>{formatCurrency(invoice.subtotal)}</td>
                  <td style={{ fontSize: '13px', color: invoice.discount > 0 ? 'var(--color-success)' : 'var(--color-text-muted)' }}>
                    {invoice.discount > 0 ? '-' + formatCurrency(invoice.discount) : '-'}
                  </td>
                  <td style={{ fontSize: '14px', fontWeight: '700' }}>{formatCurrency(invoice.total)}</td>
                  <td style={{ fontSize: '12px', color: 'var(--color-text-secondary)' }}>{new Date(invoice.due_date).toLocaleDateString('id-ID')}</td>
                  <td><span className="tc-badge" style={{ background: status.bg, color: status.color }}>{status.label}</span></td>
                  <td>
                    {invoice.status === 'pending' && (
                      <div style={{ display: 'flex', gap: '4px' }}>
                        <button onClick={() => handleStatusUpdate(invoice.id, 'paid')} className="tc-btn tc-btn-ghost" style={{ color: 'var(--color-success)', padding: '4px 8px', fontSize: '12px' }}>Bayar</button>
                        <button onClick={() => handleStatusUpdate(invoice.id, 'cancelled')} className="tc-btn tc-btn-ghost" style={{ color: 'var(--color-error)', padding: '4px 8px', fontSize: '12px' }}>Batal</button>
                      </div>
                    )}
                  </td>
                </tr>
              );
            })}
          </tbody>
        </table>
        {invoices.length === 0 && <EmptyState icon="💳" title="Belum ada invoice" />}
      </div>

      <Modal open={showModal} onClose={() => setShowModal(false)} title="Buat Invoice Baru">
        <form onSubmit={handleSubmit}>
          <div style={{ display: 'flex', flexDirection: 'column', gap: '14px' }}>
            <div>
              <label className="tc-label">Anak *</label>
              <select value={formData.child_id} onChange={(e) => setFormData({ ...formData, child_id: e.target.value })} className="tc-select" required>
                <option value="">-- Pilih Anak --</option>
                {children.map((c) => <option key={c.id} value={c.id}>{c.name}</option>)}
              </select>
            </div>
            <div>
              <label className="tc-label">Package ID *</label>
              <input type="text" value={formData.package_id} onChange={(e) => setFormData({ ...formData, package_id: e.target.value })} className="tc-input" required />
            </div>
            <div>
              <label className="tc-label">Tanggal Jatuh Tempo *</label>
              <input type="date" value={formData.due_date} onChange={(e) => setFormData({ ...formData, due_date: e.target.value })} className="tc-input" required />
            </div>
            <div>
              <label className="tc-label">Kode Voucher (opsional)</label>
              <input type="text" value={formData.voucher_code} onChange={(e) => setFormData({ ...formData, voucher_code: e.target.value.toUpperCase() })} className="tc-input" style={{ fontFamily: 'monospace', textTransform: 'uppercase' }} />
            </div>
            <div>
              <label className="tc-label">Catatan</label>
              <textarea value={formData.notes} onChange={(e) => setFormData({ ...formData, notes: e.target.value })} className="tc-input" rows="2" />
            </div>
          </div>
          <div style={{ display: 'flex', gap: '10px', marginTop: '20px' }}>
            <button type="button" onClick={() => setShowModal(false)} className="tc-btn tc-btn-secondary" style={{ flex: 1 }}>Batal</button>
            <button type="submit" className="tc-btn tc-btn-primary" style={{ flex: 1 }}>Buat Invoice</button>
          </div>
        </form>
      </Modal>
    </div>
  );
}
