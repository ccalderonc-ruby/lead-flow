import { Head, Link, router, usePage } from '@inertiajs/react'
import { useState } from 'react'

import AuthenticatedPage from '@/components/layouts/AuthenticatedPage'
import MetricCard from '@/components/dashboard/MetricCard'
import OnboardingPanel, { type OnboardingProps } from '@/components/dashboard/OnboardingPanel'
import LeadFormModal from '@/components/leads/LeadFormModal'
import { hasLeadCreateErrors } from '@/components/leads/leadFormErrors'
import type { LeadFormDefaults, LeadFormOption } from '@/components/leads/LeadForm'
import MeetingFormModal, {
  type EditableMeeting,
  type MeetingFormDefaults,
  type MeetingFormOption,
} from '@/components/meetings/MeetingFormModal'
import { hasMeetingCreateErrors } from '@/components/meetings/meetingFormErrors'
import NoteFormModal, { type NoteFormOption } from '@/components/notes/NoteFormModal'
import { hasNoteCreateErrors } from '@/components/notes/noteFormErrors'
import TaskFormModal, {
  type EditableTask,
  type TaskFormDefaults,
  type TaskFormOption,
} from '@/components/tasks/TaskFormModal'
import { hasTaskCreateErrors } from '@/components/tasks/taskFormErrors'
import { SelectField } from '@/components/ui/FormFields'
import { formatCurrency } from '@/lib/format'
import { formatRoleLabel } from '@/lib/navigation'
import type { SharedProps } from '@/types'

const DASHBOARD_RETURN_TO = '/'

type QuickActionModal = 'lead' | 'task' | 'meeting' | 'note'

export type DashboardMetrics = {
  open_leads: number
  active_opportunities: number
  tasks_due_today: number
  high_priority_tasks_due_today: number
  meetings_today: number
  next_meeting_time: string | null
  overdue_tasks: number
  upcoming_meetings: number
  pipeline_value: number
}

export type DashboardAdvisorOption = {
  id: number
  name: string
  role?: string
}

export type DashboardActivity = {
  id: number
  kind: 'meeting' | 'task'
  title: string
  when_label: string
  lead_name: string | null
  virtual_link: string | null
  can_complete: boolean
  can_edit: boolean
  can_revert: boolean
  lead_id: number | null
  user_id?: number | null
  status: string | null
  description?: string | null
  due_date?: string | null
  scheduled_on?: string | null
  start_time?: string | null
  location?: string | null
  virtual_meeting?: boolean | null
}

export type DashboardRecentLead = {
  id: number
  name: string
  company: string | null
  stage: string | null
  owner: string | null
}

export type DashboardPipelineStage = {
  id: number
  name: string
  count: number
  value: number
}

type DashboardView = 'personal' | 'organization' | 'advisor'

function activityDaysLabel(days: number): string {
  if (days === 0) return 'Today'
  if (days === 1) return '1 day'
  return `${days} days`
}

type DashboardIndexProps = {
  metrics: DashboardMetrics
  upcoming_activities: DashboardActivity[]
  recent_leads: DashboardRecentLead[]
  pipeline_stages: DashboardPipelineStage[]
  activity_days: number
  activity_day_options: number[]
  lead_stage_id: number | null
  lead_stage_options: { id: number; name: string }[]
  view: DashboardView
  can_switch_view: boolean
  advisors: DashboardAdvisorOption[]
  selected_advisor_id: number | null
  selected_advisor_name: string | null
  greeting: {
    name: string
    first_name: string
    role_label: string
    date_label: string
    first_session?: boolean
  }
  onboarding: OnboardingProps
  actions: {
    can_create_lead: boolean
    can_create_task: boolean
    can_create_meeting: boolean
    can_create_note: boolean
  }
  forms: {
    lead: {
      countries: LeadFormOption[]
      stages: LeadFormOption[]
      assignees: LeadFormOption[]
      defaults: LeadFormDefaults
    }
    task: {
      leads: TaskFormOption[]
      assignees: TaskFormOption[]
      defaults: TaskFormDefaults
    }
    meeting: {
      leads: MeetingFormOption[]
      hosts: MeetingFormOption[]
      defaults: MeetingFormDefaults
    }
    note: {
      leads: NoteFormOption[]
      opportunities: NoteFormOption[]
    }
  }
}

