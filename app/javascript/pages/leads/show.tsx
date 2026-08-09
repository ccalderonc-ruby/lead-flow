import { Head, Link, router, usePage } from '@inertiajs/react'
import { useState, type ReactNode } from 'react'

import AuthenticatedPage from '@/components/layouts/AuthenticatedPage'
import MeetingFormModal, {
  type EditableMeeting,
  type MeetingFormDefaults,
  type MeetingFormOption,
} from '@/components/meetings/MeetingFormModal'
import { hasMeetingCreateErrors } from '@/components/meetings/meetingFormErrors'
import NoteFormModal, { type EditableNote, type NoteFormOption } from '@/components/notes/NoteFormModal'
import {
  hasNoteCreateErrors,
  hasNoteUpdateErrors,
  noteIdFromErrors,
} from '@/components/notes/noteFormErrors'
import OpportunityFormModal, {
  type OpportunityFormDefaults,
  type OpportunityFormOption,
} from '@/components/opportunities/OpportunityFormModal'
import { hasOpportunityCreateErrors } from '@/components/opportunities/opportunityFormErrors'
import TaskFormModal, {
  type EditableTask,
  type TaskFormDefaults,
  type TaskFormOption,
} from '@/components/tasks/TaskFormModal'
import { hasTaskCreateErrors } from '@/components/tasks/taskFormErrors'
import { formatCurrency, formatDate, formatDateTime, isPastDueDate } from '@/lib/format'

type LeadDetail = {
  id: number
  name: string
  email: string
  phone: string | null
  estimated_value: string | number | null
  last_activity_at: string | null
  company: string | null
  country: string | null
  stage: string | null
  advisor: string | null
  can_update: boolean
}

type TaskPreview = {
  id: number
  title: string
  description?: string | null
  due_date: string | null
  status: string | null
  past_due?: boolean
  completed_at?: string | null
  user_id?: number | null
  can_edit: boolean
  can_revert: boolean
}

function formatTaskStatus(status: string | null): string {
  if (!status) return '—'
  if (status === 'in_progress') return 'In progress'
  return status.charAt(0).toUpperCase() + status.slice(1)
}

function taskIsPastDue(task: Pick<TaskPreview, 'due_date' | 'status'>): boolean {
  return task.status !== 'completed' && isPastDueDate(task.due_date)
}

type MeetingPreview = {
  id: number
  title: string
  scheduled_on: string | null
  start_time?: string | null
  location?: string | null
  virtual_link?: string | null
  virtual_meeting?: boolean | null
  status: string | null
  user_id?: number | null
  can_edit: boolean
  can_revert: boolean
}

type NotePreview = {
  id: number
  content: string
  author: string | null
  created_at: string | null
  can_update: boolean
  can_destroy: boolean
}

type OpportunityPreview = {
  id: number
  title: string
  value: string | number | null
  stage: string | null
}

type RelatedSection<T> = {
  count: number
  items: T[]
}

type NotesSection = RelatedSection<NotePreview> & {
  showing: number
  truncated: boolean
}

type TaskFormProps = {
  leads: TaskFormOption[]
  assignees: TaskFormOption[]
  defaults: TaskFormDefaults
  return_to: string
}

type MeetingFormProps = {
  leads: MeetingFormOption[]
  hosts: MeetingFormOption[]
  defaults: MeetingFormDefaults
  return_to: string
}

type NoteFormProps = {
  lead_id: number
  leads?: NoteFormOption[]
  return_to: string
}

type OpportunityFormProps = {
  leads: OpportunityFormOption[]
  stages: OpportunityFormOption[]
  defaults: OpportunityFormDefaults
  return_to: string
}

type LeadsShowProps = {
  lead: LeadDetail
  tasks: RelatedSection<TaskPreview>
  meetings: RelatedSection<MeetingPreview>
  notes: NotesSection
  opportunities: RelatedSection<OpportunityPreview>
  can_create_task: boolean
  task_form: TaskFormProps
  can_create_meeting: boolean
  meeting_form: MeetingFormProps
  can_create_note: boolean
  note_form: NoteFormProps
  can_create_opportunity: boolean
  opportunity_form: OpportunityFormProps
}

function Field({ label, value }: { label: string; value: string }) {
  return (
    <div>
      <dt className="text-xs font-semibold uppercase tracking-wide text-slate-500">{label}</dt>
      <dd className="mt-1 text-sm text-slate-900">{value}</dd>
    </div>
  )
}

