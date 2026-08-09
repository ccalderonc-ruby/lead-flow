import { router, useForm, usePage } from '@inertiajs/react'
import { FormEvent, useRef, useState } from 'react'
import { Link } from '@inertiajs/react'

import NoteFormModal, { type EditableNote } from '@/components/notes/NoteFormModal'
import {
  hasNoteCreateErrors,
  hasNoteUpdateErrors,
  noteIdFromErrors,
} from '@/components/notes/noteFormErrors'
import { SelectField, TextAreaField, TextField } from '@/components/ui/FormFields'
import { useDialogA11y } from '@/hooks/useDialogA11y'
import { formatDateTime } from '@/lib/format'

export type OpportunityStageOption = {
  id: number
  name: string
}

export type OpportunityNote = {
  id: number
  content: string
  author: string | null
  created_at: string | null
  can_update: boolean
  can_destroy: boolean
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
  can_create_note?: boolean
  notes?: OpportunityNote[]
}

type OpportunityDrawerProps = {
  open: boolean
  opportunity: OpportunityDrawerRecord | null
  stageOptions: OpportunityStageOption[]
  returnTo?: string
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
  returnTo = '/opportunities',
  onClose,
}: OpportunityDrawerProps) {
  const page = usePage()
  const pageErrors = page.props.errors as Record<string, unknown> | undefined
  const noteCreateErrors = hasNoteCreateErrors(pageErrors)
  const noteUpdateErrors = hasNoteUpdateErrors(pageErrors)
  const errorNoteId = noteIdFromErrors(pageErrors)
  const noteCreateErrorKey = noteCreateErrors ? JSON.stringify(pageErrors) : null
  const noteUpdateErrorKey = noteUpdateErrors ? JSON.stringify(pageErrors) : null

  const form = useForm<OpportunityFormValues>(
    opportunity
      ? toFormValues(opportunity)
      : {
          title: '',
          value: '',
          stage_id: '',
          close_date: '',
          description: '',
        },
  )
  const dialogRef = useRef<HTMLDivElement>(null)
  const [noteManualOpen, setNoteManualOpen] = useState(false)
  const [editingNote, setEditingNote] = useState<EditableNote | null>(null)
  const [dismissedNoteCreateErrorKey, setDismissedNoteCreateErrorKey] = useState<string | null>(null)
  const [dismissedNoteUpdateErrorKey, setDismissedNoteUpdateErrorKey] = useState<string | null>(null)
  const [deletingNoteId, setDeletingNoteId] = useState<number | null>(null)

  function handleClose() {
    if (form.processing) return
    form.clearErrors()
    setNoteManualOpen(false)
    setEditingNote(null)
    onClose()
  }

  useDialogA11y({
    open: open && opportunity != null,
    onClose: handleClose,
    containerRef: dialogRef,
  })

  if (!open || !opportunity) return null

  const record = opportunity
  const readOnly = !record.can_update
  const notes = record.notes ?? []
  const canCreateNote = record.can_create_note === true

  const noteCreateModalOpen =
    editingNote == null &&
    (noteManualOpen ||
      (noteCreateErrorKey != null && dismissedNoteCreateErrorKey !== noteCreateErrorKey))
  const noteUpdateErrorStillOpen =
    noteUpdateErrorKey != null && dismissedNoteUpdateErrorKey !== noteUpdateErrorKey
  const editingNoteFromError =
    noteUpdateErrorStillOpen && errorNoteId != null
      ? notes.find((note) => note.id === errorNoteId) ?? null
      : null
  const activeEditNote =
    editingNote ??
    (editingNoteFromError
      ? {
          id: editingNoteFromError.id,
          content: editingNoteFromError.content,
          lead_id: null,
          opportunity_id: record.id,
          link_type: 'opportunity' as const,
        }
      : null)

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

  function openNoteModal() {
    setEditingNote(null)
    setDismissedNoteCreateErrorKey(null)
    setNoteManualOpen(true)
  }

  function openEditNoteModal(note: OpportunityNote) {
    setNoteManualOpen(false)
    setDismissedNoteUpdateErrorKey(null)
    setEditingNote({
      id: note.id,
      content: note.content,
      lead_id: null,
      opportunity_id: record.id,
      link_type: 'opportunity',
    })
  }

  function closeNoteModal() {
    setNoteManualOpen(false)
    setEditingNote(null)
    if (noteCreateErrorKey != null) setDismissedNoteCreateErrorKey(noteCreateErrorKey)
    if (noteUpdateErrorKey != null) setDismissedNoteUpdateErrorKey(noteUpdateErrorKey)
  }

  function deleteNote(note: OpportunityNote) {
    if (deletingNoteId != null) return
    if (!window.confirm('Delete this note? This cannot be undone.')) return

    setDeletingNoteId(note.id)
    router.delete(`/notes/${note.id}?return_to=${encodeURIComponent(returnTo)}`, {
      preserveScroll: true,
      onFinish: () => setDeletingNoteId(null),
    })
  }

  return (
    <div ref={dialogRef} className="fixed inset-0 z-50 flex justify-end bg-slate-900/40">
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

        <div className="flex flex-1 flex-col overflow-y-auto px-5 py-4">
          <form onSubmit={submit} className="space-y-4">
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

            <div className="flex justify-end gap-2 border-t border-slate-100 pt-4">
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

          <section className="mt-6 border-t border-slate-100 pt-4">
            <div className="flex items-center justify-between gap-3">
              <h3 className="text-sm font-semibold text-slate-900">Notes</h3>
              {canCreateNote && (
                <button
                  type="button"
                  onClick={openNoteModal}
                  className="text-sm font-medium text-indigo-600 hover:text-indigo-500"
                >
                  Add note
                </button>
              )}
            </div>

            {notes.length === 0 ? (
              <p className="mt-3 text-sm text-slate-500">No opportunity notes yet.</p>
            ) : (
              <ul className="mt-3 divide-y divide-slate-100 rounded-lg border border-slate-200">
                {notes.map((note) => (
                  <li key={note.id} className="flex items-start justify-between gap-3 px-3 py-3">
                    <div className="min-w-0">
                      <div className="whitespace-pre-wrap text-sm text-slate-900">{note.content}</div>
                      <div className="mt-1 text-xs text-slate-500">
                        {note.author || '—'} · {formatDateTime(note.created_at)}
                      </div>
                    </div>
                    {(note.can_update || note.can_destroy) && (
                      <div className="flex shrink-0 gap-3">
                        {note.can_update && (
                          <button
                            type="button"
                            onClick={() => openEditNoteModal(note)}
                            className="text-sm font-medium text-slate-700 hover:text-slate-900"
                          >
                            Edit
                          </button>
                        )}
                        {note.can_destroy && (
                          <button
                            type="button"
                            onClick={() => deleteNote(note)}
                            disabled={deletingNoteId === note.id}
                            className="text-sm font-medium text-red-600 hover:text-red-500 disabled:opacity-50"
                          >
                            {deletingNoteId === note.id ? 'Deleting…' : 'Delete'}
                          </button>
                        )}
                      </div>
                    )}
                  </li>
                ))}
              </ul>
            )}
          </section>
        </div>
      </aside>

      {canCreateNote && (
        <NoteFormModal
          key={`opp-note-create-${record.id}`}
          open={noteCreateModalOpen}
          onClose={closeNoteModal}
          leads={[]}
          opportunities={[{ id: record.id, name: record.title || 'Untitled' }]}
          returnTo={returnTo}
          lockedOpportunityId={record.id}
        />
      )}

      {activeEditNote && (
        <NoteFormModal
          key={`opp-note-edit-${activeEditNote.id}`}
          open
          onClose={closeNoteModal}
          leads={[]}
          opportunities={[{ id: record.id, name: record.title || 'Untitled' }]}
          returnTo={returnTo}
          lockedOpportunityId={record.id}
          note={activeEditNote}
        />
      )}
    </div>
  )
}