function modalFromErrors(errors: Record<string, unknown> | undefined): QuickActionModal | null {
  if (!errors) return null
  if (hasLeadCreateErrors(errors)) return 'lead'
  if (hasNoteCreateErrors(errors)) return 'note'
  if (hasMeetingCreateErrors(errors)) return 'meeting'
  if (hasTaskCreateErrors(errors)) return 'task'
  return null
}

function stageBadgeClass(stage: string | null): string {
  switch (stage) {
    case 'Prospect':
    case 'Prospects':
      return 'bg-sky-100 text-sky-800'
    case 'Qualified':
      return 'bg-emerald-100 text-emerald-800'
    case 'Proposal':
      return 'bg-violet-100 text-violet-800'
    case 'Negotiation':
      return 'bg-fuchsia-100 text-fuchsia-800'
    case 'Closed':
    case 'Won':
    case 'Lost':
      return 'bg-slate-100 text-slate-600'
    default:
      return 'bg-amber-100 text-amber-900'
  }
}

function compactCurrency(amount: number): string {
  if (amount >= 1_000_000) return `$${(amount / 1_000_000).toFixed(1)}M`
  if (amount >= 1_000) return `$${Math.round(amount / 1_000)}k`
  return formatCurrency(amount)
}

function completeTask(taskId: number) {
  router.patch(`/tasks/${taskId}`, { status: 'completed', return_to: '/' }, { preserveScroll: true })
}

