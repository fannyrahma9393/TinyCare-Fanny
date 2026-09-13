import { useState, useEffect } from 'react';
import { useSearchParams } from 'react-router-dom';
import { invoicesAPI, childrenAPI, unwrapList } from '../services/api';
import { PageHeader, Modal, EmptyState } from '../components/PageHeader';

export default function Invoices() {
  const [invoices, setInvoices] = useState([]);
  const [children, setChildren] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [showModal, setShowModal] = useState(false);
  const [searchParams] = useSearchParams();
  const [filter, setFilter] = useState(searchParams.get('filter') || '');
  const [formData, setFormData] = useState({ child_id: '', package_id: '', due_date: '', voucher_code: '', notes: '' });
  const selectedChild = children.find((c) => String(c.id) === String(formData.child_id));
  const availablePackages = selectedChild
    ? (selectedChild.child_packages || [])
        .filter((cp) => cp.status === 'active' && cp.package)
        .map((cp) => ({ id: cp.package.id, name: cp.package.name, price: cp.package.price }))
    : [];

  async function loadInvoices() {
    setLoading(true);
    setError('');
    try {
      const params = { per_page: 50 };
      if (filter) params.status = filter;
      const res = await invoicesAPI.list(params);
      setInvoices(unwrapList(res));
    } catch (error) {
      setError(error.response?.data?.message || 'Gagal memuat daftar invoice.');
    } finally {
      setLoading(false);
    }
  }
  async function loadChildren() {
    try { const res = await childrenAPI.list({ per_page: 100 }); setChildren(unwrapList(res)); }
    catch (error) { setError(error.response?.data?.message || 'Gagal memuat data anak.'); }
  }

  useEffect(() => { loadInvoices(); loadChildren(); }, [filter]);

  useEffect(() => {
    setFilter(searchParams.get('filter') || '');
  }, [searchParams]);

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

  const formatCurrency = (amount) => {
    const num = Number(amount);
    if (num <= 0 || Number.isNaN(num)) return 'Rp 0';
    return new Intl.NumberFormat('id-ID', { style: 'currency', currency: 'IDR' }).format(num);
  };

  if (loading) return <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'center', height: '300px' }}><div className="tc-spinner"></div></div>;

  return (
    <div>
      <PageHeader title="Manajemen Invoice" subtitle="Kelola tagihan dan pembayaran" action={<button onClick={() => setShowModal(true)} className="tc-btn tc-btn-primary">+ Buat Invoice</button>} />

      <div style={{ display: 'flex', gap: '6px', marginBottom: '20px', flexWrap: 'wrap' }}>
        {[{ value: '', label: 'Semua' }, { value: 'pending', label: 'Menunggu' }, { value: 'paid', label: 'Lunas' }, { value: 'failed', label: 'Gagal' }, { value: 'cancelled', label: 'Dibatalkan' }].map((tab) => (
          <button key={tab.value} onClick={() => setFilter(tab.value)} className={filter === tab.value ? 'tc-btn tc-btn-primary' : 'tc-btn tc-btn-secondary'} style={{ padding: '7px 14px', fontSize: '13px' }}>{tab.label}</button>
        ))}
      </div>

      {error && (
        <div className="tc-error-state" style={{ marginBottom: '16px' }}>
          <p className="tc-empty-state-title">{error}</p>
          <button onClick={loadInvoices} className="tc-btn tc-btn-secondary tc-btn-sm" style={{ marginTop: '12px' }}>Coba Lagi</button>
        </div>
      )}

      <div className="tc-card" style={{ overflow: 'hidden' }}>
        <div style={{ overflowX: 'auto' }}>
        <table className="tc-table" style={{ minWidth: '900px' }}>
          <thead>
            <tr>
              <th style={{ whiteSpace: 'nowrap' }}>No. Invoice</th>
              <th>Anak</th>
              <th>Paket</th>
              <th style={{ textAlign: 'right' }}>Subtotal</th>
              <th style={{ textAlign: 'right' }}>Diskon</th>
              <th style={{ textAlign: 'right' }}>Total</th>
              <th style={{ whiteSpace: 'nowrap' }}>Jatuh Tempo</th>
              <th>Status</th>
              <th style={{ position: 'sticky', right: 0, background: 'var(--color-surface)', zIndex: 1, textAlign: 'center' }}>Aksi</th>
            </tr>
          </thead>
          <tbody>
            {invoices.map((invoice) => {
              const status = statusConfig[invoice.status] || statusConfig.pending;
              return (
                <tr key={invoice.id}>
                  <td style={{ fontFamily: 'monospace', fontWeight: '600', fontSize: '13px', whiteSpace: 'nowrap' }}>{invoice.invoice_number}</td>
                  <td style={{ fontSize: '13px' }}>{invoice.child?.name}</td>
                  <td style={{ fontSize: '13px', color: 'var(--color-text-secondary)' }}>{invoice.package?.name}</td>
                  <td style={{ fontSize: '13px', color: 'var(--color-text-secondary)', textAlign: 'right' }}>{formatCurrency(invoice.subtotal)}</td>
                  <td style={{ fontSize: '13px', color: invoice.discount > 0 ? 'var(--color-success)' : 'var(--color-text-muted)', textAlign: 'right' }}>
                    {invoice.discount > 0 ? '-' + formatCurrency(invoice.discount) : '-'}
                  </td>
                  <td style={{ fontSize: '14px', fontWeight: '700', textAlign: 'right' }}>{formatCurrency(invoice.total)}</td>
                  <td style={{ fontSize: '12px', color: 'var(--color-text-secondary)', whiteSpace: 'nowrap' }}>{new Date(invoice.due_date).toLocaleDateString('id-ID')}</td>
                  <td><span className="tc-badge" style={{ background: status.bg, color: status.color }}>{status.label}</span></td>
                  <td style={{ position: 'sticky', right: 0, background: 'var(--color-surface)', zIndex: 1 }}>
                    {invoice.status === 'pending' && (
                      <div style={{ display: 'flex', gap: '4px', justifyContent: 'center' }}>
                        <button onClick={() => handleStatusUpdate(invoice.id, 'paid')} className="tc-btn tc-btn-ghost" style={{ color: 'var(--color-success)', padding: '4px 8px', fontSize: '12px', whiteSpace: 'nowrap' }}>Bayar</button>
                        <button onClick={() => handleStatusUpdate(invoice.id, 'cancelled')} className="tc-btn tc-btn-ghost" style={{ color: 'var(--color-error)', padding: '4px 8px', fontSize: '12px', whiteSpace: 'nowrap' }}>Batal</button>
                      </div>
                    )}
                  </td>
                </tr>
              );
            })}
          </tbody>
        </table>
        </div>
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
              <label className="tc-label">Paket *</label>
              <select value={formData.package_id} onChange={(e) => setFormData({ ...formData, package_id: e.target.value })} className="tc-select" required>
                <option value="">{selectedChild ? '-- Pilih Paket --' : '-- Pilih Anak terlebih dahulu --'}</option>
                {availablePackages.map((pkg) => <option key={pkg.id} value={pkg.id}>{pkg.name} · {formatCurrency(pkg.price)}</option>)}
              </select>
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
