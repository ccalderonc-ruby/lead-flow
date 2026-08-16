import { router } from '@inertiajs/react'

export const PER_PAGE_OPTIONS = [10, 25, 50, 100] as const

export type PaginationMeta = {
  page: number
  per_page: number
  total_count: number
  total_pages: number
}

type PaginationBarProps = {
  meta: PaginationMeta
  /** Path without query, e.g. `/leads` */
  path: string
  /** Extra query params to preserve (filters, etc.) */
  query?: Record<string, string | number | undefined | null>
  label?: string
}

function buildParams(
  meta: PaginationMeta,
  query: PaginationBarProps['query'],
  overrides: Partial<{ page: number; per_page: number }>,
) {
  const page = overrides.page ?? meta.page
  const perPage = overrides.per_page ?? meta.per_page
  const params: Record<string, string | number> = {}

  if (query) {
    for (const [key, value] of Object.entries(query)) {
      if (value == null || value === '') continue
      params[key] = value
    }
  }

  if (page > 1) params.page = page
  if (perPage !== 25) params.per_page = perPage

  return params
}

/** Footer: result summary, per-page selector, previous/next. */
export default function PaginationBar({
  meta,
  path,
  query = {},
  label = 'results',
}: PaginationBarProps) {
  function visit(overrides: Partial<{ page: number; per_page: number }>) {
    router.get(path, buildParams(meta, query, overrides), { preserveState: true })
  }

  const summary =
    meta.total_count === 0
      ? `0 ${label}`
      : `Showing page ${meta.page} of ${meta.total_pages} (${meta.total_count} ${label})`

  return (
    <div className="mt-4 flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
      <p className="text-sm text-slate-500">{summary}</p>

      <div className="flex flex-col gap-3 sm:flex-row sm:items-center sm:gap-4">
        <label className="flex min-h-11 items-center gap-2 text-sm text-slate-600">
          <span className="whitespace-nowrap">Per page</span>
          <select
            value={String(meta.per_page)}
            onChange={(event) => visit({ page: 1, per_page: Number(event.target.value) })}
            className="min-h-11 min-w-[4.5rem] rounded-lg border border-slate-300 bg-panel py-2 pl-3 pr-9 text-sm text-slate-900 focus:border-brand focus:outline-none focus:ring-2 focus:ring-brand-muted"
            aria-label="Results per page"
          >
            {PER_PAGE_OPTIONS.map((option) => (
              <option key={option} value={option}>
                {option}
              </option>
            ))}
          </select>
        </label>

        <div className="flex gap-2">
          <button
            type="button"
            disabled={meta.page <= 1 || meta.total_count === 0}
            onClick={() => visit({ page: meta.page - 1 })}
            className="inline-flex min-h-11 items-center rounded-lg border border-slate-300 px-3 py-2.5 text-sm font-medium text-slate-700 enabled:hover:bg-slate-50 disabled:cursor-not-allowed disabled:opacity-40"
          >
            Previous
          </button>
          <button
            type="button"
            disabled={meta.page >= meta.total_pages || meta.total_count === 0}
            onClick={() => visit({ page: meta.page + 1 })}
            className="inline-flex min-h-11 items-center rounded-lg border border-slate-300 px-3 py-2.5 text-sm font-medium text-slate-700 enabled:hover:bg-slate-50 disabled:cursor-not-allowed disabled:opacity-40"
          >
            Next
          </button>
        </div>
      </div>
    </div>
  )
}
