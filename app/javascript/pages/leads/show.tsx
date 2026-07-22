import { Head, Link, router, usePage } from '@inertiajs/react'
import { useState, type ReactNode } from 'react'

import AuthenticatedPage from '@/components/layouts/AuthenticatedPage'
import NoteFormModal from '@/components/notes/NoteFormModal'
import { hasNoteCreateErrors } from '@/components/notes/noteFormErrors'
import TaskFormModal, {
  type TaskFormDefaults,
  type TaskFormOption,
} from '@/components/tasks/TaskFormModal'
import { hasTaskCreateErrors } from '@/components/tasks/taskFormErrors'
import { formatCurrency, formatDate, formatDateTime } from '@/lib/format'

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
  due_date: string | null
  status: string | null
  can_complete: boolean
}

type MeetingPreview = {
  id: number
  title: string
  scheduled_on: string | null
  status: string | null
}

type NotePreview = {
  id: number
  content: string
  author: string | null
  created_at: string | null
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

type NoteFormProps = {
  lead_id: number
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
  can_create_note: boolean
  note_form: NoteFormProps
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
  can_create_note: canCreateNote,
  note_form: noteForm,
}: LeadsShowProps) {
  const page = usePage()
  const pageErrors = page.props.errors as Record<string, unknown> | undefined
  const noteErrorsPresent = hasNoteCreateErrors(pageErrors)
  // On lead show, note wins shared lead_id/base errors so both modals do not open.
  const taskErrorsPresent = hasTaskCreateErrors(pageErrors) && !noteErrorsPresent
  const taskErrorKey = taskErrorsPresent ? JSON.stringify(pageErrors) : null
  const noteErrorKey = noteErrorsPresent ? JSON.stringify(pageErrors) : null
  const [taskManualOpen, setTaskManualOpen] = useState(false)
  const [noteManualOpen, setNoteManualOpen] = useState(false)
  const [dismissedTaskErrorKey, setDismissedTaskErrorKey] = useState<string | null>(null)
  const [dismissedNoteErrorKey, setDismissedNoteErrorKey] = useState<string | null>(null)
  const [completingId, setCompletingId] = useState<number | null>(null)

  const taskModalOpen =
    taskManualOpen || (taskErrorKey != null && dismissedTaskErrorKey !== taskErrorKey)
  const noteModalOpen =
    noteManualOpen || (noteErrorKey != null && dismissedNoteErrorKey !== noteErrorKey)

  function openTaskModal() {
    setDismissedTaskErrorKey(null)
    setTaskManualOpen(true)
  }

  function closeTaskModal() {
    setTaskManualOpen(false)
    if (taskErrorKey != null) setDismissedTaskErrorKey(taskErrorKey)
  }

  function openNoteModal() {
    setDismissedNoteErrorKey(null)
    setNoteManualOpen(true)
  }

  function closeNoteModal() {
    setNoteManualOpen(false)
    if (noteErrorKey != null) setDismissedNoteErrorKey(noteErrorKey)
  }

  function completeTask(taskId: number) {
    if (completingId != null) return

    setCompletingId(taskId)
    router.patch(
      `/tasks/${taskId}`,
      { status: 'completed', return_to: taskForm.return_to },
      {
        preserveScroll: true,
        onFinish: () => setCompletingId(null),
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
                    Due {formatDate(task.due_date)} · {task.status || '—'}
                  </div>
                </div>
                {task.can_complete && (
                  <button
                    type="button"
                    disabled={completingId != null}
                    onClick={() => completeTask(task.id)}
                    className="shrink-0 text-sm font-medium text-indigo-600 hover:text-indigo-500 disabled:cursor-not-allowed disabled:opacity-50"
                  >
                    {completingId === task.id ? 'Completing…' : 'Complete'}
                  </button>
                )}
              </li>
            ))}
          </Section>

          <Section title="Meetings" count={meetings.count} empty="No meetings yet.">
            {meetings.items.map((meeting) => (
              <li key={meeting.id} className="px-4 py-3">
                <div className="font-medium text-slate-900">{meeting.title}</div>
                <div className="mt-1 text-xs text-slate-500">
                  {formatDate(meeting.scheduled_on)} · {meeting.status || '—'}
                </div>
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
              <li key={note.id} className="px-4 py-3">
                <div className="whitespace-pre-wrap text-sm text-slate-900">{note.content}</div>
                <div className="mt-1 text-xs text-slate-500">
                  {note.author || '—'} · {formatDateTime(note.created_at)}
                </div>
              </li>
            ))}
          </Section>

          <Section title="Opportunities" count={opportunities.count} empty="No opportunities yet.">
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
          open={taskModalOpen}
          onClose={closeTaskModal}
          leads={taskForm.leads}
          assignees={taskForm.assignees}
          defaults={taskForm.defaults}
          returnTo={taskForm.return_to}
          lockedLeadId={lead.id}
        />
      )}

      {canCreateNote && (
        <NoteFormModal
          open={noteModalOpen}
          onClose={closeNoteModal}
          leadId={noteForm.lead_id}
          returnTo={noteForm.return_to}
        />
      )}
    </AuthenticatedPage>
  )
}
