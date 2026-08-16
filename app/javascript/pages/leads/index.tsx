import { Head, Link, router } from '@inertiajs/react'
import { FormEvent, useEffect, useState } from 'react'

import AuthenticatedPage from '@/components/layouts/AuthenticatedPage'
import Button from '@/components/ui/Button'
import ActiveFilters from '@/components/ui/ActiveFilters'
import EmptyState from '@/components/ui/EmptyState'
import { SelectField } from '@/components/ui/FormFields'
import PageHeader from '@/components/ui/PageHeader'
import PaginationBar from '@/components/ui/PaginationBar'
import {
  DataTable,
  DataTableBody,
  DataTableCell,
  DataTableEmpty,
  DataTableHead,
  DataTableHeaderCell,
  DataTableRow,
} from '@/components/ui/DataTable'
import { formatCurrency, formatDate } from '@/lib/format'

export type LeadRow = {
  id: number
  name: string
  email: string
  company: string
  stage: string
  advisor: string
  last_activity_at: string | null
  estimated_value: string | number | null
  can_update: boolean
}

export type LeadFilterOption = {
  id: number
  name: string
}

export type LeadsMeta = {
  q: string
  stage_id: number | null
  user_id: number | null
  page: number
  per_page: number
  total_count: number
  total_pages: number
}

type LeadsIndexProps = {
  leads: LeadRow[]
  meta: LeadsMeta
  stages: LeadFilterOption[]
  assignees: LeadFilterOption[]
  can_filter_assignee: boolean
  can_create: boolean
  can_export: boolean
  show_subscribe_for_export: boolean
  show_admin_subscribe_link?: boolean
}

function leadsQueryParams(
  meta: LeadsMeta,
  overrides: Partial<{ q: string; stage_id: string; user_id: string; page: number; per_page: number }> = {},
) {
  const q = overrides.q !== undefined ? overrides.q : meta.q
  const stageId =
    overrides.stage_id !== undefined
      ? overrides.stage_id
      : meta.stage_id != null
        ? String(meta.stage_id)
        : ''
  const userId =
    overrides.user_id !== undefined
      ? overrides.user_id
      : meta.user_id != null
        ? String(meta.user_id)
        : ''
  const page = overrides.page !== undefined ? overrides.page : meta.page
  const perPage = overrides.per_page !== undefined ? overrides.per_page : meta.per_page

  return {
    q: q.trim() || undefined,
    stage_id: stageId || undefined,
    user_id: userId || undefined,
    page: page > 1 ? page : undefined,
    per_page: perPage !== 25 ? perPage : undefined,
  }
}

function exportHref(meta: LeadsMeta) {
  const params = new URLSearchParams()
  const q = meta.q.trim()
  if (q) params.set('q', q)
  if (meta.stage_id != null) params.set('stage_id', String(meta.stage_id))
  const qs = params.toString()
  return qs ? `/leads/export?${qs}` : '/leads/export'
}