export default function DashboardIndex({
  metrics,
  upcoming_activities: activities,
  recent_leads: recentLeads,
  pipeline_stages: pipelineStages,
  activity_days: activityDays,
  activity_day_options: activityDayOptions,
  lead_stage_id: leadStageId,
  lead_stage_options: leadStageOptions,
  view,
  can_switch_view: canSwitchView,
  advisors,
  selected_advisor_id: selectedAdvisorId,
  greeting,
  onboarding,
  actions,
  forms,
}: DashboardIndexProps) {
  const page = usePage<SharedProps>()
  const { auth } = page.props
  const pageErrors = page.props.errors as Record<string, unknown> | undefined
  const errorModal = modalFromErrors(pageErrors)
  const errorKey = errorModal && pageErrors ? JSON.stringify(pageErrors) : null
  const [manualModal, setManualModal] = useState<QuickActionModal | null>(null)
  const [dismissedErrorKey, setDismissedErrorKey] = useState<string | null>(null)
  const [editingTask, setEditingTask] = useState<EditableTask | null>(null)
  const [editingMeeting, setEditingMeeting] = useState<EditableMeeting | null>(null)
  const activeModal =
    editingTask == null && editingMeeting == null
      ? (manualModal ?? (errorKey != null && dismissedErrorKey !== errorKey ? errorModal : null))
      : null
  const maxPipelineValue = Math.max(...pipelineStages.map((stage) => stage.value), 1)

  function openModal(modal: QuickActionModal) {
    setEditingTask(null)
    setEditingMeeting(null)
    setDismissedErrorKey(null)
    setManualModal(modal)
  }

  function closeModal() {
    if (errorKey != null) setDismissedErrorKey(errorKey)
    setManualModal(null)
    setEditingTask(null)
    setEditingMeeting(null)
  }

  function openActivityDetails(item: DashboardActivity) {
    setManualModal(null)
    setDismissedErrorKey(null)

    if (item.kind === 'task') {
      setEditingMeeting(null)
      setEditingTask({
        id: item.id,
        title: item.title,
        description: item.description,
        due_date: item.due_date ?? null,
        lead_id: item.lead_id,
        user_id: item.user_id,
        status: item.status,
        can_revert: item.can_revert,
      })
      return
    }

    setEditingTask(null)
    setEditingMeeting({
      id: item.id,
      title: item.title,
      scheduled_on: item.scheduled_on ?? null,
      start_time: item.start_time ?? null,
      lead_id: item.lead_id,
      user_id: item.user_id,
      location: item.location,
      virtual_link: item.virtual_link,
      virtual_meeting: item.virtual_meeting,
      status: item.status,
      can_revert: item.can_revert,
    })
  }

  function dashboardParams(extra: Record<string, string | undefined> = {}) {
    const params: Record<string, string> = {
      activity_days: String(activityDays),
      lead_stage_id: leadStageId != null ? String(leadStageId) : '',
      ...Object.fromEntries(
        Object.entries(extra).filter((entry): entry is [string, string] => entry[1] != null),
      ),
    }
    return params
  }

  function visitDashboard(extra: Record<string, string | undefined> = {}) {
    const params = dashboardParams(extra)
    if (canSwitchView) {
      params.view = (extra.view ?? (view === 'advisor' ? 'advisor' : 'organization')) as string
      if (params.view === 'advisor') {
        const advisorId = extra.advisor_id ?? (selectedAdvisorId != null ? String(selectedAdvisorId) : undefined)
        if (advisorId) params.advisor_id = advisorId
      }
    }
    router.get('/', params, { preserveState: false, replace: true })
  }

  function setView(nextView: 'organization' | 'advisor') {
    const extra: Record<string, string | undefined> = { view: nextView }
    if (nextView === 'advisor') {
      extra.advisor_id =
        selectedAdvisorId != null ? String(selectedAdvisorId) : advisors[0] ? String(advisors[0].id) : undefined
    }
    visitDashboard(extra)
  }

  function setAdvisor(advisorId: string) {
    visitDashboard({ view: 'advisor', advisor_id: advisorId })
  }

  function setActivityDays(nextDays: string) {
    visitDashboard({ activity_days: nextDays })
  }

  function setLeadStage(nextStageId: string) {
    visitDashboard({ lead_stage_id: nextStageId })
  }

  const firstName = greeting.first_name || auth.user?.name?.split(/\s+/)[0] || 'there'
  const welcomeLabel = greeting.first_session || onboarding.show ? 'Welcome' : 'Welcome back'
  const tasksHint =
    metrics.high_priority_tasks_due_today > 0
      ? `${metrics.high_priority_tasks_due_today} high priority`
      : metrics.overdue_tasks > 0
        ? `${metrics.overdue_tasks} overdue`
        : 'Due today'
  const meetingsHint = metrics.next_meeting_time
    ? `Next at ${metrics.next_meeting_time}`
    : metrics.upcoming_meetings > 0
      ? `${metrics.upcoming_meetings} in next 7 days`
      : 'None scheduled today'

  return (
    <AuthenticatedPage>
      <Head title="Dashboard" />

      <div className="space-y-8">
        <div className="flex flex-col gap-4 lg:flex-row lg:items-end lg:justify-between">
          <div>
            <h1 className="text-3xl font-semibold tracking-tight text-ink">
              {welcomeLabel}, {firstName}
            </h1>
            <p className="mt-1 text-slate-600">
              {greeting.role_label} · {greeting.date_label}
            </p>
          </div>

          {canSwitchView && (
            <div className="flex flex-col gap-3 sm:items-end">
              <div
                className="flex flex-wrap gap-1 rounded-lg border border-slate-200 bg-panel p-1"
                role="group"
                aria-label="Dashboard view"
              >
                <button
                  type="button"
                  aria-pressed={view === 'organization'}
                  onClick={() => setView('organization')}
                  className={
                    view === 'organization'
                      ? 'rounded-md bg-navy px-3 py-2.5 text-sm font-medium text-white min-h-11'
                      : 'rounded-md px-3 py-2.5 text-sm font-medium text-slate-600 hover:bg-slate-50 min-h-11'
                  }
                >
                  Organization
                </button>
                <button
                  type="button"
                  aria-pressed={view === 'advisor'}
                  onClick={() => setView('advisor')}
                  disabled={advisors.length === 0}
                  className={
                    view === 'advisor'
                      ? 'rounded-md bg-navy px-3 py-2.5 text-sm font-medium text-white min-h-11 disabled:cursor-not-allowed disabled:opacity-50'
                      : 'rounded-md px-3 py-2.5 text-sm font-medium text-slate-600 hover:bg-slate-50 min-h-11 disabled:cursor-not-allowed disabled:opacity-50'
                  }
                >
                  Advisor
                </button>
              </div>

              {view === 'advisor' && advisors.length > 0 && (
                <div className="w-full min-w-[16rem] sm:w-72">
                  <SelectField
                    id="dashboard-advisor"
                    label="Advisor"
                    value={selectedAdvisorId != null ? String(selectedAdvisorId) : ''}
                    onChange={setAdvisor}
                  >
                    {advisors.map((advisor) => (
                      <option key={advisor.id} value={String(advisor.id)}>
                        {advisor.role
                          ? `${advisor.name} (${formatRoleLabel(advisor.role)})`
                          : advisor.name}
                      </option>
                    ))}
                  </SelectField>
                </div>
              )}
            </div>
          )}
        </div>

        <OnboardingPanel onboarding={onboarding} onCreateLead={() => openModal('lead')} />

        <div className="grid gap-4 sm:grid-cols-2 xl:grid-cols-4">
          <MetricCard
            label="Open leads"
            value={String(metrics.open_leads)}
            hint="Excludes closed stage"
            accentClassName="bg-brand"
          />
          <MetricCard
            label="Active opportunities"
            value={String(metrics.active_opportunities)}
            hint={formatCurrency(metrics.pipeline_value)}
            accentClassName="bg-amber-500"
          />
          <MetricCard
            label="Tasks due today"
            value={String(metrics.tasks_due_today)}
            hint={tasksHint}
            accentClassName="bg-teal-500"
          />
          <MetricCard
            label="Meetings today"
            value={String(metrics.meetings_today)}
            hint={meetingsHint}
            accentClassName="bg-violet-500"
          />
        </div>

        <div className="grid gap-6 xl:grid-cols-[minmax(0,1fr)_20rem]">
          <div className="space-y-6">
            <section className="rounded-xl border border-slate-200 bg-panel shadow-sm">
              <div className="flex flex-col gap-3 border-b border-slate-100 px-5 py-4 sm:flex-row sm:items-end sm:justify-between">
                <h2 className="text-lg font-semibold text-ink">Upcoming activities</h2>
                <div className="flex flex-col gap-3 sm:flex-row sm:items-end">
                  <div className="w-full sm:w-40">
                    <SelectField
                      id="activity-days"
                      label="Show next"
                      value={String(activityDays)}
                      onChange={setActivityDays}
                    >
                      {activityDayOptions.map((days) => (
                        <option key={days} value={String(days)}>
                          {activityDaysLabel(days)}
                        </option>
                      ))}
                    </SelectField>
                  </div>
                  <div className="flex items-center gap-3 pb-2">
                    <Link
                      href="/tasks"
                      className="text-sm font-medium text-brand-ink hover:text-brand"
                    >
                      View tasks
                    </Link>
                    <Link
                      href="/meetings"
                      className="text-sm font-medium text-brand-ink hover:text-brand"
                    >
                      View meetings
                    </Link>
                  </div>
                </div>
              </div>
              {activities.length === 0 ? (
                <p className="px-5 py-8 text-sm text-slate-500">
                  No upcoming tasks or meetings in this range.
                </p>
              ) : (
                <ul className="divide-y divide-slate-100">
                  {activities.map((item) => (
                    <li
                      key={`${item.kind}-${item.id}`}
                      className="flex flex-col gap-3 px-5 py-4 sm:flex-row sm:items-center sm:justify-between"
                    >
                      <div className="flex min-w-0 items-start gap-3">
                        <span
                          className={
                            item.kind === 'meeting'
                              ? 'mt-1 h-2.5 w-2.5 shrink-0 rounded-full bg-brand'
                              : 'mt-1 h-2.5 w-2.5 shrink-0 rounded-full bg-amber-500'
                          }
                          aria-hidden
                        />
                        <div className="min-w-0">
                          <p className="truncate font-medium text-slate-900">{item.title}</p>
                          <p className="mt-0.5 text-sm text-slate-500">
                            {item.when_label}
                            {item.lead_name ? ` · ${item.lead_name}` : ''}
                          </p>
                        </div>
                      </div>
                      <div className="flex flex-wrap gap-2 sm:justify-end">
                        {item.kind === 'meeting' && item.virtual_link && (
                          <a
                            href={item.virtual_link}
                            target="_blank"
                            rel="noreferrer"
                            className="inline-flex min-h-11 items-center rounded-lg bg-brand px-3 py-2.5 text-sm font-medium text-white hover:bg-brand-hover"
                          >
                            Join meeting
                          </a>
                        )}
                        {item.kind === 'task' && item.can_complete && (
                          <button
                            type="button"
                            onClick={() => completeTask(item.id)}
                            className="inline-flex min-h-11 items-center rounded-lg border border-slate-300 px-3 py-2.5 text-sm font-medium text-slate-700 hover:bg-slate-50"
                          >
                            Mark complete
                          </button>
                        )}
                        <button
                          type="button"
                          onClick={() => openActivityDetails(item)}
                          className="inline-flex min-h-11 items-center rounded-lg border border-slate-300 px-3 py-2.5 text-sm font-medium text-slate-700 hover:bg-slate-50"
                        >
                          Details
                        </button>
                      </div>
                    </li>
                  ))}
                </ul>
              )}
            </section>

            <section className="overflow-hidden rounded-xl border border-slate-200 bg-panel shadow-sm">
              <div className="flex flex-col gap-3 border-b border-slate-100 px-5 py-4 sm:flex-row sm:items-end sm:justify-between">
                <h2 className="text-lg font-semibold text-ink">Recent leads</h2>
                <div className="flex flex-col gap-3 sm:flex-row sm:items-end">
                  <div className="w-full sm:w-44">
                    <SelectField
                      id="recent-lead-stage"
                      label="Stage"
                      value={leadStageId != null ? String(leadStageId) : ''}
                      onChange={setLeadStage}
                    >
                      <option value="">All stages</option>
                      {leadStageOptions.map((stage) => (
                        <option key={stage.id} value={String(stage.id)}>
                          {stage.name}
                        </option>
                      ))}
                    </SelectField>
                  </div>
                  <Link
                    href="/leads"
                    className="pb-2 text-sm font-medium text-brand-ink hover:text-brand"
                  >
                    View all
                  </Link>
                </div>
              </div>
              {recentLeads.length === 0 ? (
                <p className="px-5 py-8 text-sm text-slate-500">
                  {leadStageId != null ? 'No leads in this stage.' : 'No leads yet.'}
                </p>
              ) : (
                <div className="overflow-x-auto">
                  <table className="min-w-full divide-y divide-slate-200 text-left text-sm">
                    <thead className="bg-slate-50 text-xs font-semibold uppercase tracking-wide text-slate-500">
                      <tr>
                        <th className="px-5 py-3">Name</th>
                        <th className="px-5 py-3">Company</th>
                        <th className="px-5 py-3">Stage</th>
                        <th className="px-5 py-3">Owner</th>
                      </tr>
                    </thead>
                    <tbody className="divide-y divide-slate-100">
                      {recentLeads.map((lead) => (
                        <tr key={lead.id} className="text-slate-800">
                          <td className="px-5 py-3 font-medium">
                            <Link href={`/leads/${lead.id}`} className="hover:text-brand">
                              {lead.name}
                            </Link>
                          </td>
                          <td className="px-5 py-3 text-slate-600">{lead.company || '—'}</td>
                          <td className="px-5 py-3">
                            <span
                              className={`inline-flex rounded-full px-2.5 py-0.5 text-xs font-medium ${stageBadgeClass(lead.stage)}`}
                            >
                              {lead.stage || '—'}
                            </span>
                          </td>
                          <td className="px-5 py-3 text-slate-600">{lead.owner || '—'}</td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                </div>
              )}
            </section>
          </div>

          <aside className="space-y-6">
            <section className="rounded-xl border border-slate-200 bg-panel p-5 shadow-sm">
              <h2 className="text-lg font-semibold text-ink">Quick actions</h2>
              <div className="mt-4 flex flex-col gap-2">
                {actions.can_create_lead ? (
                  <button
                    type="button"
                    onClick={() => openModal('lead')}
                    className="inline-flex items-center justify-center rounded-lg bg-brand px-4 py-2.5 text-sm font-medium text-white hover:bg-brand-hover"
                  >
                    + Create new lead
                  </button>
                ) : null}
                {actions.can_create_task ? (
                  <button
                    type="button"
                    onClick={() => openModal('task')}
                    className="inline-flex items-center justify-center rounded-lg border border-slate-300 px-4 py-2.5 text-sm font-medium text-slate-700 hover:bg-slate-50"
                  >
                    Add task
                  </button>
                ) : null}
                {actions.can_create_meeting ? (
                  <button
                    type="button"
                    onClick={() => openModal('meeting')}
                    className="inline-flex items-center justify-center rounded-lg border border-slate-300 px-4 py-2.5 text-sm font-medium text-slate-700 hover:bg-slate-50"
                  >
                    Schedule meeting
                  </button>
                ) : null}
                {actions.can_create_note ? (
                  <button
                    type="button"
                    onClick={() => openModal('note')}
                    className="inline-flex items-center justify-center rounded-lg border border-slate-300 px-4 py-2.5 text-sm font-medium text-slate-700 hover:bg-slate-50"
                  >
                    Write a quick note
                  </button>
                ) : null}
              </div>
            </section>

            <section className="rounded-xl border border-slate-200 bg-panel p-5 shadow-sm">
              <div className="flex items-baseline justify-between gap-3">
                <h2 className="text-lg font-semibold text-ink">Pipeline snapshot</h2>
                <p className="text-sm font-semibold text-brand-ink">
                  {compactCurrency(metrics.pipeline_value)}
                </p>
              </div>
              <ul className="mt-5 space-y-4">
                {pipelineStages.map((stage, index) => {
                  const width = Math.max((stage.value / maxPipelineValue) * 100, stage.count > 0 ? 8 : 0)
                  const barColors = ['bg-brand', 'bg-amber-500', 'bg-teal-500', 'bg-violet-400']
                  return (
                    <li key={stage.id}>
                      <div className="mb-1.5 flex items-center justify-between gap-2 text-sm">
                        <span className="font-medium text-slate-800">
                          {stage.name}{' '}
                          <span className="font-normal text-slate-500">({stage.count})</span>
                        </span>
                        <span className="text-slate-600">{compactCurrency(stage.value)}</span>
                      </div>
                      <div className="h-2 overflow-hidden rounded-full bg-slate-100">
                        <div
                          className={`h-full rounded-full ${barColors[index % barColors.length]}`}
                          style={{ width: `${width}%` }}
                        />
                      </div>
                    </li>
                  )
                })}
              </ul>
              <Link
                href="/opportunities"
                className="mt-5 inline-flex text-sm font-medium text-brand-ink hover:text-brand"
              >
                Open board
              </Link>
            </section>
          </aside>
        </div>
      </div>

      {actions.can_create_lead && (
        <LeadFormModal
          key="dashboard-lead-create"
          open={activeModal === 'lead'}
          onClose={closeModal}
          countries={forms.lead.countries}
          stages={forms.lead.stages}
          assignees={forms.lead.assignees}
          defaults={forms.lead.defaults}
          returnTo={DASHBOARD_RETURN_TO}
        />
      )}

      {actions.can_create_task && (
        <TaskFormModal
          key="dashboard-task-create"
          open={activeModal === 'task'}
          onClose={closeModal}
          leads={forms.task.leads}
          assignees={forms.task.assignees}
          defaults={forms.task.defaults}
          returnTo={DASHBOARD_RETURN_TO}
        />
      )}

      {editingTask && (
        <TaskFormModal
          key={`dashboard-task-edit-${editingTask.id}`}
          open
          onClose={closeModal}
          leads={forms.task.leads}
          assignees={forms.task.assignees}
          defaults={forms.task.defaults}
          returnTo={DASHBOARD_RETURN_TO}
          task={editingTask}
        />
      )}

      {actions.can_create_meeting && (
        <MeetingFormModal
          key="dashboard-meeting-create"
          open={activeModal === 'meeting'}
          onClose={closeModal}
          leads={forms.meeting.leads}
          hosts={forms.meeting.hosts}
          defaults={forms.meeting.defaults}
          returnTo={DASHBOARD_RETURN_TO}
        />
      )}

      {editingMeeting && (
        <MeetingFormModal
          key={`dashboard-meeting-edit-${editingMeeting.id}`}
          open
          onClose={closeModal}
          leads={forms.meeting.leads}
          hosts={forms.meeting.hosts}
          defaults={forms.meeting.defaults}
          returnTo={DASHBOARD_RETURN_TO}
          meeting={editingMeeting}
        />
      )}

      {actions.can_create_note && (
        <NoteFormModal
          key="dashboard-note-create"
          open={activeModal === 'note'}
          onClose={closeModal}
          leads={forms.note.leads}
          opportunities={forms.note.opportunities}
          returnTo={DASHBOARD_RETURN_TO}
        />
      )}
    </AuthenticatedPage>
  )
}

export type DashboardPageProps = DashboardIndexProps
