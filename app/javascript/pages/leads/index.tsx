import { Head, Link, router } from '@inertiajs/react'
import { FormEvent, useEffect, useState } from 'react'

import AuthenticatedPage from '@/components/layouts/AuthenticatedPage'

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

export type LeadsMeta = {
  q: string
  page: number
  per_page: number
  total_count: number
  total_pages: number
}

type LeadsIndexProps = {
  leads: LeadRow[]
  meta: LeadsMeta
  can_create: boolean
}

function formatCurrency(amount: string | number | null): string {
  if (amount == null || amount === '') return '—'
  const value = typeof amount === 'number' ? amount : Number(amount)
  if (Number.isNaN(value)) return '—'
  return new Intl.NumberFormat('en-US', {
    style: 'currency',
    currency: 'USD',
    maximumFractionDigits: 0,
  }).format(value)
}

function formatActivity(iso: string | null): string {
  if (!iso) return '—'
  return new Intl.DateTimeFormat('en-US', {
    month: 'short',
    day: 'numeric',
    year: 'numeric',
  }).format(new Date(iso))
}

export default function LeadsIndex({ leads, meta, can_create: canCreate }: LeadsIndexProps) {
  const [query, setQuery] = useState(meta.q)

  useEffect(() => {
    setQuery(meta.q)
  }, [meta.q])

  function submitSearch(event: FormEvent) {
    event.preventDefault()
    const nextQuery = query.trim()
    router.get(
      '/leads',
      { q: nextQuery || undefined, page: 1 },
      { preserveState: true },
    )
  }

  function goToPage(page: number) {
    router.get(
      '/leads',
      { q: meta.q || undefined, page },
      { preserveState: true },
    )
  }

  return (
    <AuthenticatedPage>
      <Head title="Leads" />

      <div>
        <div className="flex flex-col gap-4 sm:flex-row sm:items-end sm:justify-between">
          <div>
            <h1 className="text-2xl font-semibold text-slate-900">Leads</h1>
            <p className="mt-1 text-slate-600">Search and browse your pipeline prospects.</p>
          </div>

          <div className="flex w-full flex-col gap-2 sm:w-auto sm:flex-row sm:items-center">
            {canCreate && (
              <Link
                href="/leads/new"
                className="inline-flex items-center justify-center rounded-lg bg-indigo-600 px-4 py-2 text-sm font-medium text-white hover:bg-indigo-500"
              >
                New lead
              </Link>
            )}
            <form onSubmit={submitSearch} className="flex w-full gap-2 sm:w-auto">
              <label htmlFor="leads-search" className="sr-only">
                Search leads
              </label>
              <input
                id="leads-search"
                type="search"
                value={query}
                onChange={(event) => setQuery(event.target.value)}
                placeholder="Search name, email, or company"
                className="min-w-0 flex-1 rounded-lg border border-slate-300 px-3 py-2 text-sm text-slate-900 placeholder:text-slate-400 focus:border-indigo-500 focus:outline-none focus:ring-2 focus:ring-indigo-200 sm:w-72"
              />
              <button
                type="submit"
                className="rounded-lg border border-slate-300 bg-white px-4 py-2 text-sm font-medium text-slate-700 hover:bg-slate-50"
              >
                Search
              </button>
            </form>
          </div>
        </div>

        <div className="mt-8 overflow-x-auto rounded-xl border border-slate-200 bg-white">
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
                  <td colSpan={7} className="px-4 py-10 text-center text-slate-500">
                    No leads found.
                  </td>
                </tr>
              ) : (
                leads.map((lead) => (
                  <tr key={lead.id} className="hover:bg-slate-50">
                    <td className="px-4 py-3 font-medium text-slate-900">
                      <div>{lead.name}</div>
                      {lead.email && <div className="text-xs font-normal text-slate-500">{lead.email}</div>}
                    </td>
                    <td className="px-4 py-3 text-slate-700">{lead.company}</td>
                    <td className="px-4 py-3 text-slate-700">{lead.stage}</td>
                    <td className="px-4 py-3 text-slate-700">{lead.advisor}</td>
                    <td className="px-4 py-3 text-slate-700">{formatActivity(lead.last_activity_at)}</td>
                    <td className="px-4 py-3 text-right tabular-nums text-slate-900">
                      {formatCurrency(lead.estimated_value)}
                    </td>
                    <td className="px-4 py-3 text-right">
                      {lead.can_update ? (
                        <Link
                          href={`/leads/${lead.id}/edit`}
                          className="text-sm font-medium text-indigo-600 hover:text-indigo-500"
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
              className="rounded-lg border border-slate-300 px-3 py-1.5 text-sm font-medium text-slate-700 enabled:hover:bg-slate-50 disabled:cursor-not-allowed disabled:opacity-40"
            >
              Previous
            </button>
            <button
              type="button"
              disabled={meta.page >= meta.total_pages}
              onClick={() => goToPage(meta.page + 1)}
              className="rounded-lg border border-slate-300 px-3 py-1.5 text-sm font-medium text-slate-700 enabled:hover:bg-slate-50 disabled:cursor-not-allowed disabled:opacity-40"
            >
              Next
            </button>
          </div>
        </div>
      </div>
    </AuthenticatedPage>
  )
}