export default function LeadsIndex({
  leads,
  meta,
  stages,
  assignees,
  can_filter_assignee: canFilterAssignee,
  can_create: canCreate,
  can_export: canExport,
  show_subscribe_for_export: showSubscribeForExport,
  show_admin_subscribe_link: showAdminSubscribeLink = false,
}: LeadsIndexProps) {
  const [query, setQuery] = useState(meta.q)

  useEffect(() => {
    setQuery(meta.q)
  }, [meta.q])

  function submitSearch(event: FormEvent) {
    event.preventDefault()
    router.get('/leads', leadsQueryParams(meta, { q: query, page: 1 }), { preserveState: true })
  }

  function setStageFilter(stageId: string) {
    router.get('/leads', leadsQueryParams(meta, { q: query, stage_id: stageId, page: 1 }), {
      preserveState: true,
    })
  }

  function setAssigneeFilter(userId: string) {
    router.get('/leads', leadsQueryParams(meta, { q: query, user_id: userId, page: 1 }), {
      preserveState: true,
    })
  }

  function clearFilters() {
    setQuery('')
    router.get(
      '/leads',
      meta.per_page !== 25 ? { per_page: meta.per_page } : {},
      { preserveState: true },
    )
  }

  const stageName = stages.find((stage) => stage.id === meta.stage_id)?.name
  const assigneeName = assignees.find((assignee) => assignee.id === meta.user_id)?.name
  const hasActiveFilters = Boolean(meta.q.trim() || meta.stage_id != null || meta.user_id != null)
  const filtersActiveLabel = [
    meta.q.trim() ? `Search “${meta.q.trim()}”` : null,
    stageName ? `Stage: ${stageName}` : null,
    assigneeName ? `Assignee: ${assigneeName}` : null,
  ].filter(Boolean)

  return (
    <AuthenticatedPage>
      <Head title="Leads" />

      <div>
        <PageHeader
          title="Leads"
          description="Search and browse your pipeline prospects."
          actions={
            <>
              {canExport && (
                <a
                  href={exportHref(meta)}
                  className="inline-flex items-center justify-center rounded-lg border border-slate-300 bg-panel px-4 py-2 text-sm font-medium text-slate-700 hover:bg-slate-50"
                >
                  Export CSV
                </a>
              )}
              {showSubscribeForExport &&
                (showAdminSubscribeLink ? (
                  <Link
                    href="/admin/subscriptions"
                    className="inline-flex items-center justify-center rounded-lg border border-amber-300 bg-amber-50 px-4 py-2 text-sm font-medium text-amber-900 hover:bg-amber-100"
                  >
                    Export CSV — subscribe to LeadFlow Pro
                  </Link>
                ) : (
                  <span className="inline-flex items-center justify-center rounded-lg border border-amber-300 bg-amber-50 px-4 py-2 text-sm font-medium text-amber-900">
                    Export CSV — ask an admin for LeadFlow Pro
                  </span>
                ))}
              {canCreate && <Button href="/leads/new">+ Add lead</Button>}
            </>
          }
        />

        {showSubscribeForExport && (
          <p className="mt-3 text-sm text-amber-800">
            Ask an admin to activate LeadFlow Pro so you can export leads as CSV.
          </p>
        )}

        <div className="sticky top-14 z-20 mt-6 space-y-3 rounded-xl border border-slate-200 bg-panel/95 p-4 shadow-sm backdrop-blur lg:top-0">
          <form onSubmit={submitSearch} className="flex flex-col gap-3 sm:flex-row sm:items-end">
            <div className="min-w-0 flex-1">
              <label htmlFor="leads-search" className="block text-sm font-medium text-slate-700">
                Search
              </label>
              <input
                id="leads-search"
                type="search"
                value={query}
                onChange={(event) => setQuery(event.target.value)}
                placeholder="Search name, email, or company"
                className="mt-1 block w-full rounded-lg border border-slate-300 bg-panel px-3 py-2 text-sm text-slate-900 placeholder:text-slate-400 focus:border-brand focus:outline-none focus:ring-2 focus:ring-brand-muted"
              />
            </div>
            <button
              type="submit"
              className="rounded-lg border border-slate-300 bg-panel px-4 py-2 text-sm font-medium text-slate-700 hover:bg-slate-50"
            >
              Search
            </button>
          </form>

          <div className="grid gap-3 sm:grid-cols-2 lg:grid-cols-3">
            <SelectField
              id="leads-stage-filter"
              label="Stage"
              value={meta.stage_id != null ? String(meta.stage_id) : ''}
              onChange={setStageFilter}
            >
              <option value="">All stages</option>
              {stages.map((stage) => (
                <option key={stage.id} value={String(stage.id)}>
                  {stage.name}
                </option>
              ))}
            </SelectField>

            {canFilterAssignee && (
              <SelectField
                id="leads-assignee-filter"
                label="Assignee"
                value={meta.user_id != null ? String(meta.user_id) : ''}
                onChange={setAssigneeFilter}
              >
                <option value="">All assignees</option>
                {assignees.map((assignee) => (
                  <option key={assignee.id} value={String(assignee.id)}>
                    {assignee.name}
                  </option>
                ))}
              </SelectField>
            )}
          </div>

          {hasActiveFilters && (
            <ActiveFilters labels={filtersActiveLabel as string[]} onClear={clearFilters} />
          )}
        </div>

        <DataTable className="mt-6">
          <DataTableHead>
            <tr>
              <DataTableHeaderCell>Name</DataTableHeaderCell>
              <DataTableHeaderCell>Company</DataTableHeaderCell>
              <DataTableHeaderCell>Stage</DataTableHeaderCell>
              <DataTableHeaderCell>Advisor</DataTableHeaderCell>
              <DataTableHeaderCell>Last activity</DataTableHeaderCell>
              <DataTableHeaderCell align="right">Value</DataTableHeaderCell>
              <DataTableHeaderCell align="right">Actions</DataTableHeaderCell>
            </tr>
          </DataTableHead>
          <DataTableBody>
            {leads.length === 0 ? (
              <DataTableEmpty colSpan={7}>
                <EmptyState
                  title={hasActiveFilters ? 'No leads match these filters' : 'No leads yet'}
                  description={
                    hasActiveFilters
                      ? 'Try clearing filters or adjusting your search.'
                      : 'Add your first prospect to start building the pipeline.'
                  }
                  action={
                    hasActiveFilters
                      ? { label: 'Clear filters', onClick: clearFilters }
                      : canCreate
                        ? { label: '+ Add lead', href: '/leads/new' }
                        : undefined
                  }
                />
              </DataTableEmpty>
            ) : (
              leads.map((lead) => (
                <DataTableRow key={lead.id}>
                  <DataTableCell className="font-medium text-slate-900">
                    <Link
                      href={`/leads/${lead.id}`}
                      className="text-brand-ink hover:text-brand"
                    >
                      {lead.name}
                    </Link>
                    {lead.email && <div className="text-xs font-normal text-slate-500">{lead.email}</div>}
                  </DataTableCell>
                  <DataTableCell className="text-slate-700">{lead.company}</DataTableCell>
                  <DataTableCell className="text-slate-700">{lead.stage}</DataTableCell>
                  <DataTableCell className="text-slate-700">{lead.advisor}</DataTableCell>
                  <DataTableCell className="text-slate-700">{formatDate(lead.last_activity_at)}</DataTableCell>
                  <DataTableCell align="right" className="tabular-nums text-slate-900">
                    {formatCurrency(lead.estimated_value)}
                  </DataTableCell>
                  <DataTableCell align="right">
                    {lead.can_update ? (
                      <Link
                        href={`/leads/${lead.id}/edit`}
                        className="inline-flex min-h-11 items-center px-1 text-sm font-medium text-brand-ink hover:text-brand"
                      >
                        Edit
                      </Link>
                    ) : (
                      <span className="text-slate-300">—</span>
                    )}
                  </DataTableCell>
                </DataTableRow>
              ))
            )}
          </DataTableBody>
        </DataTable>

        <PaginationBar
          meta={meta}
          path="/leads"
          label="leads"
          query={{
            q: query.trim() || undefined,
            stage_id: meta.stage_id,
            user_id: meta.user_id,
          }}
        />
      </div>
    </AuthenticatedPage>
  )
}
