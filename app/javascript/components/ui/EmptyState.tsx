import type { ReactNode } from 'react'
import { Link } from '@inertiajs/react'

type EmptyStateAction = {
  label: string
  href?: string
  onClick?: () => void
}

type EmptyStateProps = {
  title: string
  description?: string
  action?: EmptyStateAction
  secondaryAction?: EmptyStateAction
  children?: ReactNode
}

function ActionButton({ action, primary }: { action: EmptyStateAction; primary?: boolean }) {
  const className = primary
    ? 'inline-flex items-center justify-center rounded-lg bg-brand px-4 py-2 text-sm font-medium text-white hover:bg-brand-hover'
    : 'inline-flex items-center justify-center rounded-lg border border-slate-300 bg-white px-4 py-2 text-sm font-medium text-slate-700 hover:bg-slate-50'

  if (action.href) {
    return (
      <Link href={action.href} className={className}>
        {action.label}
      </Link>
    )
  }

  return (
    <button type="button" onClick={action.onClick} className={className}>
      {action.label}
    </button>
  )
}

export default function EmptyState({
  title,
  description,
  action,
  secondaryAction,
  children,
}: EmptyStateProps) {
  return (
    <div className="flex flex-col items-center justify-center px-6 py-12 text-center">
      <div className="flex h-12 w-12 items-center justify-center rounded-full bg-slate-100 text-slate-400" aria-hidden>
        <svg className="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={1.5}>
          <path
            strokeLinecap="round"
            strokeLinejoin="round"
            d="M3.75 6.75h16.5M3.75 12h16.5m-16.5 5.25H12"
          />
        </svg>
      </div>
      <h3 className="mt-4 text-base font-semibold text-ink">{title}</h3>
      {description ? <p className="mt-1 max-w-sm text-sm text-slate-500">{description}</p> : null}
      {children}
      {(action || secondaryAction) && (
        <div className="mt-5 flex flex-wrap items-center justify-center gap-2">
          {action ? <ActionButton action={action} primary /> : null}
          {secondaryAction ? <ActionButton action={secondaryAction} /> : null}
        </div>
      )}
    </div>
  )
}
