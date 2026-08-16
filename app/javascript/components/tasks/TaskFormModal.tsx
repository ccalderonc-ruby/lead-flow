import { useForm } from '@inertiajs/react'
import { FormEvent, useRef } from 'react'

import { FieldError, SelectField, TextAreaField, TextField } from '@/components/ui/FormFields'
import { useDialogA11y } from '@/hooks/useDialogA11y'

export type TaskFormOption = {
  id: number
  name: string
}

export type TaskFormDefaults = {
  user_id: number | null
  force_assignee: boolean
}

export type TaskFormValues = {
  title: string
  description: string
  due_date: string
  lead_id: string
  user_id: string
  status: string
  return_to: string
}

export type EditableTask = {
  id: number
  title: string
  description?: string | null
  due_date: string | null
  lead_id: number | null
  user_id?: number | null
  status: string | null
  can_revert?: boolean
}

type TaskFormModalProps = {
  open: boolean
  onClose: () => void
  leads: TaskFormOption[]
  assignees: TaskFormOption[]
  defaults: TaskFormDefaults
  returnTo: string
  lockedLeadId?: number | null
  task?: EditableTask | null
}

const STATUS_OPTIONS = [
  { value: 'pending', label: 'Pending' },
  { value: 'in_progress', label: 'In progress' },
  { value: 'completed', label: 'Completed' },
] as const

function editableStatus(status: string | null | undefined): string {
  if (!status || status === 'overdue') return 'pending'
  return status
}

function fieldError(errors: Record<string, string | string[] | undefined>, key: string): string | null {
  const value = errors[key]
  if (!value) return null
  return Array.isArray(value) ? value.join(', ') : value
}

