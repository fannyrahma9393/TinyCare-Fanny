export function PageHeader({ title, subtitle, action }) {
  return (
    <div style={{ display: 'flex', alignItems: 'flex-start', justifyContent: 'space-between', marginBottom: '28px', gap: '16px', flexWrap: 'wrap' }}>
      <div>
        <h1 style={{ fontSize: '22px', fontWeight: '700', letterSpacing: '-0.02em', marginBottom: '4px' }}>{title}</h1>
        {subtitle && <p style={{ fontSize: '13px', color: 'var(--color-text-secondary)' }}>{subtitle}</p>}
      </div>
      {action && <div>{action}</div>}
    </div>
  );
}

export function Modal({ open, onClose, title, children, maxWidth }) {
  if (!open) return null;
  return (
    <div className="tc-modal-overlay" onClick={onClose}>
      <div className="tc-modal" onClick={(e) => e.stopPropagation()} style={{ maxWidth: maxWidth || '500px' }}>
        <h2 style={{ fontSize: '18px', fontWeight: '700', marginBottom: '20px', letterSpacing: '-0.01em' }}>{title}</h2>
        {children}
      </div>
    </div>
  );
}

export function EmptyState({ icon, title, description, action }) {
  return (
    <div className="tc-card" style={{ textAlign: 'center' }}>
      <div className="tc-empty-state">
        <div className="tc-empty-state-icon">
          <span style={{ fontSize: '24px' }}>{icon}</span>
        </div>
        <p className="tc-empty-state-title">{title}</p>
        {description && <p className="tc-empty-state-desc">{description}</p>}
        {action && <div style={{ marginTop: '16px' }}>{action}</div>}
      </div>
    </div>
  );
}

export function FilterTabs({ tabs, active, onChange }) {
  return (
    <div style={{ display: 'flex', gap: '6px', marginBottom: '20px', flexWrap: 'wrap' }}>
      {tabs.map((tab) => (
        <button
          key={tab.value}
          onClick={() => onChange(tab.value)}
          className={active === tab.value ? 'tc-btn tc-btn-primary tc-btn-sm' : 'tc-btn tc-btn-secondary tc-btn-sm'}
        >
          {tab.label}
        </button>
      ))}
    </div>
  );
}

export function StatusBadge({ status, config }) {
  const c = config?.[status] || { label: status, color: 'var(--color-text-muted)', bg: 'var(--color-bg-alt)' };
  return (
    <span className="tc-badge" style={{ background: c.bg || 'var(--color-bg-alt)', color: c.color || 'var(--color-text-muted)' }}>
      {c.label}
    </span>
  );
}
