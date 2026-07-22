import { Head, Link, usePage } from '@inertiajs/react'
import { useState } from 'react'

import AuthenticatedPage from '@/components/layouts/AuthenticatedPage'
import OpportunityDrawer, {
  type OpportunityDrawerRecord,
  type OpportunityStageOption,
} from '@/components/opportunities/OpportunityDrawer'
import {
  hasOpportunityUpdateErrors,
  opportunityIdFromErrors,
} from '@/components/opportunities/opportunityFormErrors'
import { formatCurrency, formatDate } from '@/lib/format'

type OpportunityCard = OpportunityDrawerRecord

type PipelineStage = {
  id: number
  name: string
  position: number
  opportunities: OpportunityCard[]
}

type OpportunitiesIndexProps = {
  stages: PipelineStage[]
  stage_options: OpportunityStageOption[]
}

function findOpportunity(stages: PipelineStage[], id: number | null): OpportunityCard | null {
  if (id == null) return null
  for (const stage of stages) {
    const match = stage.opportunities.find((item) => item.id === id)
    if (match) return match
  }
  return null
}

export default function OpportunitiesIndex({
  stages = [],
  stage_options: stageOptions = [],
}: OpportunitiesIndexProps) {
  const page = usePage()
  const pageErrors = page.props.errors as Record<string, unknown> | undefined
  const updateErrorsPresent = hasOpportunityUpdateErrors(pageErrors)
  const errorOpportunityId = opportunityIdFromErrors(pageErrors)
  const errorKey = updateErrorsPresent ? JSON.stringify(pageErrors) : null

  const [manualId, setManualId] = useState<number | null>(null)
  const [dismissedErrorKey, setDismissedErrorKey] = useState<string | null>(null)

  const errorStillOpen = errorKey != null && dismissedErrorKey !== errorKey
  const selectedId = manualId ?? (errorStillOpen ? errorOpportunityId : null)
  const selected = findOpportunity(stages, selectedId)
  const drawerOpen = selected != null

  function openDrawer(opportunity: OpportunityCard) {
    setDismissedErrorKey(null)
    setManualId(opportunity.id)
  }

  function closeDrawer() {
    setManualId(null)
    if (errorKey != null) setDismissedErrorKey(errorKey)
  }

  return (
    <AuthenticatedPage>
      <Head title="Opportunities" />

      <div>
        <div>
          <h1 className="text-2xl font-semibold text-slate-900">Opportunities</h1>
          <p className="mt-1 text-slate-600">Pipeline by stage across your scoped leads.</p>
        </div>

        <div className="mt-8 flex gap-4 overflow-x-auto pb-4">
          {stages.map((stage) => (
            <section
              key={stage.id}
              className="flex w-72 shrink-0 flex-col rounded-xl border border-slate-200 bg-slate-50"
              aria-label={`${stage.name} stage`}
            >
              <header className="flex items-center justify-between gap-2 border-b border-slate-200 px-3 py-3">
                <h2 className="text-sm font-semibold text-slate-900">{stage.name}</h2>
                <span className="rounded-full bg-white px-2 py-0.5 text-xs font-medium text-slate-600 ring-1 ring-slate-200">
                  {stage.opportunities.length}
                </span>
              </header>

              <ul className="flex min-h-40 flex-1 flex-col gap-2 p-3">
                {stage.opportunities.length === 0 ? (
                  <li className="rounded-lg border border-dashed border-slate-200 bg-white px-3 py-6 text-center text-xs text-slate-400">
                    No opportunities
                  </li>
                ) : (
                  stage.opportunities.map((opportunity) => (
                    <li key={opportunity.id}>
                      <article className="rounded-lg border border-slate-200 bg-white shadow-sm hover:border-indigo-200 hover:bg-indigo-50/40">
                        <button
                          type="button"
                          onClick={() => openDrawer(opportunity)}
                          className="w-full px-3 pt-3 text-left"
                        >
                          <div className="font-medium text-slate-900">{opportunity.title || 'Untitled'}</div>
                          <div className="mt-1 text-sm font-semibold text-slate-700">
                            {formatCurrency(opportunity.value)}
                          </div>
                        </button>
                        <div className="px-3 pb-3 pt-2 text-xs text-slate-500">
                          {opportunity.lead_id ? (
                            <Link
                              href={`/leads/${opportunity.lead_id}`}
                              className="font-medium text-indigo-600 hover:text-indigo-500"
                            >
                              {opportunity.lead || '—'}
                            </Link>
                          ) : (
                            opportunity.lead || '—'
                          )}
                          {opportunity.close_date ? ` · Close ${formatDate(opportunity.close_date)}` : null}
                        </div>
                      </article>
                    </li>
                  ))
                )}
              </ul>
            </section>
          ))}
        </div>
      </div>

      <OpportunityDrawer
        key={selected?.id ?? 'closed'}
        open={drawerOpen}
        opportunity={selected}
        stageOptions={stageOptions}
        onClose={closeDrawer}
      />
    </AuthenticatedPage>
  )
}
