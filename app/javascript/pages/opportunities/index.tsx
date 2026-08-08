import { Head, Link, usePage } from '@inertiajs/react'
import { useState } from 'react'

import AuthenticatedPage from '@/components/layouts/AuthenticatedPage'
import OpportunityDrawer, {
  type OpportunityDrawerRecord,
  type OpportunityStageOption,
} from '@/components/opportunities/OpportunityDrawer'
import OpportunityFormModal, {
  type OpportunityFormDefaults,
  type OpportunityFormOption,
} from '@/components/opportunities/OpportunityFormModal'
import {
  hasOpportunityCreateErrors,
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
  can_create: boolean
  leads: OpportunityFormOption[]
  defaults: OpportunityFormDefaults
  return_to: string
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
  can_create: canCreate = false,
  leads = [],
  defaults = { stage_id: null },
  return_to: returnTo = '/opportunities',
}: OpportunitiesIndexProps) {
  const page = usePage()
  const pageErrors = page.props.errors as Record<string, unknown> | undefined
  const updateErrorsPresent = hasOpportunityUpdateErrors(pageErrors)
  const createErrorsPresent = hasOpportunityCreateErrors(pageErrors)
  const errorOpportunityId = opportunityIdFromErrors(pageErrors)
  const updateErrorKey = updateErrorsPresent ? JSON.stringify(pageErrors) : null
  const createErrorKey = createErrorsPresent ? JSON.stringify(pageErrors) : null

  const [manualId, setManualId] = useState<number | null>(null)
  const [dismissedUpdateErrorKey, setDismissedUpdateErrorKey] = useState<string | null>(null)
  const [createManualOpen, setCreateManualOpen] = useState(false)
  const [dismissedCreateErrorKey, setDismissedCreateErrorKey] = useState<string | null>(null)

  const updateErrorStillOpen = updateErrorKey != null && dismissedUpdateErrorKey !== updateErrorKey
  const selectedId = manualId ?? (updateErrorStillOpen ? errorOpportunityId : null)
  const selected = findOpportunity(stages, selectedId)
  const drawerOpen = selected != null

  const createModalOpen =
    createManualOpen || (createErrorKey != null && dismissedCreateErrorKey !== createErrorKey)

  function openDrawer(opportunity: OpportunityCard) {
    setDismissedUpdateErrorKey(null)
    setManualId(opportunity.id)
  }

  function closeDrawer() {
    setManualId(null)
    if (updateErrorKey != null) setDismissedUpdateErrorKey(updateErrorKey)
  }

  function openCreateModal() {
    setDismissedCreateErrorKey(null)
    setCreateManualOpen(true)
  }

  function closeCreateModal() {
    setCreateManualOpen(false)
    if (createErrorKey != null) setDismissedCreateErrorKey(createErrorKey)
  }

  return (
    <AuthenticatedPage>
      <Head title="Opportunities" />

      <div>
        <div className="flex flex-col gap-4 sm:flex-row sm:items-end sm:justify-between">
          <div>
            <h1 className="text-2xl font-semibold text-slate-900">Opportunities</h1>
            <p className="mt-1 text-slate-600">Pipeline by stage across your scoped leads.</p>
          </div>

          {canCreate && (
            <button
              type="button"
              onClick={openCreateModal}
              className="inline-flex items-center justify-center rounded-lg bg-indigo-600 px-4 py-2 text-sm font-medium text-white hover:bg-indigo-500"
            >
              New opportunity
            </button>
          )}
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

      {canCreate && (
        <OpportunityFormModal
          open={createModalOpen}
          onClose={closeCreateModal}
          leads={leads}
          stages={stageOptions}
          defaults={defaults}
          returnTo={returnTo}
        />
      )}
    </AuthenticatedPage>
  )
}
