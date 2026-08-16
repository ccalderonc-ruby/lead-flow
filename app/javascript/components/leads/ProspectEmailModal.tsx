import { useForm } from '@inertiajs/react'
import { FormEvent, useRef } from 'react'

import { FieldError, TextAreaField, TextField } from '@/components/ui/FormFields'
import { useDialogA11y } from '@/hooks/useDialogA11y'

type ProspectEmailModalProps = {
  open: boolean
  onClose: () => void
  leadId: number
  leadName: string
  leadEmail: string
}

function fieldError(errors: Record<string, string | string[] | undefined>, key: string): string | null {
  const value = errors[key]
  if (!value) return null
  return Array.isArray(value) ? value.join(', ') : value
}

export default function ProspectEmailModal({
  open,
  onClose,
  leadId,
  leadName,
  leadEmail,
}: ProspectEmailModalProps) {
  const containerRef = useRef<HTMLDivElement>(null)
  useDialogA11y({ open, onClose, containerRef })

  const { data, setData, post, processing, errors, reset } = useForm({
    subject: '',
    body: '',
  })

  if (!open) return null

  function submit(event: FormEvent) {
    event.preventDefault()
    post(`/leads/${leadId}/emails`, {
      preserveScroll: true,
      onSuccess: () => {
        reset()
        onClose()
      },
    })
  }

  return (
    <div
      ref={containerRef}
      className="fixed inset-0 z-50 flex items-end justify-center bg-slate-900/40 p-4 sm:items-center"
    >
      <div
        role="dialog"
        aria-modal="true"
        aria-labelledby="prospect-email-title"
        className="flex max-h-[min(90dvh,90vh)] w-full max-w-lg flex-col overflow-hidden rounded-xl border border-slate-200 bg-panel shadow-xl"
      >
        <div className="flex items-start justify-between gap-3 border-b border-slate-100 px-5 py-4">
          <div>
            <h2 id="prospect-email-title" className="text-lg font-semibold text-slate-900">
              Email prospect
            </h2>
            <p className="mt-1 text-sm text-slate-600">
              To {leadName} &lt;{leadEmail}&gt;
            </p>
          </div>
          <button
            type="button"
            onClick={onClose}
            className="inline-flex min-h-11 min-w-11 items-center justify-center rounded-lg text-slate-500 hover:bg-slate-100 hover:text-slate-800"
            aria-label="Close"
          >
            ×
          </button>
        </div>

        <form onSubmit={submit} className="flex min-h-0 flex-1 flex-col">
          <div className="space-y-4 overflow-y-auto px-5 py-4">
            {fieldError(errors, 'base') && (
              <p className="rounded-lg border border-red-200 bg-red-50 px-3 py-2 text-sm text-red-700" role="alert">
                {fieldError(errors, 'base')}
              </p>
            )}

            <TextField
              id="prospect-email-subject"
              label="Subject"
              required
              value={data.subject}
              onChange={(value) => setData('subject', value)}
              error={fieldError(errors, 'subject')}
            />

            <TextAreaField
              id="prospect-email-body"
              label="Message"
              required
              rows={8}
              value={data.body}
              onChange={(value) => setData('body', value)}
              error={fieldError(errors, 'body')}
            />
            <FieldError error={fieldError(errors, 'form')} />
          </div>

          <div className="flex justify-end gap-2 border-t border-slate-100 px-5 py-4">
            <button
              type="button"
              onClick={onClose}
              className="inline-flex min-h-11 items-center rounded-lg border border-slate-300 px-4 py-2 text-sm font-medium text-slate-700 hover:bg-slate-50"
            >
              Cancel
            </button>
            <button
              type="submit"
              disabled={processing || !leadEmail}
              className="inline-flex min-h-11 items-center rounded-lg bg-brand px-4 py-2 text-sm font-medium text-white hover:bg-brand-hover disabled:cursor-not-allowed disabled:opacity-50"
            >
              {processing ? 'Sending…' : 'Send email'}
            </button>
          </div>
        </form>
      </div>
    </div>
  )
}
