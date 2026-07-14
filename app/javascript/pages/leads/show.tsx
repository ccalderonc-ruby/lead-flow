import { Head, Link } from '@inertiajs/react'
import type { ReactNode } from 'react'

import AuthenticatedPage from '@/components/layouts/AuthenticatedPage'

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
}

type MeetingPreview = {
  id: number
  title: string
  scheduled_on: string | null
  status: string | null
}

type NotePreview = {
  id: number
  content_preview: string
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

type LeadsShowProps = {
  lead: LeadDetail
  tasks: RelatedSection<TaskPreview>
  meetings: RelatedSection<MeetingPreview>
  notes: RelatedSection<NotePreview>
  opportunities: RelatedSection<OpportunityPreview>
}

function formatCurrency(amount: string | number | null): string {
  if (amount == null || amount === '') return '—'
  const value = typeof amount === 'number' ? amount : Number(amount)
  if (Number.isNaN(value)) return '—'
  return new Intl.NumberFormat('en-US', {
    style: 'currency',
    currency: 'USD',
    maximumFractionDigits: 0,
  }).format(value)
}

function formatDate(iso: string | null): string {
  if (!iso) return '—'

  // Date-only values must not be parsed as local midnight (UTC day shift in AMERICAs).
  if (/^\d{4}-\d{2}-\d{2}$/.test(iso)) {
    const [year, month, day] = iso.split('-').map(Number)
    return new Intl.DateTimeFormat('en-US', {
      month: 'short',
      day: 'numeric',
      year: 'numeric',
      timeZone: 'UTC',
    }).format(new Date(Date.UTC(year, month - 1, day)))
  }

  return new Intl.DateTimeFormat('en-US', {
    month: 'short',
    day: 'numeric',
    year: 'numeric',
  }).format(new Date(iso))
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
  children,
}: {
  title: string
  count: number
  empty: string
  children: ReactNode
}) {
  return (
    <section className="rounded-xl border border-slate-200 bg-white">
      <div className="flex items-center justify-between border-b border-slate-100 px-4 py-3">
        <h2 className="text-sm font-semibold text-slate-900">{title}</h2>
        <span className="rounded-full bg-slate-100 px-2.5 py-0.5 text-xs font-medium text-slate-600">
          {count}
        </span>
      </div>
      {count === 0 ? (
        <p className="px-4 py-6 text-sm text-slate-500">{empty}</p>
      ) : (
        <ul className="divide-y divide-slate-100">{children}</ul>
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
}: LeadsShowProps) {
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
          <Section title="Tasks" count={tasks.count} empty="No tasks yet.">
            {tasks.items.map((task) => (
              <li key={task.id} className="px-4 py-3">
                <div className="font-medium text-slate-900">{task.title}</div>
                <div className="mt-1 text-xs text-slate-500">
                  Due {formatDate(task.due_date)} · {task.status || '—'}
                </div>
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

          <Section title="Notes" count={notes.count} empty="No notes yet.">
            {notes.items.map((note) => (
              <li key={note.id} className="px-4 py-3">
                <div className="text-sm text-slate-900">{note.content_preview}</div>
                <div className="mt-1 text-xs text-slate-500">
                  {note.author || '—'} · {formatDate(note.created_at)}
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
    </AuthenticatedPage>
  )
}
