import { useState, type ButtonHTMLAttributes, type ReactNode } from 'react';
import { Icon, type IconName } from './Icon';

export function Button({ children, icon, variant = 'primary', loading = false, ...p }: ButtonHTMLAttributes<HTMLButtonElement> & { icon?: IconName; variant?: 'primary' | 'secondary' | 'danger' | 'ghost'; loading?: boolean }) {
  return <button {...p} disabled={p.disabled || loading} className={`btn ${variant}`}>{loading ? <span className="spin" /> : icon ? <Icon name={icon} /> : null}{children}</button>;
}

export function ConfirmButton({ children, title, description, confirmText = 'تأیید', variant = 'danger', onConfirm, ...buttonProps }: Omit<ButtonHTMLAttributes<HTMLButtonElement>, 'onClick'> & { children: ReactNode; title: string; description?: string; confirmText?: string; variant?: 'primary' | 'secondary' | 'danger' | 'ghost'; onConfirm: () => Promise<void> | void }) {
  const [open, setOpen] = useState(false);
  const [loading, setLoading] = useState(false);
  const run = async () => {
    setLoading(true);
    try { await onConfirm(); setOpen(false); } finally { setLoading(false); }
  };
  return <>
    <Button {...buttonProps} variant={variant} onClick={() => setOpen(true)}>{children}</Button>
    {open ? <div className="modal-backdrop" role="presentation" onMouseDown={(e) => { if (e.currentTarget === e.target && !loading) setOpen(false); }}>
      <section className="update-modal" role="dialog" aria-modal="true" aria-label={title}>
        <h2>{title}</h2>
        {description ? <p>{description}</p> : null}
        <div><Button variant="secondary" disabled={loading} onClick={() => setOpen(false)}>انصراف</Button><Button variant={variant} loading={loading} onClick={run}>{confirmText}</Button></div>
      </section>
    </div> : null}
  </>;
}

export function PageHeader({ title, subtitle, actions }: { title: string; subtitle?: string; actions?: ReactNode }) {
  return <header className="page-header"><div><h1>{title}</h1>{subtitle ? <p>{subtitle}</p> : null}</div><div className="page-actions">{actions}</div></header>;
}
export function Card({ children, className = '' }: { children: ReactNode; className?: string }) { return <section className={`card ${className}`}>{children}</section>; }
export function Badge({ children, tone = 'neutral' }: { children: ReactNode; tone?: 'neutral' | 'good' | 'warn' | 'bad' | 'info' }) { return <span className={`badge ${tone}`}>{children}</span>; }
export function Empty({ children = 'داده‌ای وجود ندارد' }: { children?: ReactNode }) { return <div className="empty">{children}</div>; }
