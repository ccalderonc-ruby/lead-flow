import type { ReactNode } from 'react'

type StageBadgeProps = {
  stage: string | null | undefined
  className?: string
}

const STAGE_STYLES: Record<string, string> = {
  prospect: 'bg-sky-100 text-sky-800',
  prospecting: 'bg-sky-100 text-sky-800',
  qualified: 'bg-emerald-100 text-emerald-800',
  qualification: 'bg-sky-100 text-sky-800',
  nurturing: 'bg-amber-100 text-amber-900',
  negotiation: 'bg-violet-100 text-violet-800',
  proposal: 'bg-violet-100 text-violet-800',
  closed: 'bg-slate-100 text-slate-700',
  won: 'bg-emerald-100 text-emerald-800',
  lost: 'bg-slate-100 text-slate-700',
}

function styleFor(stage: string) {
  return STAGE_STYLES[stage.trim().toLowerCase()] ?? 'bg-slate-100 text-slate-700'
}

export default function StageBadge({ stage, className }: StageBadgeProps) {
  if (!stage) return <span className="text-slate-400">—</span>

  return (
    <span
      className={[
        'inline-flex rounded-full px-2.5 py-0.5 text-xs font-medium',
        styleFor(stage),
        className,
      ]
        .filter(Boolean)
        .join(' ')}
    >
      {stage}
    </span>
  )
}

type PriorityBadgeProps = {
  priority: string | null | undefined
}

const PRIORITY_STYLES: Record<string, string> = {
  high: 'bg-red-100 text-red-800',
  medium: 'bg-amber-100 text-amber-900',
  low: 'bg-slate-100 text-slate-700',
}

export function PriorityBadge({ priority }: PriorityBadgeProps) {
  if (!priority) return <span className="text-slate-400">—</span>
  const key = priority.trim().toLowerCase()

  return (
    <span
      className={[
        'inline-flex rounded-full px-2.5 py-0.5 text-xs font-medium',
        PRIORITY_STYLES[key] ?? 'bg-slate-100 text-slate-700',
      ].join(' ')}
    >
      {priority}
    </span>
  )
}

export function SectionCard({
  title,
  children,
  action,
}: {
  title: string
  children: ReactNode
  action?: ReactNode
}) {
  return (
    <div className="rounded-xl border border-slate-200 bg-panel p-5 shadow-sm">
      <div className="mb-4 flex items-center justify-between gap-3">
        <h2 className="text-base font-semibold text-ink">{title}</h2>
        {action}
      </div>
      {children}
    </div>
  )
}
