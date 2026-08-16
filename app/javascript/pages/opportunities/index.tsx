import { Head, router, usePage } from '@inertiajs/react'
import { useEffect, useState } from 'react'

import AuthenticatedPage from '@/components/layouts/AuthenticatedPage'
import OpportunityBoard, {
  type OpportunityCard,
  type PipelineStage,
} from '@/components/opportunities/OpportunityBoard'
import OpportunityDrawer, {
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

type OwnerOption = {
  id: number
  name: string
}

type OpportunitiesMeta = {
  user_id: number | null
  opportunity_id: number | null
}

type OpportunitiesIndexProps = {
  stages: PipelineStage[]
  stage_options: OpportunityStageOption[]
  owners: OwnerOption[]
  meta: OpportunitiesMeta
  can_create: boolean
  leads: OpportunityFormOption[]
  defaults: OpportunityFormDefaults
  return_to: string
}

function opportunitiesQueryParams(userId: string) {
  return {
    user_id: userId || undefined,
  }
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
  owners = [],
  meta = { user_id: null, opportunity_id: null },
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

  const [manualId, setManualId] = useState<number | null>(meta.opportunity_id)
  const [dismissedUpdateErrorKey, setDismissedUpdateErrorKey] = useState<string | null>(null)
  const [createManualOpen, setCreateManualOpen] = useState(false)
  const [dismissedCreateErrorKey, setDismissedCreateErrorKey] = useState<string | null>(null)

  useEffect(() => {
    setManualId(meta.opportunity_id)
  }, [meta.opportunity_id])

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
    if (meta.opportunity_id != null) {
      router.get(
        '/opportunities',
        opportunitiesQueryParams(meta.user_id != null ? String(meta.user_id) : ''),
        { preserveState: true, preserveScroll: true, replace: true },
      )
    }
  }

  function openCreateModal() {
    setDismissedCreateErrorKey(null)
    setCreateManualOpen(true)
  }

  function closeCreateModal() {
    setCreateManualOpen(false)
    if (createErrorKey != null) setDismissedCreateErrorKey(createErrorKey)
  }

  function setOwnerFilter(userId: string) {
    router.get('/opportunities', opportunitiesQueryParams(userId), { preserveState: true })
  }

  const selectedOwnerName =
    meta.user_id != null ? owners.find((owner) => owner.id === meta.user_id)?.name : null

  return (
    <AuthenticatedPage>
      <Head title="Opportunities" />

      <div className="flex h-[calc(100vh-7.5rem)] min-h-[28rem] min-w-0 flex-col lg:h-[calc(100vh-8.5rem)]">
        <div className="flex shrink-0 flex-col gap-4 sm:flex-row sm:items-end sm:justify-between">
          <div className="min-w-0">
            <h1 className="text-2xl font-semibold text-slate-900">Opportunities</h1>
            <p className="mt-1 text-slate-600">Pipeline by stage across your scoped leads.</p>
          </div>

          <div className="flex shrink-0 flex-col gap-3 sm:flex-row sm:items-center">
            <div className="relative">
              <div
                className={`inline-flex items-center gap-2 rounded-full border bg-panel px-3 py-1.5 text-sm shadow-sm ${
                  meta.user_id != null
                    ? 'border-brand-muted text-slate-800'
                    : 'border-slate-200 text-slate-700'
                }`}
              >
                <svg
                  aria-hidden="true"
                  viewBox="0 0 20 20"
                  fill="none"
                  className="h-4 w-4 shrink-0 text-slate-500"
                >
                  <path
                    d="M3 4.5h14l-5.5 6.25V15l-3 1.5v-5.75L3 4.5Z"
                    stroke="currentColor"
                    strokeWidth="1.5"
                    strokeLinejoin="round"
                  />
                </svg>
                <span className="pointer-events-none font-medium">
                  Filter: Owner
                  {selectedOwnerName ? (
                    <span className="font-normal text-slate-500"> · {selectedOwnerName}</span>
                  ) : null}
                </span>
              </div>
              <select
                id="opportunities-owner-filter"
                aria-label="Filter: Owner"
                value={meta.user_id != null ? String(meta.user_id) : ''}
                onChange={(event) => setOwnerFilter(event.target.value)}
                className="absolute inset-0 cursor-pointer opacity-0"
              >
                <option value="">All owners</option>
                {owners.map((owner) => (
                  <option key={owner.id} value={String(owner.id)}>
                    {owner.name}
                  </option>
                ))}
              </select>
            </div>

            {canCreate && (
              <button
                type="button"
                onClick={openCreateModal}
                className="inline-flex shrink-0 items-center justify-center rounded-lg bg-brand px-4 py-2 text-sm font-medium text-white hover:bg-brand-hover"
              >
                New opportunity
              </button>
            )}
          </div>
        </div>

        <OpportunityBoard stages={stages} returnTo={returnTo} onOpen={openDrawer} />
      </div>

      <OpportunityDrawer
        key={selected?.id ?? 'closed'}
        open={drawerOpen}
        opportunity={selected}
        stageOptions={stageOptions}
        returnTo={returnTo}
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
