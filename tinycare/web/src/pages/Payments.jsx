import { useState, useEffect } from 'react';
import { paymentsAPI, unwrapList } from '../services/api';
import { PageHeader, Modal, EmptyState } from '../components/PageHeader';

export default function Payments() {
  const [payments, setPayments] = useState([]);
  const [loading, setLoading] = useState(true);
  const [filter, setFilter] = useState('');
  const [selectedDetail, setSelectedDetail] = useState(null);
  const [error, setError] = useState('');

  async function loadPayments() {
    setLoading(true);
    try { const params = { per_page: 50 }; if (filter) params.status = filter; const res = await paymentsAPI.list(params); setPayments(unwrapList(res)); }
    catch (error) { setError(error.response?.data?.message || 'Gagal memuat data pembayaran.'); } finally { setLoading(false); }
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

  const viewDetail = async (payment) => {
    try {
      let proofUrl = null;
      if (payment.proof_file) {
        const res = await paymentsAPI.getProof(payment.id);
        proofUrl = res.data.data?.url || null;
      }
      setSelectedDetail({ ...payment, proofUrl });
    }
    catch { setSelectedDetail({ ...payment, proofUrl: null }); }
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

      {error && (
        <div className="tc-error-state" style={{ marginBottom: '16px' }}>
          <p className="tc-empty-state-title">{error}</p>
          <button onClick={() => { setError(''); loadPayments(); }} className="tc-btn tc-btn-secondary tc-btn-sm" style={{ marginTop: '12px' }}>Coba Lagi</button>
        </div>
      )}

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
                      <button onClick={() => viewDetail(payment)} className="tc-btn tc-btn-ghost" style={{ color: 'var(--color-info)', padding: '4px 8px', fontSize: '12px' }}>Detail</button>
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

      <Modal open={!!selectedDetail} onClose={() => setSelectedDetail(null)} title="Detail Pembayaran">
        {selectedDetail && (
          <div>
            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '12px', marginBottom: '16px' }}>
              {[
                { label: 'No. Invoice', value: selectedDetail.invoice?.invoice_number || '-' },
                { label: 'Anak', value: selectedDetail.invoice?.child?.name || '-' },
                { label: 'Orang Tua', value: selectedDetail.invoice?.parent?.user?.name || '-' },
                { label: 'Metode', value: selectedDetail.payment_method || '-' },
                { label: 'Jumlah', value: formatCurrency(selectedDetail.amount) },
                { label: 'Tanggal', value: new Date(selectedDetail.created_at).toLocaleString('id-ID') },
              ].map((item) => (
                <div key={item.label} style={{ background: 'var(--color-bg-alt)', padding: '10px 14px', borderRadius: '10px' }}>
                  <p style={{ fontSize: '11px', fontWeight: '600', color: 'var(--color-text-muted)', textTransform: 'uppercase', letterSpacing: '0.04em', marginBottom: '4px' }}>{item.label}</p>
                  <p style={{ fontSize: '14px', fontWeight: '600', wordBreak: 'break-word' }}>{item.value}</p>
                </div>
              ))}
            </div>
            {selectedDetail.notes && (
              <div style={{ background: 'var(--color-bg-alt)', padding: '10px 14px', borderRadius: '10px', marginBottom: '16px' }}>
                <p style={{ fontSize: '11px', fontWeight: '600', color: 'var(--color-text-muted)', textTransform: 'uppercase', letterSpacing: '0.04em', marginBottom: '4px' }}>Catatan</p>
                <p style={{ fontSize: '13px' }}>{selectedDetail.notes}</p>
              </div>
            )}
            {selectedDetail.status === 'rejected' && selectedDetail.notes && (
              <div style={{ background: 'var(--color-error-bg)', padding: '10px 14px', borderRadius: '10px', marginBottom: '16px' }}>
                <p style={{ fontSize: '11px', fontWeight: '600', color: 'var(--color-error)', textTransform: 'uppercase', letterSpacing: '0.04em', marginBottom: '4px' }}>Alasan Penolakan</p>
                <p style={{ fontSize: '13px', color: 'var(--color-error)' }}>{selectedDetail.notes}</p>
              </div>
            )}
            {selectedDetail.proofUrl && (
              <div style={{ textAlign: 'center' }}>
                <p style={{ fontSize: '11px', fontWeight: '600', color: 'var(--color-text-muted)', textTransform: 'uppercase', letterSpacing: '0.04em', marginBottom: '8px' }}>Bukti Pembayaran</p>
                {/\.(jpg|jpeg|png|webp|gif)$/i.test(selectedDetail.proof_file || '') ? (
                  <a href={selectedDetail.proofUrl} target="_blank" rel="noopener noreferrer">
                    <img src={selectedDetail.proofUrl} alt="Bukti pembayaran" style={{ maxWidth: '100%', maxHeight: '320px', borderRadius: '12px', border: '1px solid var(--color-border)', objectFit: 'contain' }} onError={(e) => { e.currentTarget.style.display = 'none'; }} />
                  </a>
                ) : (
                  <a href={selectedDetail.proofUrl} target="_blank" rel="noopener noreferrer" className="tc-btn tc-btn-primary">Buka Bukti (PDF)</a>
                )}
              </div>
            )}
            <div style={{ marginTop: '18px', display: 'flex', justifyContent: 'flex-end' }}>
              <button onClick={() => setSelectedDetail(null)} className="tc-btn tc-btn-secondary tc-btn-sm">Tutup</button>
            </div>
          </div>
        )}
      </Modal>
    </div>
  );
}
