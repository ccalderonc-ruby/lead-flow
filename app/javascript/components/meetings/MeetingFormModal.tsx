import { useForm } from '@inertiajs/react'
import { FormEvent, useRef } from 'react'

import { FieldError, SelectField, TextField } from '@/components/ui/FormFields'
import { useDialogA11y } from '@/hooks/useDialogA11y'

export type MeetingFormOption = {
  id: number
  name: string
}

export type MeetingFormDefaults = {
  user_id: number | null
  force_host: boolean
}

export type MeetingFormValues = {
  title: string
  scheduled_on: string
  start_time: string
  lead_id: string
  user_id: string
  location: string
  virtual_link: string
  virtual_meeting: boolean
  status: string
  return_to: string
}

export type EditableMeeting = {
  id: number
  title: string
  scheduled_on: string | null
  start_time: string | null
  lead_id: number | null
  user_id?: number | null
  location?: string | null
  virtual_link?: string | null
  virtual_meeting?: boolean | null
  status: string | null
  can_revert?: boolean
}

type MeetingFormModalProps = {
  open: boolean
  onClose: () => void
  leads: MeetingFormOption[]
  hosts: MeetingFormOption[]
  defaults: MeetingFormDefaults
  returnTo: string
  lockedLeadId?: number | null
  meeting?: EditableMeeting | null
}

const STATUS_OPTIONS = [
  { value: 'scheduled', label: 'Scheduled' },
  { value: 'draft', label: 'Draft' },
  { value: 'completed', label: 'Completed' },
  { value: 'cancelled', label: 'Cancelled' },
] as const

function fieldError(errors: Record<string, string | string[] | undefined>, key: string): string | null {
  const value = errors[key]
  if (!value) return null
  return Array.isArray(value) ? value.join(', ') : value
}

function editableStatus(status: string | null | undefined): string {
  if (!status) return 'scheduled'
  return status
}

