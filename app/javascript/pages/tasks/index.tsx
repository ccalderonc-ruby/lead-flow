import { Head, Link, router } from '@inertiajs/react'

import AuthenticatedPage from '@/components/layouts/AuthenticatedPage'

export type TaskRow = {
  id: number
  title: string
  lead: string | null
  lead_id: number | null
  due_date: string | null
  status: string | null
  assignee: string | null
}

export type TasksMeta = {
  filter: 'all' | 'mine' | 'overdue'
  page: number
  per_page: number
  total_count: number
  total_pages: number
}

type TasksIndexProps = {
  tasks: TaskRow[]
  meta: TasksMeta
}

const FILTERS = [
  { value: 'all', label: 'All' },
  { value: 'mine', label: 'Mine' },
  { value: 'overdue', label: 'Overdue' },
] as const

function formatDate(iso: string | null): string {
  if (!iso) return '—'

  if (/^\d{4}-\d{2}-\d{2}$/.test(iso)) {
    const [year, month, day] = iso.split('-').map(Number)
    return new Intl.DateTimeFormat('en-US', {
      month: 'short',
      day: 'numeric',
      year: 'numeric',
      timeZone: 'UTC',
    }).format(new Date(Date.UTC(year, month - 1, day)))
  }

  const parsed = new Date(iso)
  if (Number.isNaN(parsed.getTime())) return '—'

  return new Intl.DateTimeFormat('en-US', {
    month: 'short',
    day: 'numeric',
    year: 'numeric',
  }).format(parsed)
}

export default function TasksIndex({ tasks, meta }: TasksIndexProps) {
  function setFilter(nextFilter: string) {
    router.get(
      '/tasks',
      { filter: nextFilter === 'all' ? undefined : nextFilter, page: 1 },
      { preserveState: true },
    )
  }

  function goToPage(page: number) {
    router.get(
      '/tasks',
      {
        filter: meta.filter === 'all' ? undefined : meta.filter,
        page,
      },
      { preserveState: true },
    )
  }

  return (
    <AuthenticatedPage>
      <Head title="Tasks" />

      <div>
        <div className="flex flex-col gap-4 sm:flex-row sm:items-end sm:justify-between">
          <div>
            <h1 className="text-2xl font-semibold text-slate-900">Tasks</h1>
            <p className="mt-1 text-slate-600">Prioritize follow-ups across your leads.</p>
          </div>

          <div
            className="flex gap-1 rounded-lg border border-slate-200 bg-white p-1"
            role="group"
            aria-label="Task filters"
          >
            {FILTERS.map((item) => {
              const active = meta.filter === item.value
              return (
                <button
                  key={item.value}
                  type="button"
                  aria-pressed={active}
                  onClick={() => setFilter(item.value)}
                  className={
                    active
                      ? 'rounded-md bg-indigo-600 px-3 py-1.5 text-sm font-medium text-white'
                      : 'rounded-md px-3 py-1.5 text-sm font-medium text-slate-600 hover:bg-slate-50'
                  }
                >
                  {item.label}
                </button>
              )
            })}
          </div>
        </div>

        <div className="mt-8 overflow-x-auto rounded-xl border border-slate-200 bg-white">
          <table className="min-w-full divide-y divide-slate-200 text-left text-sm">
            <thead className="bg-slate-50 text-xs font-semibold uppercase tracking-wide text-slate-500">
              <tr>
                <th className="px-4 py-3">Title</th>
                <th className="px-4 py-3">Lead</th>
                <th className="px-4 py-3">Due date</th>
                <th className="px-4 py-3">Status</th>
                <th className="px-4 py-3">Assignee</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-100">
              {tasks.length === 0 ? (
                <tr>
                  <td colSpan={5} className="px-4 py-10 text-center text-slate-500">
                    No tasks found.
                  </td>
                </tr>
              ) : (
                tasks.map((task) => (
                  <tr key={task.id} className="hover:bg-slate-50">
                    <td className="px-4 py-3 font-medium text-slate-900">{task.title}</td>
                    <td className="px-4 py-3 text-slate-700">
                      {task.lead_id ? (
                        <Link
                          href={`/leads/${task.lead_id}`}
                          className="font-medium text-indigo-600 hover:text-indigo-500"
                        >
                          {task.lead || '—'}
                        </Link>
                      ) : (
                        task.lead || '—'
                      )}
                    </td>
                    <td className="px-4 py-3 text-slate-700">{formatDate(task.due_date)}</td>
                    <td className="px-4 py-3 text-slate-700">{task.status || '—'}</td>
                    <td className="px-4 py-3 text-slate-700">{task.assignee || '—'}</td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>

        <div className="mt-4 flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
          <p className="text-sm text-slate-500">
            {meta.total_count === 0
              ? '0 tasks'
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
