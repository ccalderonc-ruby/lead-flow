import { useForm } from '@inertiajs/react'
import { FormEvent } from 'react'
import { Link } from '@inertiajs/react'

import { SelectField, TextAreaField, TextField } from '@/components/ui/FormFields'

export type OpportunityStageOption = {
  id: number
  name: string
}

export type OpportunityDrawerRecord = {
  id: number
  title: string
  value: string | number | null
  lead: string | null
  lead_id: number | null
  stage_id: number
  close_date: string | null
  description: string | null
  can_update: boolean
}

type OpportunityDrawerProps = {
  open: boolean
  opportunity: OpportunityDrawerRecord | null
  stageOptions: OpportunityStageOption[]
  onClose: () => void
}

type OpportunityFormValues = {
  title: string
  value: string
  stage_id: string
  close_date: string
  description: string
}

function fieldError(errors: Record<string, string | string[] | undefined>, key: string): string | null {
  const value = errors[key]
  if (!value) return null
  return Array.isArray(value) ? value.join(', ') : value
}

function toFormValues(opportunity: OpportunityDrawerRecord): OpportunityFormValues {
  return {
    title: opportunity.title || '',
    value: opportunity.value != null ? String(opportunity.value) : '',
    stage_id: String(opportunity.stage_id),
    close_date: opportunity.close_date || '',
    description: opportunity.description || '',
  }
}

export default function OpportunityDrawer({
  open,
  opportunity,
  stageOptions,
  onClose,
}: OpportunityDrawerProps) {
  const form = useForm<OpportunityFormValues>(
    opportunity ? toFormValues(opportunity) : {
      title: '',
      value: '',
      stage_id: '',
      close_date: '',
      description: '',
    },
  )

  if (!open || !opportunity) return null

  const record = opportunity
  const readOnly = !record.can_update

  function handleClose() {
    if (form.processing) return
    form.clearErrors()
    onClose()
  }

  function submit(event: FormEvent) {
    event.preventDefault()
    if (readOnly) return

    form.transform((data) => ({
      ...data,
      value: data.value.trim() === '' ? '' : data.value,
      close_date: data.close_date || '',
    }))
    form.patch(`/opportunities/${record.id}`, {
      preserveScroll: true,
      onSuccess: () => {
        form.clearErrors()
        onClose()
      },
    })
  }

  // Sync form when opening a different card (no useEffect — key remounts from parent).
  return (
    <div className="fixed inset-0 z-50 flex justify-end bg-slate-900/40">
      <button
        type="button"
        className="flex-1 cursor-default"
        aria-label="Close drawer backdrop"
        onClick={handleClose}
        disabled={form.processing}
      />
      <aside
        role="dialog"
        aria-modal="true"
        aria-labelledby="opportunity-drawer-title"
        className="flex h-full w-full max-w-md flex-col border-l border-slate-200 bg-white shadow-xl"
      >
        <div className="flex items-start justify-between gap-4 border-b border-slate-100 px-5 py-4">
          <div>
            <h2 id="opportunity-drawer-title" className="text-lg font-semibold text-slate-900">
              Opportunity
            </h2>
            <p className="mt-1 text-sm text-slate-600">
              {readOnly ? 'View deal details.' : 'Update stage, value, and details.'}
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

        <form onSubmit={submit} className="flex flex-1 flex-col overflow-y-auto px-5 py-4">
          <div className="space-y-4">
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
              disabled={readOnly}
            />

            <TextField
              id="opportunity-value"
              label="Value"
              type="number"
              min="0.01"
              step="any"
              value={form.data.value}
              onChange={(value) => form.setData('value', value)}
              error={fieldError(form.errors, 'value')}
              disabled={readOnly}
            />

            <SelectField
              id="opportunity-stage"
              label="Stage"
              required
              value={form.data.stage_id}
              onChange={(value) => form.setData('stage_id', value)}
              error={fieldError(form.errors, 'stage_id') || fieldError(form.errors, 'stage')}
              disabled={readOnly}
            >
              {stageOptions.map((stage) => (
                <option key={stage.id} value={stage.id}>
                  {stage.name}
                </option>
              ))}
            </SelectField>

            <TextField
              id="opportunity-close-date"
              label="Close date"
              type="date"
              value={form.data.close_date}
              onChange={(value) => form.setData('close_date', value)}
              error={fieldError(form.errors, 'close_date')}
              disabled={readOnly}
            />

            <TextAreaField
              id="opportunity-description"
              label="Description"
              rows={5}
              value={form.data.description}
              onChange={(value) => form.setData('description', value)}
              error={fieldError(form.errors, 'description')}
              disabled={readOnly}
            />

            <div>
              <p className="block text-sm font-medium text-slate-700">Lead</p>
              <p className="mt-1 text-sm text-slate-900">
                {record.lead_id ? (
                  <Link
                    href={`/leads/${record.lead_id}`}
                    className="font-medium text-indigo-600 hover:text-indigo-500"
                  >
                    {record.lead || '—'}
                  </Link>
                ) : (
                  record.lead || '—'
                )}
              </p>
            </div>
          </div>

          <div className="mt-auto flex justify-end gap-2 border-t border-slate-100 pt-4">
            <button
              type="button"
              onClick={handleClose}
              disabled={form.processing}
              className="rounded-lg border border-slate-300 px-4 py-2 text-sm font-medium text-slate-700 hover:bg-slate-50 disabled:cursor-not-allowed disabled:opacity-50"
            >
              {readOnly ? 'Close' : 'Cancel'}
            </button>
            {!readOnly && (
              <button
                type="submit"
                disabled={form.processing}
                className="rounded-lg bg-indigo-600 px-4 py-2 text-sm font-medium text-white hover:bg-indigo-500 disabled:opacity-60"
              >
                {form.processing ? 'Saving…' : 'Save'}
              </button>
            )}
          </div>
        </form>
      </aside>
    </div>
  )
}
