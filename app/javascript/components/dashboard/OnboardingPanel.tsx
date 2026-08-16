import { Link } from '@inertiajs/react'
import { useEffect, useState } from 'react'

export type OnboardingAction = {
  label: string
  href?: string
  action?: 'create_lead'
}

export type OnboardingChecklistItem = {
  id: string
  label: string
  href?: string
  action?: 'create_lead'
  done: boolean
}

export type OnboardingProps = {
  show: boolean
  title?: string
  description?: string
  checklist?: OnboardingChecklistItem[]
  primary_action?: OnboardingAction
  secondary_action?: OnboardingAction
}

const DISMISS_KEY = 'leadflow:onboarding-dismissed'

type OnboardingPanelProps = {
  onboarding: OnboardingProps
  onCreateLead?: () => void
}

function ActionButton({
  action,
  primary,
  onCreateLead,
}: {
  action: OnboardingAction
  primary?: boolean
  onCreateLead?: () => void
}) {
  const className = primary
    ? 'inline-flex min-h-11 items-center justify-center rounded-lg bg-brand px-4 py-2 text-sm font-medium text-white hover:bg-brand-hover focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-brand focus-visible:ring-offset-2 focus-visible:ring-offset-panel'
    : 'inline-flex min-h-11 items-center justify-center rounded-lg border border-slate-300 bg-panel px-4 py-2 text-sm font-medium text-slate-700 hover:bg-slate-50 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-brand focus-visible:ring-offset-2 focus-visible:ring-offset-panel'

  if (action.action === 'create_lead') {
    return (
      <button type="button" onClick={onCreateLead} className={className}>
        {action.label}
      </button>
    )
  }

  if (action.href) {
    return (
      <Link href={action.href} className={className}>
        {action.label}
      </Link>
    )
  }

  return null
}

export default function OnboardingPanel({ onboarding, onCreateLead }: OnboardingPanelProps) {
  const [dismissed, setDismissed] = useState(false)

  useEffect(() => {
    try {
      setDismissed(window.localStorage.getItem(DISMISS_KEY) === '1')
    } catch {
      setDismissed(false)
    }
  }, [])

  if (!onboarding.show || dismissed) return null

  function dismiss() {
    try {
      window.localStorage.setItem(DISMISS_KEY, '1')
    } catch {
      // ignore storage failures
    }
    setDismissed(true)
  }

  function handleChecklistClick(item: OnboardingChecklistItem) {
    if (item.action === 'create_lead') onCreateLead?.()
  }

  return (
    <section
      className="rounded-xl border border-brand/30 bg-gradient-to-br from-brand/5 via-panel to-panel p-5 shadow-sm sm:p-6"
      aria-labelledby="onboarding-heading"
    >
      <div className="flex flex-col gap-4 sm:flex-row sm:items-start sm:justify-between">
        <div className="min-w-0">
          <h2 id="onboarding-heading" className="text-lg font-semibold text-ink">
            {onboarding.title}
          </h2>
          {onboarding.description ? (
            <p className="mt-1 max-w-2xl text-sm text-slate-600">{onboarding.description}</p>
          ) : null}
        </div>
        <button
          type="button"
          onClick={dismiss}
          className="shrink-0 self-start text-sm font-medium text-slate-500 hover:text-slate-800"
        >
          Dismiss
        </button>
      </div>

      {onboarding.checklist && onboarding.checklist.length > 0 ? (
        <ol className="mt-5 space-y-2">
          {onboarding.checklist.map((item, index) => (
            <li key={item.id}>
              {item.action === 'create_lead' ? (
                <button
                  type="button"
                  onClick={() => handleChecklistClick(item)}
                  className="flex w-full min-h-11 items-center gap-3 rounded-lg border border-slate-200 bg-panel px-3 py-2.5 text-left text-sm text-slate-800 hover:border-brand/40 hover:bg-brand/5"
                >
                  <span className="flex h-6 w-6 shrink-0 items-center justify-center rounded-full bg-slate-100 text-xs font-semibold text-slate-600">
                    {index + 1}
                  </span>
                  <span className="font-medium">{item.label}</span>
                </button>
              ) : (
                <Link
                  href={item.href || '/'}
                  className="flex min-h-11 items-center gap-3 rounded-lg border border-slate-200 bg-panel px-3 py-2.5 text-sm text-slate-800 hover:border-brand/40 hover:bg-brand/5"
                >
                  <span className="flex h-6 w-6 shrink-0 items-center justify-center rounded-full bg-slate-100 text-xs font-semibold text-slate-600">
                    {index + 1}
                  </span>
                  <span className="font-medium">{item.label}</span>
                </Link>
              )}
            </li>
          ))}
        </ol>
      ) : null}

      {(onboarding.primary_action || onboarding.secondary_action) && (
        <div className="mt-5 flex flex-wrap gap-2">
          {onboarding.primary_action ? (
            <ActionButton action={onboarding.primary_action} primary onCreateLead={onCreateLead} />
          ) : null}
          {onboarding.secondary_action ? (
            <ActionButton action={onboarding.secondary_action} onCreateLead={onCreateLead} />
          ) : null}
        </div>
      )}
    </section>
  )
}
