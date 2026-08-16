import { Head, Link, usePage } from '@inertiajs/react'
import { useState } from 'react'

import AuthenticatedPage from '@/components/layouts/AuthenticatedPage'
import EmptyState from '@/components/ui/EmptyState'
import PaginationBar from '@/components/ui/PaginationBar'
import {
  DataTable,
  DataTableBody,
  DataTableCell,
  DataTableEmpty,
  DataTableHead,
  DataTableHeaderCell,
  DataTableRow,
} from '@/components/ui/DataTable'
import MeetingFormModal, {
  type EditableMeeting,
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
  user_id?: number | null
  can_edit: boolean
  can_revert: boolean
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

function formatMeetingStatus(status: string | null): string {
  if (!status) return '—'
  return status.charAt(0).toUpperCase() + status.slice(1)
}

function buildMeetingsReturnTo(meta: MeetingsMeta): string {
  const params = new URLSearchParams()
  if (meta.page > 1) params.set('page', String(meta.page))
  if (meta.per_page !== 25) params.set('per_page', String(meta.per_page))
  const query = params.toString()
  return query ? `/meetings?${query}` : '/meetings'
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
  const [editingMeeting, setEditingMeeting] = useState<EditableMeeting | null>(null)
  const [dismissedMeetingErrorKey, setDismissedMeetingErrorKey] = useState<string | null>(null)

  const createModalOpen =
    editingMeeting == null &&
    (manualOpen || (meetingErrorKey != null && dismissedMeetingErrorKey !== meetingErrorKey))

  function openCreateModal() {
    setEditingMeeting(null)
    setDismissedMeetingErrorKey(null)
    setManualOpen(true)
  }

  function openEditModal(meeting: MeetingRow) {
    setManualOpen(false)
    setEditingMeeting({
      id: meeting.id,
      title: meeting.title,
      scheduled_on: meeting.scheduled_on,
      start_time: meeting.start_time,
      lead_id: meeting.lead_id,
      user_id: meeting.user_id,
      location: meeting.location,
      virtual_link: meeting.virtual_link,
      virtual_meeting: meeting.virtual_meeting,
      status: meeting.status,
      can_revert: meeting.can_revert,
    })
  }

  function closeModal() {
    setManualOpen(false)
    setEditingMeeting(null)
    if (meetingErrorKey != null) setDismissedMeetingErrorKey(meetingErrorKey)
  }

  const createReturnTo = buildMeetingsReturnTo(meta) || returnTo

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
              onClick={openCreateModal}
              className="inline-flex items-center justify-center rounded-lg bg-brand px-4 py-2 text-sm font-medium text-white hover:bg-brand-hover"
            >
              Schedule meeting
            </button>
          )}
        </div>

        <DataTable className="mt-8">
          <DataTableHead>
            <tr>
              <DataTableHeaderCell>Title</DataTableHeaderCell>
              <DataTableHeaderCell>Lead</DataTableHeaderCell>
              <DataTableHeaderCell>Date</DataTableHeaderCell>
              <DataTableHeaderCell>Time</DataTableHeaderCell>
              <DataTableHeaderCell>Place</DataTableHeaderCell>
              <DataTableHeaderCell>Status</DataTableHeaderCell>
              <DataTableHeaderCell>Host</DataTableHeaderCell>
              <DataTableHeaderCell align="right">Actions</DataTableHeaderCell>
            </tr>
          </DataTableHead>
          <DataTableBody>
            {meetings.length === 0 ? (
              <DataTableEmpty colSpan={8}>
                <EmptyState
                  title="No meetings yet"
                  description="Schedule a meeting to keep client conversations on track."
                  action={
                    canCreate
                      ? { label: 'Schedule meeting', onClick: openCreateModal }
                      : undefined
                  }
                />
              </DataTableEmpty>
            ) : (
              meetings.map((meeting) => (
                <DataTableRow key={meeting.id}>
                  <DataTableCell className="font-medium text-slate-900">{meeting.title}</DataTableCell>
                  <DataTableCell className="text-slate-700">
                    {meeting.lead_id ? (
                      <Link
                        href={`/leads/${meeting.lead_id}`}
                        className="inline-flex min-h-11 items-center px-1 font-medium text-brand-ink hover:text-brand"
                      >
                        {meeting.lead || '—'}
                      </Link>
                    ) : (
                      meeting.lead || '—'
                    )}
                  </DataTableCell>
                  <DataTableCell className="text-slate-700">{formatDate(meeting.scheduled_on)}</DataTableCell>
                  <DataTableCell className="text-slate-700">{meeting.start_time || '—'}</DataTableCell>
                  <DataTableCell className="max-w-xs truncate text-slate-700">
                    {placeSummary(meeting)}
                  </DataTableCell>
                  <DataTableCell className="text-slate-700">
                    {formatMeetingStatus(meeting.status)}
                  </DataTableCell>
                  <DataTableCell className="text-slate-700">{meeting.host || '—'}</DataTableCell>
                  <DataTableCell align="right">
                    {meeting.can_edit ? (
                      <button
                        type="button"
                        onClick={() => openEditModal(meeting)}
                        className="inline-flex min-h-11 items-center px-1 text-sm font-medium text-slate-700 hover:text-slate-900"
                      >
                        Edit
                      </button>
                    ) : (
                      <span className="text-slate-300">—</span>
                    )}
                  </DataTableCell>
                </DataTableRow>
              ))
            )}
          </DataTableBody>
        </DataTable>

        <PaginationBar meta={meta} path="/meetings" label="meetings" />
      </div>

      {canCreate && (
        <MeetingFormModal
          key="meeting-create"
          open={createModalOpen}
          onClose={closeModal}
          leads={leads}
          hosts={hosts}
          defaults={defaults}
          returnTo={createReturnTo}
        />
      )}

      {editingMeeting && (
        <MeetingFormModal
          key={`meeting-edit-${editingMeeting.id}`}
          open
          onClose={closeModal}
          leads={leads}
          hosts={hosts}
          defaults={defaults}
          returnTo={createReturnTo}
          lockedLeadId={editingMeeting.lead_id}
          meeting={editingMeeting}
        />
      )}
    </AuthenticatedPage>
  )
}
