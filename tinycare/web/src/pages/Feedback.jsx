import { useState, useEffect } from 'react';
import { feedbackAPI } from '../services/api';
import { PageHeader, Modal, EmptyState } from '../components/PageHeader';
import { useTranslation } from 'react-i18next';

export default function Feedback() {
  const { t } = useTranslation();
  const [feedbacks, setFeedbacks] = useState([]);
  const [loading, setLoading] = useState(true);
  const [filter, setFilter] = useState('');
  const [respondingTo, setRespondingTo] = useState(null);
  const [responseText, setResponseText] = useState('');
  const [error, setError] = useState('');

  async function loadFeedbacks() {
    setLoading(true);
    try { const params = filter ? { status: filter } : {}; const res = await feedbackAPI.list(params); setFeedbacks(res.data.data.data || []); }
    catch (error) { setError(error.response?.data?.message || t('Gagal memuat data feedback.')); } finally { setLoading(false); }
  }

  useEffect(() => { loadFeedbacks(); }, [filter]);

  const handleRespond = async () => {
    if (!responseText.trim()) return alert(t('Masukkan jawaban.'));
    try { await feedbackAPI.respond(respondingTo.id, { admin_response: responseText }); setRespondingTo(null); setResponseText(''); loadFeedbacks(); }
    catch (error) { alert(error.response?.data?.message || t('Gagal mengirim jawaban.')); }
  };

  const handleStatusUpdate = async (id, status) => {
    try { await feedbackAPI.updateStatus(id, { status }); loadFeedbacks(); }
    catch { alert(t('Gagal mengubah status.')); }
  };

  const statusConfig = {
    pending: { label: t('Menunggu'), color: 'var(--color-warning)', bg: 'var(--color-warning-bg)' },
    reviewed: { label: t('Ditinjau'), color: 'var(--color-info)', bg: 'var(--color-info-bg)' },
    responded: { label: t('Dijawab'), color: 'var(--color-success)', bg: 'var(--color-success-bg)' },
  };

  if (loading) return <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'center', height: '300px' }}><div className="tc-spinner"></div></div>;

  return (
    <div>
      <PageHeader title={t('Manajemen Feedback')} subtitle={t('Lihat dan balas feedback dari orang tua')} />

      <div style={{ display: 'flex', gap: '6px', marginBottom: '20px' }}>
        {[{ value: '', label: t('Semua') }, { value: 'pending', label: t('Menunggu') }, { value: 'reviewed', label: t('Ditinjau') }, { value: 'responded', label: t('Dijawab') }].map((tab) => (
          <button key={tab.value} onClick={() => setFilter(tab.value)} className={filter === tab.value ? 'tc-btn tc-btn-primary' : 'tc-btn tc-btn-secondary'} style={{ padding: '7px 14px', fontSize: '13px' }}>{tab.label}</button>
        ))}
      </div>

      {error && (
        <div className="tc-error-state" style={{ marginBottom: '16px' }}>
          <p className="tc-empty-state-title">{error}</p>
          <button onClick={() => { setError(''); loadFeedbacks(); }} className="tc-btn tc-btn-secondary tc-btn-sm" style={{ marginTop: '12px' }}>{t('Coba Lagi')}</button>
        </div>
      )}

      <div style={{ display: 'flex', flexDirection: 'column', gap: '12px' }}>
        {feedbacks.map((item) => {
          const status = statusConfig[item.status] || statusConfig.pending;
          return (
            <div key={item.id} className="tc-card" style={{ padding: '20px' }}>
              <div style={{ display: 'flex', alignItems: 'flex-start', justifyContent: 'space-between', marginBottom: '8px' }}>
                <div>
                  <div style={{ display: 'flex', alignItems: 'center', gap: '8px', marginBottom: '4px' }}>
                    <h3 style={{ fontSize: '14px', fontWeight: '600' }}>{item.subject}</h3>
                    <span className="tc-badge" style={{ background: status.bg, color: status.color }}>{status.label}</span>
                  </div>
                  <p style={{ fontSize: '12px', color: 'var(--color-text-muted)' }}>{t('Dari: {{name}}', { name: item.parent?.user?.name })} {item.child ? t('• Anak: {{name}}', { name: item.child.name }) : ''}</p>
                  {item.rating && <p style={{ fontSize: '12px', color: 'var(--color-accent)', marginTop: '2px' }}>{'★'.repeat(item.rating)}{'☆'.repeat(5 - item.rating)}</p>}
                </div>
                <span style={{ fontSize: '12px', color: 'var(--color-text-muted)' }}>{new Date(item.created_at).toLocaleDateString('id-ID')}</span>
              </div>
              <p style={{ fontSize: '13px', color: 'var(--color-text-secondary)', marginBottom: '12px', lineHeight: '1.5' }}>{item.message}</p>
              {item.admin_response && (
                <div style={{ background: 'var(--color-success-bg)', borderRadius: 'var(--radius-md)', padding: '12px', marginBottom: '12px' }}>
                  <p style={{ fontSize: '12px', fontWeight: '600', color: 'var(--color-success)', marginBottom: '4px' }}>{t('Jawaban Admin:')}</p>
                  <p style={{ fontSize: '13px' }}>{item.admin_response}</p>
                </div>
              )}
              <div style={{ display: 'flex', gap: '8px', paddingTop: '12px', borderTop: '1px solid var(--color-border-light)' }}>
                {item.status !== 'responded' && (
                  <button onClick={() => { setRespondingTo(item); setResponseText(''); }} className="tc-btn tc-btn-primary" style={{ padding: '6px 12px', fontSize: '12px' }}>{t('Balas')}</button>
                )}
                {item.status === 'pending' && (
                  <button onClick={() => handleStatusUpdate(item.id, 'reviewed')} className="tc-btn tc-btn-secondary" style={{ padding: '6px 12px', fontSize: '12px' }}>{t('Tinjau')}</button>
                )}
              </div>
            </div>
          );
        })}
      </div>

      {feedbacks.length === 0 && <EmptyState icon="💬" title={t('Belum ada feedback')} />}

      <Modal open={!!respondingTo} onClose={() => setRespondingTo(null)} title={t('Balas Feedback')}>
        {respondingTo && (
          <>
            <div style={{ padding: '12px', background: 'var(--color-bg-alt)', borderRadius: 'var(--radius-md)', marginBottom: '14px' }}>
              <p style={{ fontSize: '13px', fontWeight: '600' }}>{respondingTo.subject}</p>
              <p style={{ fontSize: '12px', color: 'var(--color-text-secondary)', marginTop: '4px' }}>{respondingTo.message}</p>
            </div>
            <textarea value={responseText} onChange={(e) => setResponseText(e.target.value)} className="tc-input" rows="4" placeholder={t('Tulis jawaban Anda...')} style={{ marginBottom: '14px' }} />
            <div style={{ display: 'flex', gap: '10px' }}>
              <button onClick={() => setRespondingTo(null)} className="tc-btn tc-btn-secondary" style={{ flex: 1 }}>{t('Batal')}</button>
              <button onClick={handleRespond} className="tc-btn tc-btn-primary" style={{ flex: 1 }}>{t('Kirim Jawaban')}</button>
            </div>
          </>
        )}
      </Modal>
    </div>
  );
}
