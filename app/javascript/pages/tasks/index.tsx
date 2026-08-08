import { Head, Link, router, usePage } from '@inertiajs/react'
import { useState } from 'react'

import AuthenticatedPage from '@/components/layouts/AuthenticatedPage'
import TaskFormModal, {
  type EditableTask,
  type TaskFormDefaults,
  type TaskFormOption,
} from '@/components/tasks/TaskFormModal'
import { hasTaskCreateErrors } from '@/components/tasks/taskFormErrors'
import { formatDate, formatDateTime, isPastDueDate } from '@/lib/format'

export type TaskRow = {
  id: number
  title: string
  description?: string | null
  lead: string | null
  lead_id: number | null
  due_date: string | null
  status: string | null
  past_due?: boolean
  completed_at?: string | null
  assignee: string | null
  user_id?: number | null
  can_edit: boolean
  can_revert: boolean
}

function formatTaskStatus(status: string | null): string {
  if (!status) return '—'
  if (status === 'in_progress') return 'In progress'
  return status.charAt(0).toUpperCase() + status.slice(1)
}

function taskIsPastDue(task: Pick<TaskRow, 'due_date' | 'status'>): boolean {
  return task.status !== 'completed' && isPastDueDate(task.due_date)
}

export type TasksMeta = {
  filter: 'all' | 'mine' | 'pending' | 'completed' | 'overdue'
  page: number
  per_page: number
  total_count: number
  total_pages: number
}

type TasksIndexProps = {
  tasks: TaskRow[]
  meta: TasksMeta
  can_create: boolean
  leads: TaskFormOption[]
  assignees: TaskFormOption[]
  defaults: TaskFormDefaults
  return_to: string
}

const FILTERS = [
  { value: 'all', label: 'All' },
  { value: 'mine', label: 'Mine' },
  { value: 'pending', label: 'Pending' },
  { value: 'completed', label: 'Completed' },
  { value: 'overdue', label: 'Overdue' },
] as const

function buildTasksReturnTo(meta: TasksMeta): string {
  const params = new URLSearchParams()
  if (meta.filter !== 'all') params.set('filter', meta.filter)
  if (meta.page > 1) params.set('page', String(meta.page))
  const query = params.toString()
  return query ? `/tasks?${query}` : '/tasks'
}

export default function TasksIndex({
  tasks,
  meta,
  can_create: canCreate,
  leads,
  assignees,
  defaults,
  return_to: returnTo,
}: TasksIndexProps) {
  const page = usePage()
  const pageErrors = page.props.errors as Record<string, unknown> | undefined
  const taskErrorsPresent = hasTaskCreateErrors(pageErrors)
  const taskErrorKey = taskErrorsPresent ? JSON.stringify(pageErrors) : null
  const [manualOpen, setManualOpen] = useState(false)
  const [editingTask, setEditingTask] = useState<EditableTask | null>(null)
  const [dismissedTaskErrorKey, setDismissedTaskErrorKey] = useState<string | null>(null)
  const [revertingId, setRevertingId] = useState<number | null>(null)

  const createModalOpen =
    editingTask == null && (manualOpen || (taskErrorKey != null && dismissedTaskErrorKey !== taskErrorKey))

  function openCreateModal() {
    setEditingTask(null)
    setDismissedTaskErrorKey(null)
    setManualOpen(true)
  }

  function openEditModal(task: TaskRow) {
    setManualOpen(false)
    setEditingTask({
      id: task.id,
      title: task.title,
      description: task.description,
      due_date: task.due_date,
      lead_id: task.lead_id,
      user_id: task.user_id,
      status: task.status,
      can_revert: task.can_revert,
    })
  }

  function closeModal() {
    setManualOpen(false)
    setEditingTask(null)
    if (taskErrorKey != null) setDismissedTaskErrorKey(taskErrorKey)
  }

  const createReturnTo = buildTasksReturnTo(meta) || returnTo

  function setFilter(nextFilter: string) {
    router.get(
      '/tasks',
      { filter: nextFilter === 'all' ? undefined : nextFilter, page: 1 },
      { preserveState: true },
    )
  }

  function goToPage(pageNumber: number) {
    router.get(
      '/tasks',
      {
        filter: meta.filter === 'all' ? undefined : meta.filter,
        page: pageNumber,
      },
      { preserveState: true },
    )
  }

  function revertTask(task: TaskRow) {
    if (revertingId != null) return

    setRevertingId(task.id)
    router.patch(
      `/tasks/${task.id}`,
      {
        title: task.title,
        description: task.description ?? '',
        due_date: task.due_date,
        status: 'pending',
        return_to: createReturnTo,
      },
      {
        preserveScroll: true,
        onFinish: () => setRevertingId(null),
      },
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

          <div className="flex flex-col gap-2 sm:flex-row sm:items-center">
            {canCreate && (
              <button
                type="button"
                onClick={openCreateModal}
                className="inline-flex items-center justify-center rounded-lg bg-indigo-600 px-4 py-2 text-sm font-medium text-white hover:bg-indigo-500"
              >
                New task
              </button>
            )}
            <div
              className="flex flex-wrap gap-1 rounded-lg border border-slate-200 bg-white p-1"
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
                <th className="px-4 py-3 text-right">Actions</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-100">
              {tasks.length === 0 ? (
                <tr>
                  <td colSpan={6} className="px-4 py-10 text-center text-slate-500">
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
                    <td
                      className={
                        taskIsPastDue(task)
                          ? 'px-4 py-3 font-medium text-red-600'
                          : 'px-4 py-3 text-slate-700'
                      }
                    >
                      {formatDate(task.due_date)}
                    </td>
                    <td className="px-4 py-3 text-slate-700">
                      <div>{formatTaskStatus(task.status)}</div>
                      {task.status === 'completed' && task.completed_at ? (
                        <div className="mt-0.5 text-xs text-slate-500">
                          Completed {formatDateTime(task.completed_at)}
                        </div>
                      ) : null}
                    </td>
                    <td className="px-4 py-3 text-slate-700">{task.assignee || '—'}</td>
                    <td className="px-4 py-3 text-right">
                      <div className="flex justify-end gap-3">
                        {task.can_edit && (
                          <button
                            type="button"
                            onClick={() => openEditModal(task)}
                            className="text-sm font-medium text-slate-700 hover:text-slate-900"
                          >
                            Edit
                          </button>
                        )}
                        {task.can_revert ? (
                          <button
                            type="button"
                            disabled={revertingId != null}
                            onClick={() => revertTask(task)}
                            className="text-sm font-medium text-amber-700 hover:text-amber-600 disabled:cursor-not-allowed disabled:opacity-50"
                          >
                            {revertingId === task.id ? 'Reopening…' : 'Reopen'}
                          </button>
                        ) : null}
                        {!task.can_edit && !task.can_revert ? (
                          <span className="text-slate-300">—</span>
                        ) : null}
                      </div>
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

      {canCreate && (
        <TaskFormModal
          key="task-create"
          open={createModalOpen}
          onClose={closeModal}
          leads={leads}
          assignees={assignees}
          defaults={defaults}
          returnTo={createReturnTo}
        />
      )}

      {editingTask && (
        <TaskFormModal
          key={`task-edit-${editingTask.id}`}
          open
          onClose={closeModal}
          leads={leads}
          assignees={assignees}
          defaults={defaults}
          returnTo={createReturnTo}
          lockedLeadId={editingTask.lead_id}
          task={editingTask}
        />
      )}
    </AuthenticatedPage>
  )
}
