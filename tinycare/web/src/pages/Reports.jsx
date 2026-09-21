import { useState, useEffect } from 'react';
import { reportsAPI, childrenAPI } from '../services/api';
import { EmptyState, StatusBadge } from '../components/PageHeader';
import { useTranslation } from 'react-i18next';

export default function Reports() {
  const { t } = useTranslation();
  const [weeklyReports, setWeeklyReports] = useState([]);
  const [monthlyReports, setMonthlyReports] = useState([]);
  const [children, setChildren] = useState([]);
  const [loading, setLoading] = useState(true);
  const [activeTab, setActiveTab] = useState('weekly');
  const [selectedChild, setSelectedChild] = useState('');
  const [generating, setGenerating] = useState(false);
  const [error, setError] = useState('');

  async function loadReports() {
    try {
      const [weeklyRes, monthlyRes] = await Promise.all([
        reportsAPI.weeklyList({ per_page: 20 }),
        reportsAPI.monthlyList({ per_page: 20 }),
      ]);
      setWeeklyReports(weeklyRes.data.data.data || []);
      setMonthlyReports(monthlyRes.data.data.data || []);
    } catch (error) {
      setError(error.response?.data?.message || t('Gagal memuat data laporan.'));
    } finally {
      setLoading(false);
    }
  }

  async function loadChildren() {
    try {
      const res = await childrenAPI.list({ per_page: 100 });
      setChildren(res.data.data.data || []);
    } catch (error) {
      setError(error.response?.data?.message || t('Gagal memuat data anak.'));
    }
  }

  useEffect(() => {
    loadReports();
    loadChildren();
  }, []);

  const handleGenerateWeekly = async () => {
    if (!selectedChild) return;
    setGenerating(true);
    try {
      const now = new Date();
      const dayOfWeek = now.getDay();
      const monday = new Date(now);
      monday.setDate(now.getDate() - (dayOfWeek === 0 ? 6 : dayOfWeek - 1));
      const weekStart = monday.toISOString().split('T')[0];
      await reportsAPI.generateWeekly(selectedChild, { week_start: weekStart });
      loadReports();
    } catch (error) {
      setError(error.response?.data?.message || t('Gagal membuat laporan mingguan.'));
    } finally {
      setGenerating(false);
    }
  };

  const handleGenerateMonthly = async () => {
    if (!selectedChild) return;
    setGenerating(true);
    try {
      const now = new Date();
      await reportsAPI.generateMonthly(selectedChild, {
        month: now.getMonth() + 1,
        year: now.getFullYear(),
      });
      loadReports();
    } catch (error) {
      setError(error.response?.data?.message || t('Gagal membuat laporan bulanan.'));
    } finally {
      setGenerating(false);
    }
  };

  if (loading) {
    return (
      <div className="tc-loading-screen">
        <div className="tc-spinner tc-spinner-lg"></div>
        <p>{t('Memuat laporan...')}</p>
      </div>
    );
  }

  const reports = activeTab === 'weekly' ? weeklyReports : monthlyReports;

  return (
    <div>
      {/* Hero Greeting */}
      <div style={{
        padding: '28px 32px',
        background: 'var(--color-primary-subtle)',
        borderRadius: 'var(--radius-2xl)',
        border: '1px solid var(--color-primary-lighter)',
        marginBottom: '28px',
      }}>
        <h1 style={{ fontSize: '24px', fontWeight: '700', marginBottom: '4px', letterSpacing: '-0.02em' }}>
          {t('Laporan Perkembangan')}
        </h1>
        <p style={{ fontSize: '14px', color: 'var(--color-text-secondary)', lineHeight: 1.5 }}>
          {t('Pantau perkembangan anak melalui laporan mingguan dan bulanan.')}
        </p>
      </div>

      {error && (
        <div className="tc-error-state" style={{ marginBottom: '16px' }}>
          <p className="tc-empty-state-title">{error}</p>
          <button onClick={() => { setError(''); loadReports(); loadChildren(); }} className="tc-btn tc-btn-secondary tc-btn-sm" style={{ marginTop: '12px' }}>{t('Coba Lagi')}</button>
        </div>
      )}

      {/* Controls */}
      <div style={{
        display: 'flex', alignItems: 'center', justifyContent: 'space-between',
        marginBottom: '24px', gap: '16px', flexWrap: 'wrap',
      }}>
        {/* Tabs */}
        <div style={{ display: 'flex', gap: '6px' }}>
          <button
            onClick={() => setActiveTab('weekly')}
            className={activeTab === 'weekly' ? 'tc-btn tc-btn-primary tc-btn-sm' : 'tc-btn tc-btn-secondary tc-btn-sm'}
          >
            {t('Laporan Mingguan')}
          </button>
          <button
            onClick={() => setActiveTab('monthly')}
            className={activeTab === 'monthly' ? 'tc-btn tc-btn-primary tc-btn-sm' : 'tc-btn tc-btn-secondary tc-btn-sm'}
          >
            {t('Laporan Bulanan')}
          </button>
        </div>

        {/* Generate Controls */}
        <div style={{ display: 'flex', gap: '8px', alignItems: 'center' }}>
          <select
            value={selectedChild}
            onChange={(e) => setSelectedChild(e.target.value)}
            className="tc-select tc-select-sm"
            style={{ width: 'auto', minWidth: '160px' }}
          >
            <option value="">{t('Pilih Anak')}</option>
            {children.map((child) => (
              <option key={child.id} value={child.id}>{child.name}</option>
            ))}
          </select>
          <button
            onClick={activeTab === 'weekly' ? handleGenerateWeekly : handleGenerateMonthly}
            disabled={!selectedChild || generating}
            className="tc-btn tc-btn-primary tc-btn-sm"
          >
            {generating ? (
              <span style={{ display: 'flex', alignItems: 'center', gap: '6px' }}>
                <div className="tc-spinner tc-spinner-sm" style={{ borderTopColor: 'white' }}></div>
                {t('Membuat...')}
              </span>
            ) : 'Generate'}</button>
        </div>
      </div>

      {/* Reports List */}
      {reports.length === 0 ? (
        <EmptyState
          icon={activeTab === 'weekly' ? '📅' : '📆'}
          title={activeTab === 'weekly' ? t('Belum ada laporan mingguan') : t('Belum ada laporan bulanan')}
          description={t('Klik Generate untuk membuat laporan baru.')}
        />
      ) : (
        <div style={{ display: 'flex', flexDirection: 'column', gap: '16px' }}>
          {reports.map((report) => (
            <div key={report.id} className="tc-card tc-card-hover" style={{ padding: '24px' }}>
              {/* Report Header */}
              <div style={{ display: 'flex', alignItems: 'flex-start', justifyContent: 'space-between', marginBottom: '16px' }}>
                <div>
                  <h3 style={{ fontSize: '16px', fontWeight: '600', color: 'var(--color-text)', marginBottom: '4px' }}>
                    {report.child?.name}
                  </h3>
                  <p style={{ fontSize: '13px', color: 'var(--color-text-muted)' }}>
                    {activeTab === 'weekly'
                      ? `${new Date(report.week_start).toLocaleDateString('id-ID')} — ${new Date(report.week_end).toLocaleDateString('id-ID')}`
                      : new Date(report.year, report.month - 1).toLocaleDateString('id-ID', { month: 'long', year: 'numeric' })
                    }
                  </p>
                </div>
                <StatusBadge status="generated" config={{ generated: { label: 'Generated', color: 'var(--color-success)', bg: 'var(--color-success-bg)' } }} />
              </div>

              {/* Summary */}
              {report.overall_summary && (
                <div style={{
                  background: 'var(--color-bg-alt)', borderRadius: 'var(--radius-lg)',
                  padding: '14px 16px', marginTop: '4px',
                }}>
                  <p style={{ fontSize: '13px', color: 'var(--color-text-secondary)', lineHeight: 1.6, whiteSpace: 'pre-line' }}>
                    {report.overall_summary}
                  </p>
                </div>
              )}
            </div>
          ))}
        </div>
      )}
    </div>
  );
}
