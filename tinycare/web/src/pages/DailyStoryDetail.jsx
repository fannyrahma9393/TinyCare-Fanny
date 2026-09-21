import { useState, useEffect } from 'react';
import { useNavigate, useParams } from 'react-router-dom';
import { useTranslation } from 'react-i18next';
import { dailyStoriesAPI, childrenAPI } from '../services/api';
import { PageHeader, Modal, EmptyState } from '../components/PageHeader';
import ChildPhoto from '../components/ChildPhoto';

const moodConfig = (t) => ({
  bahagia: { label: t('Bahagia'), icon: '😊', color: 'var(--color-success)', bg: 'var(--color-success-bg)' },
  biasa: { label: t('Biasa'), icon: '😐', color: 'var(--color-text-muted)', bg: 'var(--color-bg-alt)' },
  sedih: { label: t('Sedih'), icon: '😢', color: 'var(--color-info)', bg: 'var(--color-info-bg)' },
  sakit: { label: t('Sakit'), icon: '🤒', color: 'var(--color-error)', bg: 'var(--color-error-bg)' },
  rewel: { label: t('Rewel'), icon: '😫', color: 'var(--color-warning)', bg: 'var(--color-warning-bg)' },
});

export default function DailyStoryDetail() {
  const { t } = useTranslation();
  const { childId } = useParams();
  const navigate = useNavigate();

  const [child, setChild] = useState(null);
  const [stories, setStories] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [selectedDate, setSelectedDate] = useState(new Date().toISOString().split('T')[0]);
  const [showModal, setShowModal] = useState(false);
  const [formData, setFormData] = useState({
    summary: '', mood: 'biasa', meal_notes: '', sleep_notes: '',
    admin_notes: '', meal_rating: '', sleep_hours: '',
  });

  async function loadChild() {
    try {
      const res = await childrenAPI.get(childId);
      setChild(res.data.data);
    } catch (err) {
      setError(err.response?.data?.message || t('Gagal memuat data anak.'));
    }
  }

  async function loadStories() {
    setLoading(true);
    setError('');
    try {
      const res = await dailyStoriesAPI.list({ child_id: childId, date: selectedDate });
      setStories(res.data.data.data || []);
    } catch (err) {
      setError(err.response?.data?.message || t('Gagal memuat Daily Stories.'));
    } finally {
      setLoading(false);
    }
  }

  useEffect(() => {
    loadChild();
  }, [childId]);

  useEffect(() => {
    loadStories();
  }, [childId, selectedDate]);

  const handleSubmit = async (e) => {
    e.preventDefault();
    try {
      await dailyStoriesAPI.create(childId, {
        ...formData,
        date: selectedDate,
        meal_rating: formData.meal_rating ? parseFloat(formData.meal_rating) : null,
        sleep_hours: formData.sleep_hours ? parseFloat(formData.sleep_hours) : null,
      });
      setShowModal(false);
      setFormData({ summary: '', mood: 'biasa', meal_notes: '', sleep_notes: '', admin_notes: '', meal_rating: '', sleep_hours: '' });
      loadStories();
    } catch (err) {
      alert(err.response?.data?.message || t('Gagal membuat Daily Story.'));
    }
  };

  const mc = moodConfig(t);

  return (
    <div>
      <PageHeader
        title={
          <div style={{ display: 'flex', alignItems: 'center', gap: '12px' }}>
            <button onClick={() => navigate('/daily-stories')} className="tc-btn tc-btn-ghost tc-btn-sm" style={{ padding: '4px 8px' }}>
              <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round">
                <polyline points="15 18 9 12 15 6" />
              </svg>
            </button>
            <ChildPhoto child={child} width={60} alt={child?.name} />
            <span>{child?.name || t('Memuat...')}</span>
          </div>
        }
        subtitle={t('Daily Story harian anak')}
        action={
          <div style={{ display: 'flex', gap: '10px', alignItems: 'center' }}>
            <input
              type="date"
              value={selectedDate}
              onChange={(e) => setSelectedDate(e.target.value)}
              className="tc-input"
              style={{ width: '180px' }}
            />
            <button onClick={() => setShowModal(true)} className="tc-btn tc-btn-primary">{t('+ Buat Story')}</button>
          </div>
        }
      />

      {error && (
        <div className="tc-error-state" style={{ marginBottom: '16px' }}>
          <p className="tc-empty-state-title">{error}</p>
          <button onClick={() => { setError(''); loadStories(); }} className="tc-btn tc-btn-secondary tc-btn-sm" style={{ marginTop: '12px' }}>
            {t('Coba Lagi')}
          </button>
        </div>
      )}

      {loading ? (
        <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'center', height: '300px' }}>
          <div className="tc-spinner"></div>
        </div>
      ) : stories.length === 0 && !error ? (
        <EmptyState
          icon="📖"
          title={t('Belum ada Daily Story')}
          description={t('Tidak ada cerita untuk tanggal {{date}}.', { date: new Date(selectedDate).toLocaleDateString('id-ID', { weekday: 'long', year: 'numeric', month: 'long', day: 'numeric' }) })}
          action={
            <button onClick={() => setShowModal(true)} className="tc-btn tc-btn-primary">
              {t('Buat Sekarang')}
            </button>
          }
        />
      ) : (
        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(380px, 1fr))', gap: '16px' }}>
          {stories.map((story) => {
            const mood = mc[story.mood] || mc.biasa;
            return (
              <div key={story.id} className="tc-card" style={{ overflow: 'hidden' }}>
                <div style={{ padding: '16px 20px', display: 'flex', alignItems: 'center', justifyContent: 'space-between', borderBottom: '1px solid var(--color-border-light)' }}>
                  <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
                    <div style={{ width: '36px', height: '36px', borderRadius: '10px', background: mood.bg, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                      <span style={{ fontSize: '18px' }}>{mood.icon}</span>
                    </div>
                    <div>
                      <p style={{ fontSize: '14px', fontWeight: '600' }}>{child?.name}</p>
                      <p style={{ fontSize: '11px', color: 'var(--color-text-muted)' }}>
                        {new Date(story.date).toLocaleDateString('id-ID', { weekday: 'long', year: 'numeric', month: 'long', day: 'numeric' })}
                      </p>
                    </div>
                  </div>
                  <span className="tc-badge" style={{ background: mood.bg, color: mood.color }}>{mood.label}</span>
                </div>
                <div style={{ padding: '16px 20px' }}>
                  {story.summary && <p style={{ fontSize: '13px', marginBottom: '12px', color: 'var(--color-text-secondary)', lineHeight: '1.5' }}>{story.summary}</p>}
                  <div style={{ display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)', gap: '8px', marginBottom: '12px' }}>
                    <div style={{ background: 'var(--color-bg-alt)', borderRadius: 'var(--radius-md)', padding: '10px', textAlign: 'center' }}>
                      <p style={{ fontSize: '11px', color: 'var(--color-text-muted)' }}>{t('Rating Makan')}</p>
                      <p style={{ fontSize: '16px', fontWeight: '700', color: 'var(--color-warning)' }}>{story.meal_rating || '-'}</p>
                    </div>
                    <div style={{ background: 'var(--color-bg-alt)', borderRadius: 'var(--radius-md)', padding: '10px', textAlign: 'center' }}>
                      <p style={{ fontSize: '11px', color: 'var(--color-text-muted)' }}>{t('Jam Tidur')}</p>
                      <p style={{ fontSize: '16px', fontWeight: '700', color: 'var(--color-info)' }}>{story.sleep_hours ? `${story.sleep_hours}j` : '-'}</p>
                    </div>
                    <div style={{ background: mood.bg, borderRadius: 'var(--radius-md)', padding: '10px', textAlign: 'center' }}>
                      <p style={{ fontSize: '11px', color: 'var(--color-text-muted)' }}>{t('Mood')}</p>
                      <p style={{ fontSize: '14px', fontWeight: '600', color: mood.color }}>{mood.label}</p>
                    </div>
                  </div>
                  {story.meal_notes && <div style={{ background: 'var(--color-warning-bg)', borderRadius: 'var(--radius-md)', padding: '10px', marginBottom: '8px' }}><p style={{ fontSize: '12px', color: 'var(--color-text-secondary)' }}>{story.meal_notes}</p></div>}
                  {story.sleep_notes && <div style={{ background: 'var(--color-info-bg)', borderRadius: 'var(--radius-md)', padding: '10px', marginBottom: '8px' }}><p style={{ fontSize: '12px', color: 'var(--color-text-secondary)' }}>{story.sleep_notes}</p></div>}
                </div>
              </div>
            );
          })}
        </div>
      )}

      <Modal open={showModal} onClose={() => setShowModal(false)} title={t('Buat Daily Story')} maxWidth="560px">
        <form onSubmit={handleSubmit}>
          <div style={{ display: 'flex', flexDirection: 'column', gap: '14px' }}>
            <div>
              <label className="tc-label">{t('Ringkasan Hari Ini')}</label>
              <textarea value={formData.summary} onChange={(e) => setFormData({ ...formData, summary: e.target.value })} className="tc-input" rows="3" placeholder={t('Ceritakan aktivitas anak hari ini...')} />
            </div>
            <div>
              <label className="tc-label">{t('Mood Anak')}</label>
              <div style={{ display: 'grid', gridTemplateColumns: 'repeat(5, 1fr)', gap: '8px' }}>
                {Object.entries(mc).map(([m, c]) => (
                  <button key={m} type="button" onClick={() => setFormData({ ...formData, mood: m })} style={{
                    padding: '8px', borderRadius: 'var(--radius-md)', border: `2px solid ${formData.mood === m ? 'var(--color-primary)' : 'var(--color-border)'}`,
                    background: formData.mood === m ? 'var(--color-primary-lighter)' : 'transparent',
                    cursor: 'pointer', textAlign: 'center', fontSize: '11px', color: 'var(--color-text)',
                  }}>
                    <div style={{ fontSize: '18px', marginBottom: '2px' }}>{c.icon}</div>
                    {c.label}
                  </button>
                ))}
              </div>
            </div>
            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '14px' }}>
              <div>
                <label className="tc-label">{t('Rating Makan (1-5)')}</label>
                <input type="number" value={formData.meal_rating} onChange={(e) => setFormData({ ...formData, meal_rating: e.target.value })} className="tc-input" min="1" max="5" step="0.5" />
              </div>
              <div>
                <label className="tc-label">{t('Jam Tidur Siang')}</label>
                <input type="number" value={formData.sleep_hours} onChange={(e) => setFormData({ ...formData, sleep_hours: e.target.value })} className="tc-input" min="0" max="12" step="0.5" />
              </div>
            </div>
            <div>
              <label className="tc-label">{t('Catatan Makan')}</label>
              <textarea value={formData.meal_notes} onChange={(e) => setFormData({ ...formData, meal_notes: e.target.value })} className="tc-input" rows="2" />
            </div>
            <div>
              <label className="tc-label">{t('Catatan Tidur')}</label>
              <textarea value={formData.sleep_notes} onChange={(e) => setFormData({ ...formData, sleep_notes: e.target.value })} className="tc-input" rows="2" />
            </div>
          </div>
          <div style={{ display: 'flex', gap: '10px', marginTop: '20px' }}>
            <button type="button" onClick={() => setShowModal(false)} className="tc-btn tc-btn-secondary" style={{ flex: 1 }}>{t('Batal')}</button>
            <button type="submit" className="tc-btn tc-btn-primary" style={{ flex: 1 }}>{t('Simpan')}</button>
          </div>
        </form>
      </Modal>
    </div>
  );
}