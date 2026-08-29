import { useState, useEffect } from 'react';
import { paymentsAPI } from '../services/api';
import { PageHeader, Modal, EmptyState } from '../components/PageHeader';

export default function Payments() {
  const [payments, setPayments] = useState([]);
  const [loading, setLoading] = useState(true);
  const [filter, setFilter] = useState('');
  const [selectedProof, setSelectedProof] = useState(null);

  async function loadPayments() {
    setLoading(true);
    try { const params = { per_page: 50 }; if (filter) params.status = filter; const res = await paymentsAPI.list(params); setPayments(res.data.data.data || []); }
    catch (error) { console.error('Error:', error); } finally { setLoading(false); }
  }

  useEffect(() => { loadPayments(); }, [filter]);

  const handleVerify = async (id) => {
    if (confirm('Yakin ingin memverifikasi pembayaran ini?')) {
      try { await paymentsAPI.verify(id); loadPayments(); } catch (error) { alert(error.response?.data?.message || 'Gagal memverifikasi.'); }
    }
  };

  const handleReject = async (id) => {
    const reason = prompt('Alasan penolakan:');
    if (reason !== null) {
      try { await paymentsAPI.reject(id, { reason }); loadPayments(); } catch (error) { alert(error.response?.data?.message || 'Gagal menolak.'); }
    }
  };

  const viewProof = async (id) => {
    try { const res = await paymentsAPI.getProof(id); setSelectedProof(res.data.data); }
    catch { alert('Gagal memuat bukti pembayaran.'); }
  };

  const statusConfig = {
    pending: { label: 'Menunggu', color: 'var(--color-warning)', bg: 'var(--color-warning-bg)' },
    verified: { label: 'Terverifikasi', color: 'var(--color-success)', bg: 'var(--color-success-bg)' },
    rejected: { label: 'Ditolak', color: 'var(--color-error)', bg: 'var(--color-error-bg)' },
  };

  const formatCurrency = (amount) => new Intl.NumberFormat('id-ID', { style: 'currency', currency: 'IDR' }).format(amount);

  if (loading) return <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'center', height: '300px' }}><div className="tc-spinner"></div></div>;

  return (
    <div>
      <PageHeader title="Manajemen Pembayaran" subtitle="Verifikasi bukti pembayaran dari orang tua" />

      <div style={{ display: 'flex', gap: '6px', marginBottom: '20px' }}>
        {[{ value: '', label: 'Semua' }, { value: 'pending', label: 'Menunggu' }, { value: 'verified', label: 'Terverifikasi' }, { value: 'rejected', label: 'Ditolak' }].map((tab) => (
          <button key={tab.value} onClick={() => setFilter(tab.value)} className={filter === tab.value ? 'tc-btn tc-btn-primary' : 'tc-btn tc-btn-secondary'} style={{ padding: '7px 14px', fontSize: '13px' }}>{tab.label}</button>
        ))}
      </div>

      <div className="tc-card" style={{ overflow: 'hidden' }}>
        <table className="tc-table">
          <thead>
            <tr>
              <th>Invoice</th>
              <th>Anak</th>
              <th>Jumlah</th>
              <th>Metode</th>
              <th>Tanggal</th>
              <th>Status</th>
              <th>Aksi</th>
            </tr>
          </thead>
          <tbody>
            {payments.map((payment) => {
              const status = statusConfig[payment.status] || statusConfig.pending;
              return (
                <tr key={payment.id}>
                  <td style={{ fontFamily: 'monospace', fontSize: '13px' }}>{payment.invoice?.invoice_number}</td>
                  <td style={{ fontSize: '13px' }}>{payment.invoice?.child?.name}</td>
                  <td style={{ fontSize: '14px', fontWeight: '700' }}>{formatCurrency(payment.amount)}</td>
                  <td style={{ fontSize: '13px', color: 'var(--color-text-secondary)' }}>{payment.payment_method || '-'}</td>
                  <td style={{ fontSize: '12px', color: 'var(--color-text-secondary)' }}>{new Date(payment.created_at).toLocaleDateString('id-ID')}</td>
                  <td><span className="tc-badge" style={{ background: status.bg, color: status.color }}>{status.label}</span></td>
                  <td>
                    <div style={{ display: 'flex', gap: '4px' }}>
                      {payment.proof_file && (
                        <button onClick={() => viewProof(payment.id)} className="tc-btn tc-btn-ghost" style={{ color: 'var(--color-info)', padding: '4px 8px', fontSize: '12px' }}>Bukti</button>
                      )}
                      {payment.status === 'pending' && (
                        <>
                          <button onClick={() => handleVerify(payment.id)} className="tc-btn tc-btn-ghost" style={{ color: 'var(--color-success)', padding: '4px 8px', fontSize: '12px' }}>Verifikasi</button>
                          <button onClick={() => handleReject(payment.id)} className="tc-btn tc-btn-ghost" style={{ color: 'var(--color-error)', padding: '4px 8px', fontSize: '12px' }}>Tolak</button>
                        </>
                      )}
                    </div>
                  </td>
                </tr>
              );
            })}
          </tbody>
        </table>
        {payments.length === 0 && <EmptyState icon="💰" title="Belum ada pembayaran" />}
      </div>

      <Modal open={!!selectedProof} onClose={() => setSelectedProof(null)} title="Bukti Pembayaran">
        {selectedProof && (
          <div style={{ textAlign: 'center' }}>
            <p style={{ fontSize: '13px', color: 'var(--color-text-secondary)', marginBottom: '16px' }}>
              <a href={selectedProof.url} target="_blank" rel="noopener noreferrer" style={{ color: 'var(--color-primary)', textDecoration: 'underline' }}>
                {selectedProof.url?.substring(0, 60)}...
              </a>
            </p>
            <a href={selectedProof.url} target="_blank" rel="noopener noreferrer" className="tc-btn tc-btn-primary">Buka Bukti</a>
          </div>
        )}
      </Modal>
    </div>
  );
}
