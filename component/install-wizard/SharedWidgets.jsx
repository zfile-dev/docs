import React from 'react';

export function OptionCard({ label, desc, icon, selected, onClick }) {
  return (
    <div
      onClick={onClick}
      onKeyDown={(e) => (e.key === 'Enter' || e.key === ' ') && onClick()}
      role="radio" aria-checked={selected} tabIndex={0}
      style={{
        cursor: 'pointer', borderRadius: '8px',
        border: selected ? '2px solid var(--ifm-color-primary)' : '2px solid var(--ifm-color-emphasis-300)',
        padding: '12px 16px', transition: 'all 0.15s',
        background: selected ? 'var(--ifm-color-primary-contrast-background)' : 'transparent',
        minHeight: '44px', display: 'flex', alignItems: 'center', gap: '10px',
      }}
    >
      {icon && <span style={{ fontSize: '1.4em' }}>{icon}</span>}
      <div>
        <div style={{ fontWeight: 600, color: selected ? 'var(--ifm-color-primary)' : 'inherit' }}>{label}</div>
        {desc && <div style={{ fontSize: '0.8em', opacity: 0.6 }}>{desc}</div>}
      </div>
    </div>
  );
}

export function ArchHint() {
  return (
    <div style={{ marginTop: '10px', padding: '10px 14px', borderRadius: '8px', background: 'var(--ifm-color-emphasis-100)', fontSize: '0.85em', lineHeight: 1.8 }}>
      不确定你的架构？运行 <code>uname -m</code> 查看：<br />
      <code>x86_64</code> → 选 amd64<br />
      <code>aarch64</code> / <code>arm64</code> → 选 arm64
    </div>
  );
}

export function ArchSelector({ arch, setArch }) {
  const archOptions = [
    { id: 'amd64', label: 'amd64', desc: '通用 PC / 云服务器' },
    { id: 'arm64', label: 'arm64', desc: '树莓派 / ARM 服务器' },
  ];
  return (
    <>
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(200px, 1fr))', gap: '10px' }}>
        {archOptions.map((a) => (
          <OptionCard key={a.id} label={a.label} desc={a.desc}
            selected={arch === a.id} onClick={() => setArch(a.id)} />
        ))}
      </div>
      <ArchHint />
    </>
  );
}
