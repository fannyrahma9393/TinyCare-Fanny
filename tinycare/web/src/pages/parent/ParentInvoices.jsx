import { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { parentAPI, unwrapList } from '../../services/api';
import { useTranslation } from 'react-i18next';

export default function ParentInvoices() {
  const { t } = useTranslation();
  const [invoices, setInvoices] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const navigate = useNavigate();

  useEffect(() => {
    parentAPI.invoices()
      .then((res) => setInvoices(unwrapList(res)))
      .catch(() => setError(t('Gagal memuat invoice.')))
      .finally(() => setLoading(false));
  }, []);

  const formatCurrency = (amount) => new Intl.NumberFormat('id-ID', { style: 'currency', currency: 'IDR' }).format(amount);

  const statusConfig = (t) => ({
    pending: { label: t('Menunggu Pembayaran'), class: 'tc-badge-warning' },
    paid: { label: t('Lunas'), class: 'tc-badge-success' },
    failed: { label: t('Gagal'), class: 'tc-badge-error' },
    expired: { label: t('Kedaluwarsa'), class: 'tc-badge-neutral' },
  });

  if (loading) return <div className="tc-loading-screen"><div className="tc-spinner tc-spinner-lg"></div><p>{t('Memuat tagihan...')}</p></div>;

  if (error) return (
    <div className="tc-error-state">
      <div className="tc-error-state-icon"><svg width="28" height="28" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8"><circle cx="12" cy="12" r="10"/><line x1="12" y1="8" x2="12" y2="12"/><line x1="12" y1="16" x2="12.01" y2="16"/></svg></div>
      <p className="tc-empty-state-title">{error}</p>
    </div>
  );

  return (
    <div>
      <div className="tc-page-header">
        <h1>{t('Tagihan')}</h1>
        <p>{t('Invoice dan pembayaran Anda.')}</p>
      </div>

      {invoices.length > 0 ? (
        <div style={{ display: 'flex', flexDirection: 'column', gap: '12px' }}>
          {invoices.map((inv) => {
            const cfg = statusConfig(t);
            const st = cfg[inv.status] || cfg.pending;
            const isPaid = inv.status === 'paid';
            const isPending = inv.status === 'pending';
            const isOverdue = isPending && new Date(inv.due_date) < new Date();

            return (
              <div
                key={inv.id}
                className="tc-card tc-card-hover"
                style={{ padding: '20px', cursor: 'pointer' }}
                onClick={() => navigate(`/parent/invoices/${inv.id}`)}
              >
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', marginBottom: '12px', flexWrap: 'wrap', gap: '8px' }}>
                  <div>
                    <div style={{ display: 'flex', alignItems: 'center', gap: '8px', marginBottom: '4px' }}>
                      <h3 style={{ fontSize: '14px', fontWeight: '600' }}>{inv.invoice_number}</h3>
                      <span className={`tc-badge ${st.class}`}>{st.label}</span>
                    </div>
                    <p style={{ fontSize: '12px', color: 'var(--color-text-muted)' }}>{inv.child?.name} · {inv.package?.name}</p>
                  </div>
                  <div style={{ textAlign: 'right' }}>
                    <p style={{ fontSize: '16px', fontWeight: '700', color: 'var(--color-primary)' }}>{formatCurrency(inv.total)}</p>
                    <p style={{ fontSize: '11px', color: isOverdue ? 'var(--color-error)' : 'var(--color-text-muted)' }}>
                      {t('Jatuh tempo: {{date}}', { date: new Date(inv.due_date).toLocaleDateString('id-ID') })}
                    </p>
                  </div>
                </div>

                {isPaid ? (
                  <div style={{ display: 'flex', alignItems: 'center', gap: '6px', fontSize: '12px', color: 'var(--color-success)' }}>
                    <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><path d="M22 11.08V12a10 10 0 11-5.93-9.14"/><polyline points="22 4 12 14.01 9 11.01"/></svg>
                    {t('Dibayar')}
                  </div>
                ) : (
                  <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
                    <span style={{ fontSize: '12px', color: isOverdue ? 'var(--color-error)' : 'var(--color-text-muted)' }}>
                      {isOverdue ? t('Jatuh tempo terlewat') : t('Sisa {{days}} hari', { days: Math.ceil((new Date(inv.due_date) - new Date()) / (1000*60*60*24)) })}
                    </span>
                    <span style={{ display: 'flex', alignItems: 'center', gap: '4px', fontSize: '12px', fontWeight: '600', color: 'var(--color-primary)' }}>
                      {t('Bayar Sekarang')}
                      <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><polyline points="9 18 15 12 9 6"/></svg>
                    </span>
                  </div>
                )}
              </div>
            );
          })}
        </div>
      ) : (
        <div className="tc-card">
          <div className="tc-empty-state">
            <div className="tc-empty-state-icon"><svg width="28" height="28" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8"><path d="M14 2H6a2 2 0 00-2 2v16a2 2 0 002 2h12a2 2 0 002-2V8z"/><polyline points="14 2 14 8 20 8"/></svg></div>
            <p className="tc-empty-state-title">{t('Belum ada tagihan')}</p>
            <p className="tc-empty-state-desc">{t('Tagihan akan muncul ketika ada invoice baru.')}</p>
          </div>
        </div>
      )}
    </div>
  );
}
