import { useForm } from '@inertiajs/react'
import { FormEvent } from 'react'

import { FieldError, TextAreaField } from '@/components/ui/FormFields'

export type NoteFormValues = {
  content: string
  lead_id: string
  return_to: string
}

type NoteFormModalProps = {
  open: boolean
  onClose: () => void
  leadId: number
  returnTo: string
}

function fieldError(errors: Record<string, string | string[] | undefined>, key: string): string | null {
  const value = errors[key]
  if (!value) return null
  return Array.isArray(value) ? value.join(', ') : value
}

export default function NoteFormModal({ open, onClose, leadId, returnTo }: NoteFormModalProps) {
  const form = useForm<NoteFormValues>({
    content: '',
    lead_id: String(leadId),
    return_to: returnTo,
  })

  if (!open) return null

  function resetForm() {
    form.setData({
      content: '',
      lead_id: String(leadId),
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
      lead_id: String(leadId),
      return_to: returnTo,
    }))
    form.post('/notes', {
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
        aria-labelledby="new-note-title"
        className="w-full max-w-lg rounded-xl border border-slate-200 bg-white p-6 shadow-lg"
      >
        <div className="flex items-start justify-between gap-4">
          <div>
            <h2 id="new-note-title" className="text-lg font-semibold text-slate-900">
              Add note
            </h2>
            <p className="mt-1 text-sm text-slate-600">Capture a conversation detail on this lead.</p>
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

          <TextAreaField
            id="note-content"
            label="Note"
            required
            rows={5}
            value={form.data.content}
            onChange={(value) => form.setData('content', value)}
            error={fieldError(form.errors, 'content')}
          />

          <FieldError error={fieldError(form.errors, 'lead_id')} />

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
              {form.processing ? 'Saving…' : 'Add note'}
            </button>
          </div>
        </form>
      </div>
    </div>
  )
}
