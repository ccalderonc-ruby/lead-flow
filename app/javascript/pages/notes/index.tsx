import { Head, Link, router, usePage } from '@inertiajs/react'
import { useState } from 'react'

import AuthenticatedPage from '@/components/layouts/AuthenticatedPage'
import EmptyState from '@/components/ui/EmptyState'
import NoteFormModal, {
  type EditableNote,
  type NoteFormOption,
} from '@/components/notes/NoteFormModal'
import {
  hasNoteCreateErrors,
  hasNoteUpdateErrors,
  noteIdFromErrors,
} from '@/components/notes/noteFormErrors'
import { formatDateTime } from '@/lib/format'

export type NoteRow = {
  id: number
  content: string
  link_type: 'lead' | 'opportunity'
  lead: string | null
  lead_id: number | null
  opportunity: string | null
  opportunity_id: number | null
  author: string | null
  user_id?: number | null
  created_at: string | null
  updated_at?: string | null
  can_update: boolean
  can_destroy: boolean
}

export type NotesMeta = {
  page: number
  per_page: number
  total_count: number
  total_pages: number
}

type NotesIndexProps = {
  notes: NoteRow[]
  meta: NotesMeta
  can_create: boolean
  leads: NoteFormOption[]
  opportunities: NoteFormOption[]
  return_to: string
}

function buildNotesReturnTo(meta: NotesMeta): string {
  if (meta.page > 1) return `/notes?page=${meta.page}`
  return '/notes'
}

function previewContent(content: string, max = 160): string {
  const trimmed = content.trim()
  if (trimmed.length <= max) return trimmed
  return `${trimmed.slice(0, max).trimEnd()}…`
}

