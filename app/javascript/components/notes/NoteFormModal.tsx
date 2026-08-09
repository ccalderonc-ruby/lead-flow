import { useForm } from '@inertiajs/react'
import { FormEvent, useRef } from 'react'

import { FieldError, SelectField, TextAreaField } from '@/components/ui/FormFields'
import { useDialogA11y } from '@/hooks/useDialogA11y'

export type NoteFormOption = {
  id: number
  name: string
}

export type NoteFormValues = {
  content: string
  lead_id: string
  return_to: string
}

export type EditableNote = {
  id: number
  content: string
  lead_id: number | null
}

type NoteFormModalProps = {
  open: boolean
  onClose: () => void
  leads: NoteFormOption[]
  returnTo: string
  lockedLeadId?: number | null
  note?: EditableNote | null
}

function fieldError(errors: Record<string, string | string[] | undefined>, key: string): string | null {
  const value = errors[key]
  if (!value) return null
  return Array.isArray(value) ? value.join(', ') : value
}

export default function NoteFormModal({
  open,
  onClose,
  leads,
  returnTo,
  lockedLeadId = null,
  note = null,
}: NoteFormModalProps) {
  const editing = note != null
  const initialLeadId =
    lockedLeadId != null
      ? String(lockedLeadId)
      : note?.lead_id != null
        ? String(note.lead_id)
        : leads[0]
          ? String(leads[0].id)
          : ''

  const form = useForm<NoteFormValues>({
    content: note?.content ?? '',
    lead_id: initialLeadId,
    return_to: returnTo,
  })
  const dialogRef = useRef<HTMLDivElement>(null)

  function resetForm() {
    form.setData({
      content: note?.content ?? '',
      lead_id: initialLeadId,
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

  function submit(event: FormEvent) {
    event.preventDefault()
    form.transform((data) => ({
      ...data,
      lead_id: lockedLeadId != null ? String(lockedLeadId) : data.lead_id,
      return_to: returnTo,
    }))

    const options = {
      preserveScroll: true,
      onSuccess: () => {
        resetForm()
        onClose()
      },
    }

    if (editing && note) {
      form.patch(`/notes/${note.id}`, options)
    } else {
      form.post('/notes', options)
    }
  }

  return (
    <div ref={dialogRef} className="fixed inset-0 z-50 flex items-center justify-center bg-slate-900/40 p-4">
      <div
        role="dialog"
        aria-modal="true"
        aria-labelledby="note-form-title"
        className="w-full max-w-lg rounded-xl border border-slate-200 bg-white p-6 shadow-lg"
      >
        <div className="flex items-start justify-between gap-4">
          <div>
            <h2 id="note-form-title" className="text-lg font-semibold text-slate-900">
              {editing ? 'Edit note' : 'Add note'}
            </h2>
            <p className="mt-1 text-sm text-slate-600">
              {editing
                ? 'Update this note. It stays linked to the same lead.'
                : 'Capture a conversation detail on a lead.'}
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

          {!editing && lockedLeadId == null && (
            <SelectField
              id="note-lead"
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

          {(editing || lockedLeadId != null) && (
            <FieldError error={fieldError(form.errors, 'lead_id') || fieldError(form.errors, 'lead')} />
          )}

          <TextAreaField
            id="note-content"
            label="Note"
            required
            rows={5}
            value={form.data.content}
            onChange={(value) => form.setData('content', value)}
            error={fieldError(form.errors, 'content')}
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
              {form.processing ? 'Saving…' : editing ? 'Save changes' : 'Add note'}
            </button>
          </div>
        </form>
      </div>
    </div>
  )
}