export default function MeetingFormModal({
  open,
  onClose,
  leads,
  hosts,
  defaults,
  returnTo,
  lockedLeadId = null,
  meeting = null,
}: MeetingFormModalProps) {
  const editing = meeting != null
  const initialLeadId =
    lockedLeadId != null
      ? String(lockedLeadId)
      : meeting?.lead_id != null
        ? String(meeting.lead_id)
        : leads[0]
          ? String(leads[0].id)
          : ''

  const form = useForm<MeetingFormValues>({
    title: meeting?.title ?? '',
    scheduled_on: meeting?.scheduled_on ?? '',
    start_time: meeting?.start_time ?? '',
    lead_id: initialLeadId,
    user_id:
      meeting?.user_id != null
        ? String(meeting.user_id)
        : defaults.user_id != null
          ? String(defaults.user_id)
          : '',
    location: meeting?.location ?? '',
    virtual_link: meeting?.virtual_link ?? '',
    virtual_meeting: Boolean(meeting?.virtual_meeting || meeting?.virtual_link),
    status: editableStatus(meeting?.status),
    return_to: returnTo,
  })
  const dialogRef = useRef<HTMLDivElement>(null)

  function resetForm() {
    form.setData({
      title: meeting?.title ?? '',
      scheduled_on: meeting?.scheduled_on ?? '',
      start_time: meeting?.start_time ?? '',
      lead_id: initialLeadId,
      user_id:
        meeting?.user_id != null
          ? String(meeting.user_id)
          : defaults.user_id != null
            ? String(defaults.user_id)
            : '',
      location: meeting?.location ?? '',
      virtual_link: meeting?.virtual_link ?? '',
      virtual_meeting: Boolean(meeting?.virtual_meeting || meeting?.virtual_link),
      status: editableStatus(meeting?.status),
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

  const terminalLocked =
    (meeting?.status === 'completed' || meeting?.status === 'cancelled') && !meeting.can_revert
  const statusOptions = terminalLocked
    ? STATUS_OPTIONS.filter((option) => option.value === meeting.status)
    : STATUS_OPTIONS

  function submit(event: FormEvent) {
    event.preventDefault()
    form.transform((data) => ({
      ...data,
      return_to: returnTo,
      lead_id: lockedLeadId != null ? String(lockedLeadId) : data.lead_id,
      virtual_meeting: data.virtual_meeting || data.virtual_link.trim().length > 0,
    }))

    if (editing && meeting) {
      form.patch(`/meetings/${meeting.id}`, {
        preserveScroll: true,
        onSuccess: () => {
          resetForm()
          onClose()
        },
      })
      return
    }

    form.post('/meetings', {
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
        aria-labelledby="meeting-form-title"
        className="w-full max-w-lg rounded-xl border border-slate-200 bg-white p-6 shadow-lg"
      >
        <div className="flex items-start justify-between gap-4">
          <div>
            <h2 id="meeting-form-title" className="text-lg font-semibold text-slate-900">
              {editing ? 'Edit meeting' : 'Schedule meeting'}
            </h2>
            <p className="mt-1 text-sm text-slate-600">
              {editing ? 'Update schedule details or status.' : 'Book time with a lead.'}
            </p>
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
            id="meeting-title"
            label="Title"
            required
            value={form.data.title}
            onChange={(value) => form.setData('title', value)}
            error={fieldError(form.errors, 'title')}
          />

          <div className="grid gap-4 sm:grid-cols-2">
            <TextField
              id="meeting-date"
              label="Date"
              type="date"
              required
              value={form.data.scheduled_on}
              onChange={(value) => form.setData('scheduled_on', value)}
              error={fieldError(form.errors, 'scheduled_on')}
            />
            <TextField
              id="meeting-time"
              label="Time"
              type="time"
              required
              value={form.data.start_time}
              onChange={(value) => form.setData('start_time', value)}
              error={fieldError(form.errors, 'start_time')}
            />
          </div>

          {lockedLeadId != null || editing ? (
            <div>
              <p className="block text-sm font-medium text-slate-700">
                Lead <span className="text-red-600">*</span>
              </p>
              <p className="mt-1 text-sm text-slate-900">
                {leads.find((lead) => lead.id === Number(form.data.lead_id))?.name || 'Selected lead'}
              </p>
              <FieldError error={fieldError(form.errors, 'lead_id') || fieldError(form.errors, 'lead')} />
            </div>
          ) : (
            <SelectField
              id="meeting-lead"
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

          {defaults.force_host ? (
            <div>
              <p className="block text-sm font-medium text-slate-700">
                Host <span className="text-red-600">*</span>
              </p>
              <p className="mt-1 text-sm text-slate-900">
                {hosts.find((user) => String(user.id) === form.data.user_id)?.name || 'You'}
              </p>
              <FieldError error={fieldError(form.errors, 'user_id') || fieldError(form.errors, 'user')} />
            </div>
          ) : (
            <SelectField
              id="meeting-host"
              label="Host"
              required
              value={form.data.user_id}
              onChange={(value) => form.setData('user_id', value)}
              error={fieldError(form.errors, 'user_id') || fieldError(form.errors, 'user')}
            >
              {hosts.map((user) => (
                <option key={user.id} value={user.id}>
                  {user.name}
                </option>
              ))}
            </SelectField>
          )}

          {editing && (
            <SelectField
              id="meeting-status"
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
          )}

          <TextField
            id="meeting-location"
            label="Location"
            value={form.data.location}
            onChange={(value) => form.setData('location', value)}
            error={fieldError(form.errors, 'location')}
            placeholder="Office / address"
          />

          <TextField
            id="meeting-virtual-link"
            label="Virtual link"
            type="url"
            value={form.data.virtual_link}
            onChange={(value) => {
              form.setData('virtual_link', value)
              if (value.trim()) form.setData('virtual_meeting', true)
            }}
            error={fieldError(form.errors, 'virtual_link')}
            placeholder="https://"
          />

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
              {form.processing
                ? editing
                  ? 'Saving…'
                  : 'Scheduling…'
                : editing
                  ? 'Save changes'
                  : 'Schedule meeting'}
            </button>
          </div>
        </form>
      </div>
    </div>
  )
}
