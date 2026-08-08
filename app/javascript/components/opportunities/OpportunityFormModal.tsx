import { useForm } from '@inertiajs/react'
import { FormEvent, useRef } from 'react'

import { FieldError, SelectField, TextAreaField, TextField } from '@/components/ui/FormFields'
import { useDialogA11y } from '@/hooks/useDialogA11y'

export type OpportunityFormOption = {
  id: number
  name: string
}

export type OpportunityFormDefaults = {
  stage_id: number | null
}

export type OpportunityFormValues = {
  title: string
  value: string
  stage_id: string
  close_date: string
  description: string
  lead_id: string
  return_to: string
}

type OpportunityFormModalProps = {
  open: boolean
  onClose: () => void
  leads: OpportunityFormOption[]
  stages: OpportunityFormOption[]
  defaults: OpportunityFormDefaults
  returnTo: string
  lockedLeadId?: number | null
}

function fieldError(errors: Record<string, string | string[] | undefined>, key: string): string | null {
  const value = errors[key]
  if (!value) return null
  return Array.isArray(value) ? value.join(', ') : value
}

export default function OpportunityFormModal({
  open,
  onClose,
  leads,
  stages,
  defaults,
  returnTo,
  lockedLeadId = null,
}: OpportunityFormModalProps) {
  const initialLeadId =
    lockedLeadId != null
      ? String(lockedLeadId)
      : leads[0]
        ? String(leads[0].id)
        : ''

  const form = useForm<OpportunityFormValues>({
    title: '',
    value: '',
    stage_id: defaults.stage_id != null ? String(defaults.stage_id) : stages[0] ? String(stages[0].id) : '',
    close_date: '',
    description: '',
    lead_id: initialLeadId,
    return_to: returnTo,
  })
  const dialogRef = useRef<HTMLDivElement>(null)

  function resetForm() {
    form.setData({
      title: '',
      value: '',
      stage_id: defaults.stage_id != null ? String(defaults.stage_id) : stages[0] ? String(stages[0].id) : '',
      close_date: '',
      description: '',
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
      return_to: returnTo,
      lead_id: lockedLeadId != null ? String(lockedLeadId) : data.lead_id,
      value: data.value.trim(),
      close_date: data.close_date || '',
    }))
    form.post('/opportunities', {
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
        aria-labelledby="opportunity-form-title"
        className="w-full max-w-lg rounded-xl border border-slate-200 bg-white p-6 shadow-lg"
      >
        <div className="flex items-start justify-between gap-4">
          <div>
            <h2 id="opportunity-form-title" className="text-lg font-semibold text-slate-900">
              New opportunity
            </h2>
            <p className="mt-1 text-sm text-slate-600">Add a deal to the pipeline.</p>
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
            id="opportunity-title"
            label="Title"
            required
            value={form.data.title}
            onChange={(value) => form.setData('title', value)}
            error={fieldError(form.errors, 'title')}
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
              id="opportunity-lead"
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

          <SelectField
            id="opportunity-stage"
            label="Stage"
            required
            value={form.data.stage_id}
            onChange={(value) => form.setData('stage_id', value)}
            error={fieldError(form.errors, 'stage_id') || fieldError(form.errors, 'stage')}
          >
            <option value="">Select a stage</option>
            {stages.map((stage) => (
              <option key={stage.id} value={stage.id}>
                {stage.name}
              </option>
            ))}
          </SelectField>

          <div className="grid gap-4 sm:grid-cols-2">
            <TextField
              id="opportunity-value"
              label="Value"
              type="number"
              min="0"
              step="1"
              value={form.data.value}
              onChange={(value) => form.setData('value', value)}
              error={fieldError(form.errors, 'value')}
              placeholder="Optional"
            />
            <TextField
              id="opportunity-close-date"
              label="Close date"
              type="date"
              value={form.data.close_date}
              onChange={(value) => form.setData('close_date', value)}
              error={fieldError(form.errors, 'close_date')}
            />
          </div>

          <TextAreaField
            id="opportunity-description"
            label="Description"
            value={form.data.description}
            onChange={(value) => form.setData('description', value)}
            error={fieldError(form.errors, 'description')}
            rows={3}
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
              {form.processing ? 'Creating…' : 'Create opportunity'}
            </button>
          </div>
        </form>
      </div>
    </div>
  )
}
