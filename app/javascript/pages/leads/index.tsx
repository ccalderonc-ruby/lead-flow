import { Head, Link, router } from '@inertiajs/react'
import { FormEvent, useEffect, useState } from 'react'

import AuthenticatedPage from '@/components/layouts/AuthenticatedPage'
import Button from '@/components/ui/Button'
import EmptyState from '@/components/ui/EmptyState'
import { SelectField } from '@/components/ui/FormFields'
import PageHeader from '@/components/ui/PageHeader'
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
  overrides: Partial<{ q: string; stage_id: string; user_id: string; page: number }> = {},
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

  return {
    q: q.trim() || undefined,
    stage_id: stageId || undefined,
    user_id: userId || undefined,
    page: page > 1 ? page : undefined,
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

  function goToPage(page: number) {
    router.get('/leads', leadsQueryParams(meta, { q: query, page }), { preserveState: true })
  }

  function clearFilters() {
    setQuery('')
    router.get('/leads', {}, { preserveState: true })
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
            <div className="flex flex-wrap items-center gap-2">
              <p className="text-sm text-slate-600">Active filters:</p>
              {filtersActiveLabel.map((label) => (
                <span
                  key={label}
                  className="inline-flex rounded-full bg-brand-subtle px-2.5 py-1 text-xs font-medium text-brand-ink"
                >
                  {label}
                </span>
              ))}
              <button
                type="button"
                onClick={clearFilters}
                className="inline-flex min-h-11 items-center px-1 text-sm font-medium text-brand-ink hover:text-brand"
              >
                Clear all
              </button>
            </div>
          )}
        </div>

        <div className="mt-6 overflow-x-auto rounded-xl border border-slate-200 bg-panel">
          <table className="min-w-full divide-y divide-slate-200 text-left text-sm">
            <thead className="bg-slate-50 text-xs font-semibold uppercase tracking-wide text-slate-500">
              <tr>
                <th className="px-4 py-3">Name</th>
                <th className="px-4 py-3">Company</th>
                <th className="px-4 py-3">Stage</th>
                <th className="px-4 py-3">Advisor</th>
                <th className="px-4 py-3">Last activity</th>
                <th className="px-4 py-3 text-right">Value</th>
                <th className="px-4 py-3 text-right">Actions</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-100">
              {leads.length === 0 ? (
                <tr>
                  <td colSpan={7} className="p-0">
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
                  </td>
                </tr>
              ) : (
                leads.map((lead) => (
                  <tr key={lead.id} className="hover:bg-slate-50">
                    <td className="px-4 py-3 font-medium text-slate-900">
                      <Link
                        href={`/leads/${lead.id}`}
                        className="text-brand-ink hover:text-brand"
                      >
                        {lead.name}
                      </Link>
                      {lead.email && <div className="text-xs font-normal text-slate-500">{lead.email}</div>}
                    </td>
                    <td className="px-4 py-3 text-slate-700">{lead.company}</td>
                    <td className="px-4 py-3 text-slate-700">{lead.stage}</td>
                    <td className="px-4 py-3 text-slate-700">{lead.advisor}</td>
                    <td className="px-4 py-3 text-slate-700">{formatDate(lead.last_activity_at)}</td>
                    <td className="px-4 py-3 text-right tabular-nums text-slate-900">
                      {formatCurrency(lead.estimated_value)}
                    </td>
                    <td className="px-4 py-3 text-right">
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
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>

        <div className="mt-4 flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
          <p className="text-sm text-slate-500">
            {meta.total_count === 0
              ? '0 leads'
              : `Showing page ${meta.page} of ${meta.total_pages} (${meta.total_count} total)`}
          </p>
          <div className="flex gap-2">
            <button
              type="button"
              disabled={meta.page <= 1}
              onClick={() => goToPage(meta.page - 1)}
              className="inline-flex min-h-11 items-center rounded-lg border border-slate-300 px-3 py-2.5 text-sm font-medium text-slate-700 enabled:hover:bg-slate-50 disabled:cursor-not-allowed disabled:opacity-40"
            >
              Previous
            </button>
            <button
              type="button"
              disabled={meta.page >= meta.total_pages}
              onClick={() => goToPage(meta.page + 1)}
              className="inline-flex min-h-11 items-center rounded-lg border border-slate-300 px-3 py-2.5 text-sm font-medium text-slate-700 enabled:hover:bg-slate-50 disabled:cursor-not-allowed disabled:opacity-40"
            >
              Next
            </button>
          </div>
        </div>
      </div>
    </AuthenticatedPage>
  )
}
