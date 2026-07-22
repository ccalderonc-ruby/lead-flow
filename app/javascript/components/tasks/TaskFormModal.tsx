import { useForm } from '@inertiajs/react'
import { FormEvent } from 'react'

import { FieldError, SelectField, TextField } from '@/components/ui/FormFields'

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
  due_date: string
  lead_id: string
  user_id: string
  return_to: string
}

type TaskFormModalProps = {
  open: boolean
  onClose: () => void
  leads: TaskFormOption[]
  assignees: TaskFormOption[]
  defaults: TaskFormDefaults
  returnTo: string
  lockedLeadId?: number | null
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
}: TaskFormModalProps) {
  const initialLeadId =
    lockedLeadId != null
      ? String(lockedLeadId)
      : leads[0]
        ? String(leads[0].id)
        : ''

  const form = useForm<TaskFormValues>({
    title: '',
    due_date: '',
    lead_id: initialLeadId,
    user_id: defaults.user_id != null ? String(defaults.user_id) : '',
    return_to: returnTo,
  })

  if (!open) return null

  function resetForm() {
    form.setData({
      title: '',
      due_date: '',
      lead_id: initialLeadId,
      user_id: defaults.user_id != null ? String(defaults.user_id) : '',
      return_to: returnTo,
    })
    form.clearErrors()
  }

  function handleClose() {
    if (form.processing) return
    resetForm()
    onClose()
  }

  function submit(event: FormEvent) {
    event.preventDefault()
    form.transform((data) => ({
      ...data,
      return_to: returnTo,
      lead_id: lockedLeadId != null ? String(lockedLeadId) : data.lead_id,
    }))
    form.post('/tasks', {
      preserveScroll: true,
      onSuccess: () => {
        resetForm()
        onClose()
      },
    })
  }

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-slate-900/40 p-4">
      <div
        role="dialog"
        aria-modal="true"
        aria-labelledby="new-task-title"
        className="w-full max-w-lg rounded-xl border border-slate-200 bg-white p-6 shadow-lg"
      >
        <div className="flex items-start justify-between gap-4">
          <div>
            <h2 id="new-task-title" className="text-lg font-semibold text-slate-900">
              New task
            </h2>
            <p className="mt-1 text-sm text-slate-600">Create a follow-up with a due date.</p>
          </div>
          <button
            type="button"
            onClick={handleClose}
            disabled={form.processing}
            className="text-sm font-medium text-slate-500 hover:text-slate-700 disabled:cursor-not-allowed disabled:opacity-50"
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

          <TextField
            id="task-due-date"
            label="Due date"
            type="date"
            required
            value={form.data.due_date}
            onChange={(value) => form.setData('due_date', value)}
            error={fieldError(form.errors, 'due_date')}
          />

          {lockedLeadId != null ? (
            <div>
              <p className="block text-sm font-medium text-slate-700">
                Lead <span className="text-red-600">*</span>
              </p>
              <p className="mt-1 text-sm text-slate-900">
                {leads.find((lead) => lead.id === lockedLeadId)?.name || 'Selected lead'}
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
              className="rounded-lg bg-indigo-600 px-4 py-2 text-sm font-medium text-white hover:bg-indigo-500 disabled:opacity-60"
            >
              {form.processing ? 'Creating…' : 'Create task'}
            </button>
          </div>
        </form>
      </div>
    </div>
  )
}