export default function TaskFormModal({
  open,
  onClose,
  leads,
  assignees,
  defaults,
  returnTo,
  lockedLeadId = null,
  task = null,
}: TaskFormModalProps) {
  const editing = task != null
  const initialLeadId =
    lockedLeadId != null
      ? String(lockedLeadId)
      : task?.lead_id != null
        ? String(task.lead_id)
        : leads[0]
          ? String(leads[0].id)
          : ''

  const form = useForm<TaskFormValues>({
    title: task?.title ?? '',
    description: task?.description ?? '',
    due_date: task?.due_date ?? '',
    lead_id: initialLeadId,
    user_id:
      task?.user_id != null
        ? String(task.user_id)
        : defaults.user_id != null
          ? String(defaults.user_id)
          : '',
    status: editableStatus(task?.status),
    return_to: returnTo,
  })
  const dialogRef = useRef<HTMLDivElement>(null)

  function resetForm() {
    form.setData({
      title: task?.title ?? '',
      description: task?.description ?? '',
      due_date: task?.due_date ?? '',
      lead_id: initialLeadId,
      user_id:
        task?.user_id != null
          ? String(task.user_id)
          : defaults.user_id != null
            ? String(defaults.user_id)
            : '',
      status: editableStatus(task?.status),
      return_to: returnTo,
    })
    form.clearErrors()
  }

  function handleClose() {
    if (form.processing) return
    resetForm()
    onClose()
  }

  useDialogA11y({ open, onClose: handleClose, containerRef: dialogRef })

  if (!open) return null

  // Completed tasks: only owner/admin can leave completed (can_revert). Others stay locked on completed.
  const statusOptions =
    task?.status === 'completed' && !task.can_revert
      ? STATUS_OPTIONS.filter((option) => option.value === 'completed')
      : STATUS_OPTIONS

  function submit(event: FormEvent) {
    event.preventDefault()
    form.transform((data) => ({
      ...data,
      return_to: returnTo,
      lead_id: lockedLeadId != null ? String(lockedLeadId) : data.lead_id,
    }))

    if (editing && task) {
      form.patch(`/tasks/${task.id}`, {
        preserveScroll: true,
        onSuccess: () => {
          resetForm()
          onClose()
        },
      })
      return
    }

    form.post('/tasks', {
      preserveScroll: true,
      onSuccess: () => {
        resetForm()
        onClose()
      },
    })
  }

  return (
    <div ref={dialogRef} className="fixed inset-0 z-50 flex items-center justify-center bg-slate-900/40 p-4">
      <div
        role="dialog"
        aria-modal="true"
        aria-labelledby="task-form-title"
        className="max-h-[min(90dvh,90vh)] w-full max-w-lg overflow-y-auto rounded-xl border border-slate-200 bg-panel p-6 shadow-lg"
      >
        <div className="flex items-start justify-between gap-4">
          <div>
            <h2 id="task-form-title" className="text-lg font-semibold text-slate-900">
              {editing ? 'Edit task' : 'New task'}
            </h2>
            <p className="mt-1 text-sm text-slate-600">
              {editing ? 'Update follow-up details or status.' : 'Create a follow-up with a due date.'}
            </p>
          </div>
          <button
            type="button"
            onClick={handleClose}
            disabled={form.processing}
            className="inline-flex min-h-11 items-center px-2 text-sm font-medium text-slate-500 hover:text-slate-700 disabled:cursor-not-allowed disabled:opacity-50"
          >
            Close
          </button>
        </div>

        <form onSubmit={submit} className="mt-6 space-y-4">
          {fieldError(form.errors, 'base') && (
            <p className="rounded-lg border border-red-200 bg-red-50 px-3 py-2 text-sm text-red-700">
              {fieldError(form.errors, 'base')}
            </p>
          )}

          <TextField
            id="task-title"
            label="Title"
            required
            value={form.data.title}
            onChange={(value) => form.setData('title', value)}
            error={fieldError(form.errors, 'title')}
          />

          <TextAreaField
            id="task-description"
            label="Description"
            rows={3}
            value={form.data.description}
            onChange={(value) => form.setData('description', value)}
            error={fieldError(form.errors, 'description')}
          />

          <TextField
            id="task-due-date"
            label="Due date"
            type="date"
            required
            value={form.data.due_date}
            onChange={(value) => form.setData('due_date', value)}
            error={fieldError(form.errors, 'due_date')}
          />

          {editing ? (
            <SelectField
              id="task-status"
              label="Status"
              required
              value={form.data.status}
              onChange={(value) => form.setData('status', value)}
              error={fieldError(form.errors, 'status')}
            >
              {statusOptions.map((option) => (
                <option key={option.value} value={option.value}>
                  {option.label}
                </option>
              ))}
            </SelectField>
          ) : null}

          {lockedLeadId != null || editing ? (
            <div>
              <p className="block text-sm font-medium text-slate-700">
                Lead <span className="text-red-600">*</span>
              </p>
              <p className="mt-1 text-sm text-slate-900">
                {leads.find((lead) => lead.id === (lockedLeadId ?? task?.lead_id))?.name ||
                  'Selected lead'}
              </p>
              <FieldError error={fieldError(form.errors, 'lead_id') || fieldError(form.errors, 'lead')} />
            </div>
          ) : (
            <SelectField
              id="task-lead"
              label="Lead"
              required
              value={form.data.lead_id}
              onChange={(value) => form.setData('lead_id', value)}
              error={fieldError(form.errors, 'lead_id') || fieldError(form.errors, 'lead')}
            >
              <option value="">Select a lead</option>
              {leads.map((lead) => (
                <option key={lead.id} value={lead.id}>
                  {lead.name}
                </option>
              ))}
            </SelectField>
          )}

          {defaults.force_assignee ? (
            <div>
              <p className="block text-sm font-medium text-slate-700">
                Assignee <span className="text-red-600">*</span>
              </p>
              <p className="mt-1 text-sm text-slate-900">
                {assignees.find((user) => String(user.id) === form.data.user_id)?.name || 'You'}
              </p>
              <FieldError error={fieldError(form.errors, 'user_id') || fieldError(form.errors, 'user')} />
            </div>
          ) : (
            <SelectField
              id="task-assignee"
              label="Assignee"
              required
              value={form.data.user_id}
              onChange={(value) => form.setData('user_id', value)}
              error={fieldError(form.errors, 'user_id') || fieldError(form.errors, 'user')}
            >
              {assignees.map((user) => (
                <option key={user.id} value={user.id}>
                  {user.name}
                </option>
              ))}
            </SelectField>
          )}

          <div className="flex justify-end gap-2 pt-2">
            <button
              type="button"
              onClick={handleClose}
              disabled={form.processing}
              className="rounded-lg border border-slate-300 px-4 py-2 text-sm font-medium text-slate-700 hover:bg-slate-50 disabled:cursor-not-allowed disabled:opacity-50"
            >
              Cancel
            </button>
            <button
              type="submit"
              disabled={form.processing}
              className="rounded-lg bg-brand px-4 py-2 text-sm font-medium text-white hover:bg-brand-hover disabled:opacity-60"
            >
              {form.processing ? (editing ? 'Saving…' : 'Creating…') : editing ? 'Save changes' : 'Create task'}
            </button>
          </div>
        </form>
      </div>
    </div>
  )
}
