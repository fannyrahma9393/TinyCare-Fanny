import { useState, useEffect } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import { parentAPI } from '../../services/api';

export default function ParentInvoiceDetail() {
  const { id } = useParams();
  const navigate = useNavigate();
  const [invoice, setInvoice] = useState(null);
  const [payments, setPayments] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [paying, setPaying] = useState(false);
  const [paymentInfo, setPaymentInfo] = useState(null);
  const [showProofForm, setShowProofForm] = useState(false);
  const [proofFile, setProofFile] = useState(null);
  const [proofMethod, setProofMethod] = useState('bank_transfer');
  const [proofNotes, setProofNotes] = useState('');
  const [submittingProof, setSubmittingProof] = useState(false);
  const [copied, setCopied] = useState(false);

  useEffect(() => { loadData(); }, [id]);

  async function loadData() {
    try {
      const [invRes, payRes] = await Promise.all([
        parentAPI.invoiceDetail(id),
        parentAPI.invoicePayments(id).catch(() => ({ data: { data: [] } })),
      ]);
      setInvoice(invRes.data.data);
      setPayments(payRes.data.data || []);
    } catch {
      setError('Gagal memuat detail invoice.');
    } finally {
      setLoading(false);
    }
  }

  async function handleInitiatePayment() {
    setPaying(true);
    try {
      const res = await parentAPI.initiatePayment(id, { payment_method: 'bank_transfer' });
      setPaymentInfo(res.data.data);
    } catch (err) {
      alert(err.response?.data?.message || 'Gagal memulai pembayaran.');
    } finally {
      setPaying(false);
    }
  }

  async function handleSubmitProof(e) {
    e.preventDefault();
    if (!proofFile) return alert('Pilih bukti pembayaran.');
    setSubmittingProof(true);
    try {
      const formData = new FormData();
      formData.append('invoice_id', invoice.id);
      formData.append('amount', invoice.total);
      formData.append('payment_method', proofMethod);
      formData.append('proof_file', proofFile);
      if (proofNotes) formData.append('notes', proofNotes);
      await parentAPI.submitPayment(formData);
      alert('Bukti pembayaran berhasil dikirim! Menunggu verifikasi admin.');
      setShowProofForm(false);
      loadData();
    } catch (err) {
      alert(err.response?.data?.message || 'Gagal mengirim bukti pembayaran.');
    } finally {
      setSubmittingProof(false);
    }
  }

  function copyToClipboard(text) {
    navigator.clipboard.writeText(text);
    setCopied(true);
    setTimeout(() => setCopied(false), 2000);
  }

  const formatCurrency = (v) => new Intl.NumberFormat('id-ID', { style: 'currency', currency: 'IDR' }).format(v);

  const statusConfig = {
    pending: { label: 'Menunggu Pembayaran', class: 'tc-badge-warning', icon: 'clock' },
    paid: { label: 'Lunas', class: 'tc-badge-success', icon: 'check' },
    failed: { label: 'Gagal', class: 'tc-badge-error', icon: 'x' },
    expired: { label: 'Kedaluwarsa', class: 'tc-badge-neutral', icon: 'clock' },
  };

  if (loading) return <div className="tc-loading-screen"><div className="tc-spinner tc-spinner-lg"></div><p>Memuat invoice...</p></div>;
  if (error) return (
    <div className="tc-error-state">
      <div className="tc-error-state-icon"><svg width="28" height="28" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8"><circle cx="12" cy="12" r="10"/><line x1="12" y1="8" x2="12" y2="12"/><line x1="12" y1="16" x2="12.01" y2="16"/></svg></div>
      <p className="tc-empty-state-title">{error}</p>
      <button onClick={() => navigate('/parent/invoices')} className="tc-btn tc-btn-secondary tc-btn-sm" style={{ marginTop: '12px' }}>Kembali</button>
    </div>
  );
  if (!invoice) return null;

  const st = statusConfig[invoice.status] || statusConfig.pending;
  const isPaid = invoice.status === 'paid';
  const isPending = invoice.status === 'pending';
  const hasPendingPayment = payments.some(p => p.status === 'pending');

  return (
    <div>
      <button onClick={() => navigate('/parent/invoices')} style={{ background: 'none', border: 'none', color: 'var(--color-primary)', cursor: 'pointer', fontSize: '13px', marginBottom: '16px', display: 'flex', alignItems: 'center', gap: '4px', fontWeight: 500 }}>
        <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><polyline points="15 18 9 12 15 6"/></svg>
        Kembali ke Tagihan
      </button>

      {/* Invoice Header */}
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', marginBottom: '24px', flexWrap: 'wrap', gap: '12px' }}>
        <div>
          <h1 style={{ fontSize: '22px', fontWeight: '700', letterSpacing: '-0.02em', marginBottom: '4px' }}>{invoice.invoice_number}</h1>
          <p style={{ fontSize: '13px', color: 'var(--color-text-secondary)' }}>
            {invoice.child?.name} · {invoice.package?.name}
          </p>
        </div>
        <span className={`tc-badge ${st.class}`} style={{ fontSize: '12px', padding: '5px 14px' }}>{st.label}</span>
      </div>

      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(340px, 1fr))', gap: '20px' }}>
        {/* Invoice Details */}
        <div className="tc-card" style={{ padding: '24px' }}>
          <h2 style={{ fontSize: '14px', fontWeight: '700', marginBottom: '16px' }}>Detail Invoice</h2>
          <div style={{ display: 'flex', flexDirection: 'column', gap: '12px' }}>
            <div style={{ display: 'flex', justifyContent: 'space-between', padding: '8px 0', borderBottom: '1px solid var(--color-border-light)' }}>
              <span style={{ fontSize: '13px', color: 'var(--color-text-muted)' }}>Anak</span>
              <span style={{ fontSize: '13px', fontWeight: '600' }}>{invoice.child?.name}</span>
            </div>
            <div style={{ display: 'flex', justifyContent: 'space-between', padding: '8px 0', borderBottom: '1px solid var(--color-border-light)' }}>
              <span style={{ fontSize: '13px', color: 'var(--color-text-muted)' }}>Paket</span>
              <span style={{ fontSize: '13px', fontWeight: '600' }}>{invoice.package?.name}</span>
            </div>
            <div style={{ display: 'flex', justifyContent: 'space-between', padding: '8px 0', borderBottom: '1px solid var(--color-border-light)' }}>
              <span style={{ fontSize: '13px', color: 'var(--color-text-muted)' }}>Subtotal</span>
              <span style={{ fontSize: '13px' }}>{formatCurrency(invoice.subtotal)}</span>
            </div>
            {invoice.discount > 0 && (
              <div style={{ display: 'flex', justifyContent: 'space-between', padding: '8px 0', borderBottom: '1px solid var(--color-border-light)' }}>
                <span style={{ fontSize: '13px', color: 'var(--color-text-muted)' }}>Diskon</span>
                <span style={{ fontSize: '13px', color: 'var(--color-success)' }}>- {formatCurrency(invoice.discount)}</span>
              </div>
            )}
            <div style={{ display: 'flex', justifyContent: 'space-between', padding: '10px 0' }}>
              <span style={{ fontSize: '14px', fontWeight: '700' }}>Total</span>
              <span style={{ fontSize: '18px', fontWeight: '700', color: 'var(--color-primary)' }}>{formatCurrency(invoice.total)}</span>
            </div>
            <div style={{ display: 'flex', justifyContent: 'space-between', padding: '8px 0', borderTop: '1px solid var(--color-border-light)' }}>
              <span style={{ fontSize: '13px', color: 'var(--color-text-muted)' }}>Jatuh Tempo</span>
              <span style={{ fontSize: '13px', color: isPending && new Date(invoice.due_date) < new Date() ? 'var(--color-error)' : 'inherit' }}>
                {new Date(invoice.due_date).toLocaleDateString('id-ID', { weekday: 'long', year: 'numeric', month: 'long', day: 'numeric' })}
              </span>
            </div>
          </div>
        </div>

        {/* Payment Section */}
        <div className="tc-card" style={{ padding: '24px' }}>
          <h2 style={{ fontSize: '14px', fontWeight: '700', marginBottom: '16px' }}>Pembayaran</h2>

          {isPaid ? (
            <div>
              <div style={{ padding: '16px', borderRadius: 'var(--radius-lg)', background: 'var(--color-success-bg)', marginBottom: '16px', textAlign: 'center' }}>
                <svg width="32" height="32" viewBox="0 0 24 24" fill="none" stroke="var(--color-success)" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" style={{ margin: '0 auto 8px' }}><path d="M22 11.08V12a10 10 0 11-5.93-9.14"/><polyline points="22 4 12 14.01 9 11.01"/></svg>
                <p style={{ fontSize: '14px', fontWeight: '600', color: 'var(--color-success)' }}>Pembayaran Berhasil</p>
                <p style={{ fontSize: '12px', color: 'var(--color-text-muted)', marginTop: '4px' }}>Invoice ini sudah lunas.</p>
              </div>
              {payments.filter(p => p.status === 'verified').map(p => (
                <div key={p.id} style={{ padding: '12px', borderRadius: 'var(--radius-md)', background: 'var(--color-bg-alt)', marginBottom: '8px' }}>
                  <p style={{ fontSize: '12px', color: 'var(--color-text-muted)' }}>Dibayar pada: {new Date(p.paid_at || p.verified_at).toLocaleDateString('id-ID', { year: 'numeric', month: 'long', day: 'numeric' })}</p>
                  <p style={{ fontSize: '12px', color: 'var(--color-text-muted)' }}>Metode: {p.payment_method || 'Bank Transfer'}</p>
                </div>
              ))}
            </div>
          ) : paymentInfo ? (
            /* Payment Instructions */
            <div>
              <div style={{ padding: '16px', borderRadius: 'var(--radius-lg)', background: 'var(--color-info-bg)', marginBottom: '16px', textAlign: 'center' }}>
                <p style={{ fontSize: '13px', fontWeight: '600', color: 'var(--color-info)', marginBottom: '4px' }}>Virtual Account</p>
                <p style={{ fontSize: '22px', fontWeight: '800', letterSpacing: '0.05em', fontFamily: 'monospace' }}>{paymentInfo.va_number}</p>
                <p style={{ fontSize: '12px', color: 'var(--color-text-muted)', marginTop: '4px' }}>{paymentInfo.bank_name} · {paymentInfo.account_name}</p>
              </div>

              <div style={{ marginBottom: '16px' }}>
                <p style={{ fontSize: '13px', fontWeight: '600', marginBottom: '8px' }}>Transfer sebesar:</p>
                <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                  <span style={{ fontSize: '20px', fontWeight: '700', color: 'var(--color-primary)' }}>{formatCurrency(paymentInfo.total_with_code || paymentInfo.amount)}</span>
                  <button onClick={() => copyToClipboard(String(paymentInfo.total_with_code || paymentInfo.amount))} style={{ padding: '4px 8px', border: '1px solid var(--color-border)', borderRadius: 'var(--radius-sm)', background: 'var(--color-surface)', cursor: 'pointer', fontSize: '11px', color: 'var(--color-text-muted)' }}>
                    {copied ? '✓' : 'Salin'}
                  </button>
                </div>
                <p style={{ fontSize: '11px', color: 'var(--color-text-muted)', marginTop: '4px' }}>Termasuk digit unik: +{paymentInfo.total_with_code - paymentInfo.amount}</p>
              </div>

              {/* Instructions */}
              <div style={{ marginBottom: '16px' }}>
                <p style={{ fontSize: '13px', fontWeight: '600', marginBottom: '8px' }}>Cara Pembayaran:</p>
                {paymentInfo.instructions && Object.entries(paymentInfo.instructions).map(([method, instruction]) => (
                  <div key={method} style={{ padding: '10px', borderRadius: 'var(--radius-md)', background: 'var(--color-bg-alt)', marginBottom: '6px' }}>
                    <p style={{ fontSize: '11px', fontWeight: '600', color: 'var(--color-text-muted)', textTransform: 'uppercase', marginBottom: '2px' }}>{method}</p>
                    <p style={{ fontSize: '12px', color: 'var(--color-text-secondary)' }}>{instruction}</p>
                  </div>
                ))}
              </div>

              {paymentInfo.expires_at && (
                <p style={{ fontSize: '12px', color: 'var(--color-warning)', marginBottom: '16px' }}>
                  ⚠️ Berlaku hingga: {new Date(paymentInfo.expires_at).toLocaleString('id-ID')}
                </p>
              )}

              {/* Upload Proof */}
              <button onClick={() => setShowProofForm(!showProofForm)} className="tc-btn tc-btn-primary" style={{ width: '100%' }}>
                {showProofForm ? 'Tutup' : 'Kirim Bukti Pembayaran'}
              </button>
            </div>
          ) : (
            /* Pay Button */
            <div style={{ textAlign: 'center', padding: '20px 0' }}>
              <p style={{ fontSize: '13px', color: 'var(--color-text-secondary)', marginBottom: '16px' }}>
                {hasPendingPayment ? 'Pembayaran sebelumnya masih dalam proses verifikasi.' : 'Klik tombol di bawah untuk memulai pembayaran.'}
              </p>
              {!hasPendingPayment && (
                <button onClick={handleInitiatePayment} disabled={paying} className="tc-btn tc-btn-primary tc-btn-lg" style={{ width: '100%' }}>
                  {paying ? 'Memproses...' : 'Bayar Sekarang'}
                </button>
              )}
            </div>
          )}

          {/* Proof Upload Form */}
          {showProofForm && (
            <form onSubmit={handleSubmitProof} style={{ marginTop: '16px', padding: '16px', borderRadius: 'var(--radius-lg)', background: 'var(--color-bg-alt)' }}>
              <p style={{ fontSize: '13px', fontWeight: '600', marginBottom: '12px' }}>Upload Bukti Pembayaran</p>
              <div style={{ marginBottom: '12px' }}>
                <label className="tc-label">Metode Pembayaran</label>
                <select value={proofMethod} onChange={(e) => setProofMethod(e.target.value)} className="tc-select">
                  <option value="bank_transfer">Bank Transfer</option>
                  <option value="ewallet">E-Wallet</option>
                  <option value="cash">Tunai</option>
                </select>
              </div>
              <div style={{ marginBottom: '12px' }}>
                <label className="tc-label">Bukti Pembayaran *</label>
                <input type="file" accept="image/*,.pdf" onChange={(e) => setProofFile(e.target.files[0])} className="tc-input" required />
                <p className="tc-helper">Format: JPG, PNG, atau PDF. Maks 5MB.</p>
              </div>
              <div style={{ marginBottom: '12px' }}>
                <label className="tc-label">Catatan (opsional)</label>
                <input type="text" value={proofNotes} onChange={(e) => setProofNotes(e.target.value)} className="tc-input" placeholder="Contoh: Transfer via BCA mobile" />
              </div>
              <button type="submit" disabled={submittingProof} className="tc-btn tc-btn-primary" style={{ width: '100%' }}>
                {submittingProof ? 'Mengirim...' : 'Kirim Bukti'}
              </button>
            </form>
          )}
        </div>
      </div>

      {/* Payment History */}
      {payments.length > 0 && (
        <div className="tc-card" style={{ padding: '20px', marginTop: '20px' }}>
          <h2 style={{ fontSize: '14px', fontWeight: '700', marginBottom: '14px' }}>Riwayat Pembayaran</h2>
          <div style={{ display: 'flex', flexDirection: 'column', gap: '8px' }}>
            {payments.map((p) => (
              <div key={p.id} style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', padding: '12px', borderRadius: 'var(--radius-md)', background: 'var(--color-bg-alt)' }}>
                <div>
                  <p style={{ fontSize: '13px', fontWeight: '600' }}>{formatCurrency(p.amount)}</p>
                  <p style={{ fontSize: '12px', color: 'var(--color-text-muted)' }}>{p.payment_method || 'Bank Transfer'} · {new Date(p.created_at).toLocaleDateString('id-ID')}</p>
                </div>
                <span className={`tc-badge ${p.status === 'verified' ? 'tc-badge-success' : p.status === 'pending' ? 'tc-badge-warning' : 'tc-badge-error'}`}>
                  {p.status === 'verified' ? 'Terverifikasi' : p.status === 'pending' ? 'Menunggu' : 'Ditolak'}
                </span>
              </div>
            ))}
          </div>
        </div>
      )}
    </div>
  );
}