function Section({
  title,
  count,
  empty,
  action,
  footer,
  children,
}: {
  title: string
  count: number
  empty: string
  action?: ReactNode
  footer?: ReactNode
  children: ReactNode
}) {
  return (
    <section className="rounded-xl border border-slate-200 bg-white">
      <div className="flex items-center justify-between gap-3 border-b border-slate-100 px-4 py-3">
        <div className="flex items-center gap-2">
          <h2 className="text-sm font-semibold text-slate-900">{title}</h2>
          <span className="rounded-full bg-slate-100 px-2.5 py-0.5 text-xs font-medium text-slate-600">
            {count}
          </span>
        </div>
        {action}
      </div>
      {count === 0 ? (
        <p className="px-4 py-6 text-sm text-slate-500">{empty}</p>
      ) : (
        <>
          <ul className="divide-y divide-slate-100">{children}</ul>
          {footer}
        </>
      )}
    </section>
  )
}

export default function LeadsShow({
  lead,
  tasks,
  meetings,
  notes,
  opportunities,
  can_create_task: canCreateTask,
  task_form: taskForm,
  can_create_meeting: canCreateMeeting,
  meeting_form: meetingForm,
  can_create_note: canCreateNote,
  note_form: noteForm,
  can_create_opportunity: canCreateOpportunity,
  opportunity_form: opportunityForm,
}: LeadsShowProps) {
  const page = usePage()
  const pageErrors = page.props.errors as Record<string, unknown> | undefined
  const opportunityErrorsPresent = hasOpportunityCreateErrors(pageErrors)
  const meetingErrorsPresent = hasMeetingCreateErrors(pageErrors) && !opportunityErrorsPresent
  const noteUpdateErrorsPresent = hasNoteUpdateErrors(pageErrors)
  const noteCreateErrorsPresent =
    hasNoteCreateErrors(pageErrors) &&
    !meetingErrorsPresent &&
    !opportunityErrorsPresent &&
    !noteUpdateErrorsPresent
  // Opportunity/meeting markers win shared keys; note wins over task for remaining shared errors.
  const taskErrorsPresent =
    hasTaskCreateErrors(pageErrors) &&
    !noteCreateErrorsPresent &&
    !noteUpdateErrorsPresent &&
    !meetingErrorsPresent &&
    !opportunityErrorsPresent
  const taskErrorKey = taskErrorsPresent ? JSON.stringify(pageErrors) : null
  const noteCreateErrorKey = noteCreateErrorsPresent ? JSON.stringify(pageErrors) : null
  const noteUpdateErrorKey = noteUpdateErrorsPresent ? JSON.stringify(pageErrors) : null
  const meetingErrorKey = meetingErrorsPresent ? JSON.stringify(pageErrors) : null
  const errorNoteId = noteIdFromErrors(pageErrors)
  const opportunityErrorKey = opportunityErrorsPresent ? JSON.stringify(pageErrors) : null
  const [taskManualOpen, setTaskManualOpen] = useState(false)
  const [editingTask, setEditingTask] = useState<EditableTask | null>(null)
  const [noteManualOpen, setNoteManualOpen] = useState(false)
  const [editingNote, setEditingNote] = useState<EditableNote | null>(null)
  const [meetingManualOpen, setMeetingManualOpen] = useState(false)
  const [editingMeeting, setEditingMeeting] = useState<EditableMeeting | null>(null)
  const [opportunityManualOpen, setOpportunityManualOpen] = useState(false)
  const [dismissedTaskErrorKey, setDismissedTaskErrorKey] = useState<string | null>(null)
  const [dismissedNoteCreateErrorKey, setDismissedNoteCreateErrorKey] = useState<string | null>(null)
  const [dismissedNoteUpdateErrorKey, setDismissedNoteUpdateErrorKey] = useState<string | null>(null)
  const [dismissedMeetingErrorKey, setDismissedMeetingErrorKey] = useState<string | null>(null)
  const [dismissedOpportunityErrorKey, setDismissedOpportunityErrorKey] = useState<string | null>(null)
  const [revertingId, setRevertingId] = useState<number | null>(null)
  const [deletingNoteId, setDeletingNoteId] = useState<number | null>(null)

  const taskModalOpen =
    editingTask == null &&
    (taskManualOpen || (taskErrorKey != null && dismissedTaskErrorKey !== taskErrorKey))
  const noteCreateModalOpen =
    editingNote == null &&
    (noteManualOpen ||
      (noteCreateErrorKey != null && dismissedNoteCreateErrorKey !== noteCreateErrorKey))
  const noteUpdateErrorStillOpen =
    noteUpdateErrorKey != null && dismissedNoteUpdateErrorKey !== noteUpdateErrorKey
  const editingNoteFromError =
    noteUpdateErrorStillOpen && errorNoteId != null
      ? notes.items.find((note) => note.id === errorNoteId) ?? null
      : null
  const activeEditNote =
    editingNote ??
    (editingNoteFromError
      ? {
          id: editingNoteFromError.id,
          content: editingNoteFromError.content,
          lead_id: lead.id,
        }
      : null)
  const meetingModalOpen =
    editingMeeting == null &&
    (meetingManualOpen || (meetingErrorKey != null && dismissedMeetingErrorKey !== meetingErrorKey))
  const opportunityModalOpen =
    opportunityManualOpen ||
    (opportunityErrorKey != null && dismissedOpportunityErrorKey !== opportunityErrorKey)

  function openTaskModal() {
    setEditingTask(null)
    setDismissedTaskErrorKey(null)
    setTaskManualOpen(true)
  }

  function openEditTaskModal(task: TaskPreview) {
    setTaskManualOpen(false)
    setEditingTask({
      id: task.id,
      title: task.title,
      description: task.description,
      due_date: task.due_date,
      lead_id: lead.id,
      user_id: task.user_id,
      status: task.status,
      can_revert: task.can_revert,
    })
  }

  function closeTaskModal() {
    setTaskManualOpen(false)
    setEditingTask(null)
    if (taskErrorKey != null) setDismissedTaskErrorKey(taskErrorKey)
  }

  function openNoteModal() {
    setEditingNote(null)
    setDismissedNoteCreateErrorKey(null)
    setNoteManualOpen(true)
  }

  function openEditNoteModal(note: NotePreview) {
    setNoteManualOpen(false)
    setDismissedNoteUpdateErrorKey(null)
    setEditingNote({
      id: note.id,
      content: note.content,
      lead_id: lead.id,
    })
  }

  function closeNoteModal() {
    setNoteManualOpen(false)
    setEditingNote(null)
    if (noteCreateErrorKey != null) setDismissedNoteCreateErrorKey(noteCreateErrorKey)
    if (noteUpdateErrorKey != null) setDismissedNoteUpdateErrorKey(noteUpdateErrorKey)
  }

  function deleteNote(note: NotePreview) {
    if (deletingNoteId != null) return
    if (!window.confirm('Delete this note? This cannot be undone.')) return

    setDeletingNoteId(note.id)
    router.delete(`/notes/${note.id}?return_to=${encodeURIComponent(noteForm.return_to)}`, {
      preserveScroll: true,
      onFinish: () => setDeletingNoteId(null),
    })
  }

  function openMeetingModal() {
    setEditingMeeting(null)
    setDismissedMeetingErrorKey(null)
    setMeetingManualOpen(true)
  }

  function openEditMeetingModal(meeting: MeetingPreview) {
    setMeetingManualOpen(false)
    setEditingMeeting({
      id: meeting.id,
      title: meeting.title,
      scheduled_on: meeting.scheduled_on,
      start_time: meeting.start_time ?? null,
      lead_id: lead.id,
      user_id: meeting.user_id ?? null,
      location: meeting.location ?? null,
      virtual_link: meeting.virtual_link ?? null,
      virtual_meeting: meeting.virtual_meeting ?? null,
      status: meeting.status,
      can_revert: meeting.can_revert,
    })
  }

  function closeMeetingModal() {
    setMeetingManualOpen(false)
    setEditingMeeting(null)
    if (meetingErrorKey != null) setDismissedMeetingErrorKey(meetingErrorKey)
  }

  function openOpportunityModal() {
    setDismissedOpportunityErrorKey(null)
    setOpportunityManualOpen(true)
  }

  function closeOpportunityModal() {
    setOpportunityManualOpen(false)
    if (opportunityErrorKey != null) setDismissedOpportunityErrorKey(opportunityErrorKey)
  }

  function revertTask(task: TaskPreview) {
    if (revertingId != null) return

    setRevertingId(task.id)
    router.patch(
      `/tasks/${task.id}`,
      {
        title: task.title,
        description: task.description ?? '',
        due_date: task.due_date,
        status: 'pending',
        return_to: taskForm.return_to,
      },
      {
        preserveScroll: true,
        onFinish: () => setRevertingId(null),
      },
    )
  }

  return (
    <AuthenticatedPage>
      <Head title={lead.name} />

      <div className="mx-auto max-w-5xl">
        <div className="flex flex-col gap-4 sm:flex-row sm:items-start sm:justify-between">
          <div>
            <h1 className="text-2xl font-semibold text-slate-900">{lead.name}</h1>
            <p className="mt-1 text-slate-600">Lead detail and related activity.</p>
          </div>
          <div className="flex items-center gap-3">
            <Link href="/leads" className="text-sm font-medium text-indigo-600 hover:text-indigo-500">
              Back to leads
            </Link>
            {lead.can_update && (
              <Link
                href={`/leads/${lead.id}/edit`}
                className="inline-flex items-center justify-center rounded-lg bg-indigo-600 px-4 py-2 text-sm font-medium text-white hover:bg-indigo-500"
              >
                Edit
              </Link>
            )}
          </div>
        </div>

        <dl className="mt-8 grid gap-4 rounded-xl border border-slate-200 bg-white p-4 sm:grid-cols-2 lg:grid-cols-3">
          <Field label="Email" value={lead.email || '—'} />
          <Field label="Phone" value={lead.phone || '—'} />
          <Field label="Company" value={lead.company || '—'} />
          <Field label="Country" value={lead.country || '—'} />
          <Field label="Stage" value={lead.stage || '—'} />
          <Field label="Advisor" value={lead.advisor || '—'} />
          <Field label="Estimated value" value={formatCurrency(lead.estimated_value)} />
          <Field label="Last activity" value={formatDate(lead.last_activity_at)} />
        </dl>

        <div className="mt-8 grid gap-4 lg:grid-cols-2">
          <Section
            title="Tasks"
            count={tasks.count}
            empty="No tasks yet."
            action={
              canCreateTask ? (
                <button
                  type="button"
                  onClick={openTaskModal}
                  className="text-sm font-medium text-indigo-600 hover:text-indigo-500"
                >
                  New task
                </button>
              ) : null
            }
          >
            {tasks.items.map((task) => (
              <li key={task.id} className="flex items-start justify-between gap-3 px-4 py-3">
                <div>
                  <div className="font-medium text-slate-900">{task.title}</div>
                  <div className="mt-1 text-xs text-slate-500">
                    Due{' '}
                    <span className={taskIsPastDue(task) ? 'font-medium text-red-600' : undefined}>
                      {formatDate(task.due_date)}
                    </span>{' '}
                    · {formatTaskStatus(task.status)}
                    {task.status === 'completed' && task.completed_at
                      ? ` · Completed ${formatDateTime(task.completed_at)}`
                      : null}
                  </div>
                </div>
                <div className="flex shrink-0 flex-col items-end gap-1 sm:flex-row sm:items-center sm:gap-3">
                  {task.can_edit && (
                    <button
                      type="button"
                      onClick={() => openEditTaskModal(task)}
                      className="text-sm font-medium text-slate-700 hover:text-slate-900"
                    >
                      Edit
                    </button>
                  )}
                  {task.can_revert && (
                    <button
                      type="button"
                      disabled={revertingId != null}
                      onClick={() => revertTask(task)}
                      className="text-sm font-medium text-amber-700 hover:text-amber-600 disabled:cursor-not-allowed disabled:opacity-50"
                    >
                      {revertingId === task.id ? 'Reopening…' : 'Reopen'}
                    </button>
                  )}
                </div>
              </li>
            ))}
          </Section>

          <Section
            title="Meetings"
            count={meetings.count}
            empty="No meetings yet."
            action={
              canCreateMeeting ? (
                <button
                  type="button"
                  onClick={openMeetingModal}
                  className="text-sm font-medium text-indigo-600 hover:text-indigo-500"
                >
                  Schedule meeting
                </button>
              ) : null
            }
          >
            {meetings.items.map((meeting) => (
              <li key={meeting.id} className="flex items-start justify-between gap-3 px-4 py-3">
                <div>
                  <div className="font-medium text-slate-900">{meeting.title}</div>
                  <div className="mt-1 text-xs text-slate-500">
                    {formatDate(meeting.scheduled_on)}
                    {meeting.start_time ? ` · ${meeting.start_time}` : ''} · {meeting.status || '—'}
                  </div>
                </div>
                {meeting.can_edit && (
                  <button
                    type="button"
                    onClick={() => openEditMeetingModal(meeting)}
                    className="shrink-0 text-sm font-medium text-slate-700 hover:text-slate-900"
                  >
                    Edit
                  </button>
                )}
              </li>
            ))}
          </Section>

          <Section
            title="Notes"
            count={notes.count}
            empty="No notes yet."
            action={
              canCreateNote ? (
                <button
                  type="button"
                  onClick={openNoteModal}
                  className="text-sm font-medium text-indigo-600 hover:text-indigo-500"
                >
                  Add note
                </button>
              ) : null
            }
            footer={
              notes.truncated ? (
                <p className="border-t border-slate-100 px-4 py-2 text-xs text-slate-500">
                  Showing {notes.showing} of {notes.count} notes
                </p>
              ) : null
            }
          >
            {notes.items.map((note) => (
              <li key={note.id} className="flex items-start justify-between gap-3 px-4 py-3">
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
          </Section>

          <Section
            title="Opportunities"
            count={opportunities.count}
            empty="No opportunities yet."
            action={
              canCreateOpportunity ? (
                <button
                  type="button"
                  onClick={openOpportunityModal}
                  className="text-sm font-medium text-indigo-600 hover:text-indigo-500"
                >
                  New opportunity
                </button>
              ) : null
            }
          >
            {opportunities.items.map((opportunity) => (
              <li key={opportunity.id} className="px-4 py-3">
                <div className="font-medium text-slate-900">{opportunity.title}</div>
                <div className="mt-1 text-xs text-slate-500">
                  {formatCurrency(opportunity.value)} · {opportunity.stage || '—'}
                </div>
              </li>
            ))}
          </Section>
        </div>
      </div>

      {canCreateTask && (
        <TaskFormModal
          key="lead-task-create"
          open={taskModalOpen}
          onClose={closeTaskModal}
          leads={taskForm.leads}
          assignees={taskForm.assignees}
          defaults={taskForm.defaults}
          returnTo={taskForm.return_to}
          lockedLeadId={lead.id}
        />
      )}

      {editingTask && (
        <TaskFormModal
          key={`lead-task-edit-${editingTask.id}`}
          open
          onClose={closeTaskModal}
          leads={taskForm.leads}
          assignees={taskForm.assignees}
          defaults={taskForm.defaults}
          returnTo={taskForm.return_to}
          lockedLeadId={lead.id}
          task={editingTask}
        />
      )}

      {canCreateMeeting && (
        <MeetingFormModal
          key="lead-meeting-create"
          open={meetingModalOpen}
          onClose={closeMeetingModal}
          leads={meetingForm.leads}
          hosts={meetingForm.hosts}
          defaults={meetingForm.defaults}
          returnTo={meetingForm.return_to}
          lockedLeadId={lead.id}
        />
      )}

      {editingMeeting && (
        <MeetingFormModal
          key={`lead-meeting-edit-${editingMeeting.id}`}
          open
          onClose={closeMeetingModal}
          leads={meetingForm.leads}
          hosts={meetingForm.hosts}
          defaults={meetingForm.defaults}
          returnTo={meetingForm.return_to}
          lockedLeadId={lead.id}
          meeting={editingMeeting}
        />
      )}

      {canCreateNote && (
        <NoteFormModal
          key="lead-note-create"
          open={noteCreateModalOpen}
          onClose={closeNoteModal}
          leads={noteForm.leads ?? [{ id: noteForm.lead_id, name: lead.name }]}
          returnTo={noteForm.return_to}
          lockedLeadId={lead.id}
        />
      )}

      {activeEditNote && (
        <NoteFormModal
          key={`lead-note-edit-${activeEditNote.id}`}
          open
          onClose={closeNoteModal}
          leads={noteForm.leads ?? [{ id: noteForm.lead_id, name: lead.name }]}
          returnTo={noteForm.return_to}
          lockedLeadId={lead.id}
          note={activeEditNote}
        />
      )}

      {canCreateOpportunity && (
        <OpportunityFormModal
          key="lead-opportunity-create"
          open={opportunityModalOpen}
          onClose={closeOpportunityModal}
          leads={opportunityForm.leads}
          stages={opportunityForm.stages}
          defaults={opportunityForm.defaults}
          returnTo={opportunityForm.return_to}
          lockedLeadId={lead.id}
        />
      )}
    </AuthenticatedPage>
  )
}
