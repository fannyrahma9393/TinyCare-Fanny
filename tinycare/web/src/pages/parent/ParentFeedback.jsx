import { useState, useEffect } from 'react';
import { parentAPI } from '../../services/api';

export default function ParentFeedback() {
  const [items, setItems] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [showForm, setShowForm] = useState(false);
  const [formData, setFormData] = useState({ subject: '', message: '', rating: 5 });
  const [submitting, setSubmitting] = useState(false);

  const load = () => {
    setLoading(true);
    parentAPI.feedback()
      .then((res) => setItems(res.data.data.data || []))
      .catch(() => setError('Gagal memuat feedback.'))
      .finally(() => setLoading(false));
  };

  useEffect(() => { load(); }, []);

  const handleSubmit = async (e) => {
    e.preventDefault();
    setSubmitting(true);
    try {
      await parentAPI.submitFeedback(formData);
      setShowForm(false);
      setFormData({ subject: '', message: '', rating: 5 });
      load();
    } catch (err) {
      alert(err.response?.data?.message || 'Gagal mengirim feedback.');
    } finally {
      setSubmitting(false);
    }
  };

  if (loading && !showForm) return <div className="tc-loading-screen"><div className="tc-spinner tc-spinner-lg"></div><p>Memuat feedback...</p></div>;

  return (
    <div>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '20px' }}>
        <div className="tc-page-header" style={{ marginBottom: 0 }}>
          <h1>Feedback</h1>
          <p>Kirim masukan untuk daycare.</p>
        </div>
        <button onClick={() => setShowForm(!showForm)} className="tc-btn tc-btn-primary tc-btn-sm">
          {showForm ? 'Batal' : '+ Kirim Feedback'}
        </button>
      </div>

      {showForm && (
        <div className="tc-card" style={{ padding: '24px', marginBottom: '20px' }}>
          <form onSubmit={handleSubmit}>
            <div style={{ display: 'flex', flexDirection: 'column', gap: '14px' }}>
              <div>
                <label className="tc-label">Subjek *</label>
                <input type="text" value={formData.subject} onChange={(e) => setFormData({ ...formData, subject: e.target.value })} className="tc-input" placeholder="Subjek feedback" required />
              </div>
              <div>
                <label className="tc-label">Pesan *</label>
                <textarea value={formData.message} onChange={(e) => setFormData({ ...formData, message: e.target.value })} className="tc-textarea" rows="3" placeholder="Tulis pesan Anda..." required />
              </div>
              <div>
                <label className="tc-label">Rating</label>
                <div style={{ display: 'flex', gap: '4px' }}>
                  {[1,2,3,4,5].map((star) => (
                    <button key={star} type="button" onClick={() => setFormData({ ...formData, rating: star })}
                      style={{ background: 'none', border: 'none', cursor: 'pointer', fontSize: '24px', color: star <= formData.rating ? 'var(--color-accent)' : 'var(--color-border)', transition: 'color 0.1s' }}>
                      ★
                    </button>
                  ))}
                </div>
              </div>
            </div>
            <div style={{ display: 'flex', gap: '10px', marginTop: '16px' }}>
              <button type="button" onClick={() => setShowForm(false)} className="tc-btn tc-btn-secondary" style={{ flex: 1 }}>Batal</button>
              <button type="submit" disabled={submitting} className="tc-btn tc-btn-primary" style={{ flex: 1 }}>{submitting ? 'Mengirim...' : 'Kirim'}</button>
            </div>
          </form>
        </div>
      )}

      {error && !loading && (
        <div className="tc-card" style={{ padding: '20px', marginBottom: '16px', borderColor: 'var(--color-error)', background: 'var(--color-error-bg)' }}>
          <p style={{ color: 'var(--color-error)', fontSize: '13px' }}>{error}</p>
        </div>
      )}

      {items.length > 0 ? (
        <div style={{ display: 'flex', flexDirection: 'column', gap: '12px' }}>
          {items.map((item) => (
            <div key={item.id} className="tc-card tc-card-hover" style={{ padding: '20px' }}>
              <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: '6px' }}>
                <h3 style={{ fontSize: '14px', fontWeight: '600' }}>{item.subject}</h3>
                {item.rating && <span style={{ color: 'var(--color-accent)', fontSize: '14px' }}>{'★'.repeat(item.rating)}{'☆'.repeat(5 - item.rating)}</span>}
              </div>
              <p style={{ fontSize: '13px', color: 'var(--color-text-secondary)', marginBottom: '8px', lineHeight: 1.5 }}>{item.message}</p>
              {item.admin_response && (
                <div style={{ background: 'var(--color-success-bg)', borderRadius: 'var(--radius-md)', padding: '12px', marginTop: '8px' }}>
                  <p style={{ fontSize: '12px', fontWeight: '600', color: 'var(--color-success)', marginBottom: '4px' }}>Balasan Admin:</p>
                  <p style={{ fontSize: '13px', lineHeight: 1.5 }}>{item.admin_response}</p>
                </div>
              )}
              <p style={{ fontSize: '12px', color: 'var(--color-text-muted)', marginTop: '8px' }}>{new Date(item.created_at).toLocaleDateString('id-ID', { year: 'numeric', month: 'long', day: 'numeric' })}</p>
            </div>
          ))}
        </div>
      ) : (
        <div className="tc-card">
          <div className="tc-empty-state">
            <div className="tc-empty-state-icon"><svg width="28" height="28" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8"><path d="M21 15a2 2 0 01-2 2H7l-4 4V5a2 2 0 012-2h14a2 2 0 012 2z"/></svg></div>
            <p className="tc-empty-state-title">Belum ada feedback</p>
            <p className="tc-empty-state-desc">Kirim feedback pertama Anda untuk daycare.</p>
          </div>
        </div>
      )}
    </div>
  );
}