export default function NotesIndex({
  notes,
  meta,
  can_create: canCreate,
  leads = [],
  opportunities = [],
  return_to: returnTo,
}: NotesIndexProps) {
  const page = usePage()
  const pageErrors = page.props.errors as Record<string, unknown> | undefined
  const createErrorsPresent = hasNoteCreateErrors(pageErrors)
  const updateErrorsPresent = hasNoteUpdateErrors(pageErrors)
  const errorNoteId = noteIdFromErrors(pageErrors)
  const createErrorKey = createErrorsPresent ? JSON.stringify(pageErrors) : null
  const updateErrorKey = updateErrorsPresent ? JSON.stringify(pageErrors) : null

  const [manualOpen, setManualOpen] = useState(false)
  const [editingNote, setEditingNote] = useState<EditableNote | null>(null)
  const [dismissedCreateErrorKey, setDismissedCreateErrorKey] = useState<string | null>(null)
  const [dismissedUpdateErrorKey, setDismissedUpdateErrorKey] = useState<string | null>(null)
  const [deletingId, setDeletingId] = useState<number | null>(null)

  const updateErrorStillOpen = updateErrorKey != null && dismissedUpdateErrorKey !== updateErrorKey
  const createModalOpen =
    editingNote == null &&
    (manualOpen || (createErrorKey != null && dismissedCreateErrorKey !== createErrorKey))

  const editingFromError =
    updateErrorStillOpen && errorNoteId != null
      ? notes.find((note) => note.id === errorNoteId) ?? null
      : null

  const activeEdit =
    editingNote ??
    (editingFromError
      ? {
          id: editingFromError.id,
          content: editingFromError.content,
          lead_id: editingFromError.lead_id,
          opportunity_id: editingFromError.opportunity_id,
          link_type: editingFromError.link_type,
        }
      : null)

  function openCreateModal() {
    setEditingNote(null)
    setDismissedCreateErrorKey(null)
    setManualOpen(true)
  }

  function openEditModal(note: NoteRow) {
    setManualOpen(false)
    setDismissedUpdateErrorKey(null)
    setEditingNote({
      id: note.id,
      content: note.content,
      lead_id: note.lead_id,
      opportunity_id: note.opportunity_id,
      link_type: note.link_type,
    })
  }

  function closeModal() {
    setManualOpen(false)
    setEditingNote(null)
    if (createErrorKey != null) setDismissedCreateErrorKey(createErrorKey)
    if (updateErrorKey != null) setDismissedUpdateErrorKey(updateErrorKey)
  }

  const createReturnTo = buildNotesReturnTo(meta) || returnTo

  function goToPage(pageNumber: number) {
    router.get('/notes', { page: pageNumber }, { preserveState: true })
  }

  function deleteNote(note: NoteRow) {
    if (deletingId != null) return
    if (!window.confirm('Delete this note? This cannot be undone.')) return

    setDeletingId(note.id)
    router.delete(`/notes/${note.id}?return_to=${encodeURIComponent(createReturnTo)}`, {
      preserveScroll: true,
      onFinish: () => setDeletingId(null),
    })
  }

  return (
    <AuthenticatedPage>
      <Head title="Notes" />

      <div>
        <div className="flex flex-col gap-4 sm:flex-row sm:items-end sm:justify-between">
          <div>
            <h1 className="text-2xl font-semibold text-slate-900">Notes</h1>
            <p className="mt-1 text-slate-600">Details linked to leads or opportunities.</p>
          </div>

          {canCreate && (
            <button
              type="button"
              onClick={openCreateModal}
              className="inline-flex items-center justify-center rounded-lg bg-brand px-4 py-2 text-sm font-medium text-white hover:bg-brand-hover"
            >
              New note
            </button>
          )}
        </div>

        <div className="mt-8 overflow-x-auto rounded-xl border border-slate-200 bg-panel">
          <table className="min-w-full divide-y divide-slate-200 text-left text-sm">
            <thead className="bg-slate-50 text-xs font-semibold uppercase tracking-wide text-slate-500">
              <tr>
                <th className="px-4 py-3">Note</th>
                <th className="px-4 py-3">Linked to</th>
                <th className="px-4 py-3">Author</th>
                <th className="px-4 py-3">Created</th>
                <th className="px-4 py-3 text-right">Actions</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-100">
              {notes.length === 0 ? (
                <tr>
                  <td colSpan={5} className="p-0">
                    <EmptyState
                      title="No notes yet"
                      description="Capture details linked to a lead or opportunity."
                      action={
                        canCreate ? { label: 'New note', onClick: openCreateModal } : undefined
                      }
                    />
                  </td>
                </tr>
              ) : (
                notes.map((note) => (
                  <tr key={note.id} className="align-top">
                    <td className="max-w-md px-4 py-3 text-slate-900">
                      <div className="whitespace-pre-wrap">{previewContent(note.content)}</div>
                    </td>
                    <td className="px-4 py-3 text-slate-700">
                      {note.link_type === 'opportunity' ? (
                        <div>
                          <div className="text-xs font-medium uppercase tracking-wide text-slate-500">
                            Opportunity
                          </div>
                          {note.opportunity_id ? (
                            <Link
                              href={`/opportunities?opportunity_id=${note.opportunity_id}`}
                              className="mt-0.5 inline-block font-medium text-brand-ink hover:text-brand"
                            >
                              {note.opportunity || '—'}
                            </Link>
                          ) : (
                            <div className="mt-0.5 font-medium text-slate-900">
                              {note.opportunity || '—'}
                            </div>
                          )}
                        </div>
                      ) : note.lead_id ? (
                        <div>
                          <div className="text-xs font-medium uppercase tracking-wide text-slate-500">
                            Lead
                          </div>
                          <Link
                            href={`/leads/${note.lead_id}`}
                            className="mt-0.5 inline-block font-medium text-brand-ink hover:text-brand"
                          >
                            {note.lead || '—'}
                          </Link>
                        </div>
                      ) : (
                        '—'
                      )}
                    </td>
                    <td className="px-4 py-3 text-slate-700">{note.author || '—'}</td>
                    <td className="px-4 py-3 text-slate-700">{formatDateTime(note.created_at)}</td>
                    <td className="px-4 py-3 text-right">
                      <div className="flex justify-end gap-3">
                        {note.can_update && (
                          <button
                            type="button"
                            onClick={() => openEditModal(note)}
                            className="inline-flex min-h-11 items-center px-1 text-sm font-medium text-slate-700 hover:text-slate-900"
                          >
                            Edit
                          </button>
                        )}
                        {note.can_destroy && (
                          <button
                            type="button"
                            onClick={() => deleteNote(note)}
                            disabled={deletingId === note.id}
                            className="inline-flex min-h-11 items-center px-1 text-sm font-medium text-red-600 hover:text-red-500 disabled:opacity-50"
                          >
                            {deletingId === note.id ? 'Deleting…' : 'Delete'}
                          </button>
                        )}
                      </div>
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>

        {meta.total_pages > 1 && (
          <div className="mt-4 flex items-center justify-between text-sm text-slate-600">
            <p>
              Page {meta.page} of {meta.total_pages} · {meta.total_count} notes
            </p>
            <div className="flex gap-2">
              <button
                type="button"
                disabled={meta.page <= 1}
                onClick={() => goToPage(meta.page - 1)}
                className="inline-flex min-h-11 items-center rounded-lg border border-slate-300 px-3 py-2.5 font-medium text-slate-700 hover:bg-slate-50 disabled:cursor-not-allowed disabled:opacity-50"
              >
                Previous
              </button>
              <button
                type="button"
                disabled={meta.page >= meta.total_pages}
                onClick={() => goToPage(meta.page + 1)}
                className="inline-flex min-h-11 items-center rounded-lg border border-slate-300 px-3 py-2.5 font-medium text-slate-700 hover:bg-slate-50 disabled:cursor-not-allowed disabled:opacity-50"
              >
                Next
              </button>
            </div>
          </div>
        )}
      </div>

      {canCreate && (
        <NoteFormModal
          key="notes-create"
          open={createModalOpen}
          onClose={closeModal}
          leads={leads}
          opportunities={opportunities}
          returnTo={createReturnTo}
        />
      )}

      {activeEdit && (
        <NoteFormModal
          key={`notes-edit-${activeEdit.id}`}
          open
          onClose={closeModal}
          leads={leads}
          opportunities={opportunities}
          returnTo={createReturnTo}
          note={activeEdit}
        />
      )}
    </AuthenticatedPage>
  )
}
