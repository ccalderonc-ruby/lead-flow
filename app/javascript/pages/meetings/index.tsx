import { Head, Link, router, usePage } from '@inertiajs/react'
import { useState } from 'react'

import AuthenticatedPage from '@/components/layouts/AuthenticatedPage'
import MeetingFormModal, {
  type MeetingFormDefaults,
  type MeetingFormOption,
} from '@/components/meetings/MeetingFormModal'
import { hasMeetingCreateErrors } from '@/components/meetings/meetingFormErrors'
import { formatDate } from '@/lib/format'

export type MeetingRow = {
  id: number
  title: string
  lead: string | null
  lead_id: number | null
  scheduled_on: string | null
  start_time: string | null
  location: string | null
  virtual_link: string | null
  virtual_meeting: boolean | null
  status: string | null
  host: string | null
}

export type MeetingsMeta = {
  page: number
  per_page: number
  total_count: number
  total_pages: number
}

type MeetingsIndexProps = {
  meetings: MeetingRow[]
  meta: MeetingsMeta
  can_create: boolean
  leads: MeetingFormOption[]
  hosts: MeetingFormOption[]
  defaults: MeetingFormDefaults
  return_to: string
}

function placeSummary(meeting: MeetingRow): string {
  if (meeting.virtual_link) return meeting.virtual_link
  if (meeting.location) return meeting.location
  if (meeting.virtual_meeting) return 'Virtual'
  return '—'
}

function buildMeetingsReturnTo(meta: MeetingsMeta): string {
  if (meta.page > 1) return `/meetings?page=${meta.page}`
  return '/meetings'
}

export default function MeetingsIndex({
  meetings,
  meta,
  can_create: canCreate,
  leads,
  hosts,
  defaults,
  return_to: returnTo,
}: MeetingsIndexProps) {
  const page = usePage()
  const pageErrors = page.props.errors as Record<string, unknown> | undefined
  const meetingErrorsPresent = hasMeetingCreateErrors(pageErrors)
  const meetingErrorKey = meetingErrorsPresent ? JSON.stringify(pageErrors) : null
  const [manualOpen, setManualOpen] = useState(false)
  const [dismissedMeetingErrorKey, setDismissedMeetingErrorKey] = useState<string | null>(null)

  const modalOpen =
    manualOpen || (meetingErrorKey != null && dismissedMeetingErrorKey !== meetingErrorKey)

  function openModal() {
    setDismissedMeetingErrorKey(null)
    setManualOpen(true)
  }

  function closeModal() {
    setManualOpen(false)
    if (meetingErrorKey != null) setDismissedMeetingErrorKey(meetingErrorKey)
  }

  const createReturnTo = buildMeetingsReturnTo(meta) || returnTo

  function goToPage(pageNumber: number) {
    router.get('/meetings', { page: pageNumber }, { preserveState: true })
  }

  return (
    <AuthenticatedPage>
      <Head title="Meetings" />

      <div>
        <div className="flex flex-col gap-4 sm:flex-row sm:items-end sm:justify-between">
          <div>
            <h1 className="text-2xl font-semibold text-slate-900">Meetings</h1>
            <p className="mt-1 text-slate-600">Scheduled client conversations.</p>
          </div>

          {canCreate && (
            <button
              type="button"
              onClick={openModal}
              className="inline-flex items-center justify-center rounded-lg bg-indigo-600 px-4 py-2 text-sm font-medium text-white hover:bg-indigo-500"
            >
              Schedule meeting
            </button>
          )}
        </div>

        <div className="mt-8 overflow-x-auto rounded-xl border border-slate-200 bg-white">
          <table className="min-w-full divide-y divide-slate-200 text-left text-sm">
            <thead className="bg-slate-50 text-xs font-semibold uppercase tracking-wide text-slate-500">
              <tr>
                <th className="px-4 py-3">Title</th>
                <th className="px-4 py-3">Lead</th>
                <th className="px-4 py-3">Date</th>
                <th className="px-4 py-3">Time</th>
                <th className="px-4 py-3">Place</th>
                <th className="px-4 py-3">Status</th>
                <th className="px-4 py-3">Host</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-100">
              {meetings.length === 0 ? (
                <tr>
                  <td colSpan={7} className="px-4 py-10 text-center text-slate-500">
                    No meetings found.
                  </td>
                </tr>
              ) : (
                meetings.map((meeting) => (
                  <tr key={meeting.id} className="hover:bg-slate-50">
                    <td className="px-4 py-3 font-medium text-slate-900">{meeting.title}</td>
                    <td className="px-4 py-3 text-slate-700">
                      {meeting.lead_id ? (
                        <Link
                          href={`/leads/${meeting.lead_id}`}
                          className="font-medium text-indigo-600 hover:text-indigo-500"
                        >
                          {meeting.lead || '—'}
                        </Link>
                      ) : (
                        meeting.lead || '—'
                      )}
                    </td>
                    <td className="px-4 py-3 text-slate-700">{formatDate(meeting.scheduled_on)}</td>
                    <td className="px-4 py-3 text-slate-700">{meeting.start_time || '—'}</td>
                    <td className="max-w-xs truncate px-4 py-3 text-slate-700">{placeSummary(meeting)}</td>
                    <td className="px-4 py-3 text-slate-700">{meeting.status || '—'}</td>
                    <td className="px-4 py-3 text-slate-700">{meeting.host || '—'}</td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>

        <div className="mt-4 flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
          <p className="text-sm text-slate-500">
            {meta.total_count === 0
              ? '0 meetings'
              : `Showing page ${meta.page} of ${meta.total_pages} (${meta.total_count} total)`}
          </p>
          <div className="flex gap-2">
            <button
              type="button"
              disabled={meta.page <= 1}
              onClick={() => goToPage(meta.page - 1)}
              className="rounded-lg border border-slate-300 px-3 py-1.5 text-sm font-medium text-slate-700 enabled:hover:bg-slate-50 disabled:cursor-not-allowed disabled:opacity-40"
            >
              Previous
            </button>
            <button
              type="button"
              disabled={meta.page >= meta.total_pages}
              onClick={() => goToPage(meta.page + 1)}
              className="rounded-lg border border-slate-300 px-3 py-1.5 text-sm font-medium text-slate-700 enabled:hover:bg-slate-50 disabled:cursor-not-allowed disabled:opacity-40"
            >
              Next
            </button>
          </div>
        </div>
      </div>

      {canCreate && (
        <MeetingFormModal
          open={modalOpen}
          onClose={closeModal}
          leads={leads}
          hosts={hosts}
          defaults={defaults}
          returnTo={createReturnTo}
        />
      )}
    </AuthenticatedPage>
  )
}
