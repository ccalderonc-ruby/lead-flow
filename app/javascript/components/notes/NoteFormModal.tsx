import { useForm } from '@inertiajs/react'
import { FormEvent, useRef } from 'react'

import { FieldError, SelectField, TextAreaField } from '@/components/ui/FormFields'
import { useDialogA11y } from '@/hooks/useDialogA11y'

export type NoteFormOption = {
  id: number
  name: string
  lead_name?: string | null
}

export type NoteFormValues = {
  content: string
  link_type: 'lead' | 'opportunity'
  lead_id: string
  opportunity_id: string
  return_to: string
}

export type EditableNote = {
  id: number
  content: string
  lead_id: number | null
  opportunity_id?: number | null
  link_type?: 'lead' | 'opportunity'
}

type NoteFormModalProps = {
  open: boolean
  onClose: () => void
  leads: NoteFormOption[]
  opportunities?: NoteFormOption[]
  returnTo: string
  lockedLeadId?: number | null
  lockedOpportunityId?: number | null
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
  opportunities = [],
  returnTo,
  lockedLeadId = null,
  lockedOpportunityId = null,
  note = null,
}: NoteFormModalProps) {
  const editing = note != null
  const lockedToOpportunity = lockedOpportunityId != null
  const lockedToLead = lockedLeadId != null && !lockedToOpportunity

  const initialLinkType: 'lead' | 'opportunity' =
    lockedToOpportunity || note?.link_type === 'opportunity' || note?.opportunity_id != null
      ? 'opportunity'
      : 'lead'

  const initialLeadId =
    lockedLeadId != null
      ? String(lockedLeadId)
      : note?.lead_id != null
        ? String(note.lead_id)
        : leads[0]
          ? String(leads[0].id)
          : ''

  const initialOpportunityId =
    lockedOpportunityId != null
      ? String(lockedOpportunityId)
      : note?.opportunity_id != null
        ? String(note.opportunity_id)
        : opportunities[0]
          ? String(opportunities[0].id)
          : ''

  const form = useForm<NoteFormValues>({
    content: note?.content ?? '',
    link_type: initialLinkType,
    lead_id: initialLeadId,
    opportunity_id: initialOpportunityId,
    return_to: returnTo,
  })
  const dialogRef = useRef<HTMLDivElement>(null)

  function resetForm() {
    form.setData({
      content: note?.content ?? '',
      link_type: initialLinkType,
      lead_id: initialLeadId,
      opportunity_id: initialOpportunityId,
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

  const showLinkPicker = !editing && !lockedToLead && !lockedToOpportunity
  const linkType = lockedToOpportunity ? 'opportunity' : lockedToLead ? 'lead' : form.data.link_type

  function submit(event: FormEvent) {
    event.preventDefault()
    form.transform((data) => {
      const resolvedType = lockedToOpportunity
        ? 'opportunity'
        : lockedToLead
          ? 'lead'
          : data.link_type

      return {
        content: data.content,
        link_type: resolvedType,
        lead_id: resolvedType === 'lead' ? (lockedLeadId != null ? String(lockedLeadId) : data.lead_id) : '',
        opportunity_id:
          resolvedType === 'opportunity'
            ? lockedOpportunityId != null
              ? String(lockedOpportunityId)
              : data.opportunity_id
            : '',
        return_to: returnTo,
      }
    })

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
                ? 'Update this note. The linked lead or opportunity stays the same.'
                : lockedToOpportunity
                  ? 'Capture a detail on this opportunity.'
                  : lockedToLead
                    ? 'Capture a conversation detail on this lead.'
                    : 'Link a note to a lead or an opportunity.'}
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

          {showLinkPicker && (
            <SelectField
              id="note-link-type"
              label="Linked to"
              required
              value={form.data.link_type}
              onChange={(value) =>
                form.setData('link_type', value === 'opportunity' ? 'opportunity' : 'lead')
              }
            >
              <option value="lead">Lead</option>
              <option value="opportunity">Opportunity</option>
            </SelectField>
          )}

          {showLinkPicker && linkType === 'lead' && (
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

          {showLinkPicker && linkType === 'opportunity' && (
            <SelectField
              id="note-opportunity"
              label="Opportunity"
              required
              value={form.data.opportunity_id}
              onChange={(value) => form.setData('opportunity_id', value)}
              error={
                fieldError(form.errors, 'opportunity_id') || fieldError(form.errors, 'opportunity')
              }
            >
              <option value="">Select an opportunity</option>
              {opportunities.map((opportunity) => (
                <option key={opportunity.id} value={opportunity.id}>
                  {opportunity.name}
                  {opportunity.lead_name ? ` · ${opportunity.lead_name}` : ''}
                </option>
              ))}
            </SelectField>
          )}

          {(editing || lockedToLead || lockedToOpportunity) && (
            <FieldError
              error={
                fieldError(form.errors, 'lead_id') ||
                fieldError(form.errors, 'lead') ||
                fieldError(form.errors, 'opportunity_id') ||
                fieldError(form.errors, 'opportunity')
              }
            />
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
