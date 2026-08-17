import { Head, router } from '@inertiajs/react'
import { FormEvent, useState } from 'react'

import AuthenticatedPage from '@/components/layouts/AuthenticatedPage'
import { SelectField } from '@/components/ui/FormFields'
import EmptyState from '@/components/ui/EmptyState'
import PageHeader from '@/components/ui/PageHeader'
import PaginationBar, { type PaginationMeta } from '@/components/ui/PaginationBar'
import {
  DataTable,
  DataTableBody,
  DataTableCell,
  DataTableEmpty,
  DataTableHead,
  DataTableHeaderCell,
  DataTableRow,
} from '@/components/ui/DataTable'

export type AssistantUser = {
  id: number
  name: string
  email: string
}

export type AssistantAssignment = {
  id: number
  assistant: AssistantUser
}

type AssistantsIndexProps = {
  advisor: { id: number; name: string }
  assignments: AssistantAssignment[]
  available_assistants: AssistantUser[]
  meta: PaginationMeta
  can_manage: boolean
  managed_advisors: AssistantUser[]
}

export default function AssistantsIndex({
  advisor,
  assignments,
  available_assistants: availableAssistants,
  meta,
  can_manage: canManage,
  managed_advisors: managedAdvisors,
}: AssistantsIndexProps) {
  const [assistantId, setAssistantId] = useState(
    availableAssistants[0] ? String(availableAssistants[0].id) : '',
  )
  const [busyId, setBusyId] = useState<number | null>(null)
  const [assigning, setAssigning] = useState(false)

  function switchAdvisor(nextAdvisorId: string) {
    router.get(
      '/assistants',
      {
        advisor_id: nextAdvisorId,
        per_page: meta.per_page !== 25 ? meta.per_page : undefined,
      },
      { preserveState: true },
    )
  }

  function assignAssistant(event: FormEvent) {
    event.preventDefault()
    if (!canManage || !assistantId || assigning) return

    setAssigning(true)
    router.post(
      '/assistants',
      { assistant_id: Number(assistantId), advisor_id: advisor.id },
      {
        onFinish: () => setAssigning(false),
      },
    )
  }

  function removeAssignment(assignmentId: number) {
    if (!canManage || busyId != null) return
    setBusyId(assignmentId)
    router.delete(`/assistants/${assignmentId}`, {
      onFinish: () => setBusyId(null),
    })
  }

  return (
    <AuthenticatedPage>
      <Head title="Assistants" />

      <div>
        <PageHeader
          title="Assistants"
          description={`Assign assistants who can view and support ${advisor.name}'s leads, tasks, meetings, notes, and opportunities.`}
        />

        {managedAdvisors.length > 0 && (
          <div className="max-w-md">
            <SelectField
              id="managed-advisor"
              label="Advisor"
              value={String(advisor.id)}
              onChange={switchAdvisor}
            >
              {managedAdvisors.map((row) => (
                <option key={row.id} value={String(row.id)}>
                  {row.name}
                </option>
              ))}
            </SelectField>
          </div>
        )}

        {canManage && availableAssistants.length > 0 && (
          <form
            onSubmit={assignAssistant}
            className="mt-8 flex flex-col gap-3 rounded-xl border border-slate-200 bg-panel p-4 sm:flex-row sm:items-end"
          >
            <div className="min-w-0 flex-1">
              <SelectField
                id="assistant-id"
                label="Add assistant"
                value={assistantId}
                onChange={setAssistantId}
              >
                {availableAssistants.map((row) => (
                  <option key={row.id} value={String(row.id)}>
                    {row.name} ({row.email})
                  </option>
                ))}
              </SelectField>
            </div>
            <button
              type="submit"
              disabled={assigning || !assistantId}
              className="inline-flex items-center justify-center rounded-lg bg-brand px-4 py-2 text-sm font-medium text-white hover:bg-brand-hover disabled:cursor-not-allowed disabled:opacity-50"
            >
              {assigning ? 'Assigning…' : 'Assign'}
            </button>
          </form>
        )}

        <DataTable className="mt-8">
          <DataTableHead>
            <tr>
              <DataTableHeaderCell>Name</DataTableHeaderCell>
              <DataTableHeaderCell>Email</DataTableHeaderCell>
              <DataTableHeaderCell align="right">Actions</DataTableHeaderCell>
            </tr>
          </DataTableHead>
          <DataTableBody>
            {assignments.length === 0 ? (
              <DataTableEmpty colSpan={3}>
                <EmptyState
                  title="No assistants assigned yet"
                  description={
                    canManage
                      ? availableAssistants.length > 0
                        ? 'Pick an assistant above to give them access to this advisor\'s CRM data.'
                        : 'There are no available assistants left to assign.'
                      : 'Assistants assigned to this advisor will appear here.'
                  }
                />
              </DataTableEmpty>
            ) : (
              assignments.map((row) => (
                <DataTableRow key={row.id} hover={false} className="text-slate-800">
                  <DataTableCell className="font-medium">{row.assistant.name}</DataTableCell>
                  <DataTableCell>{row.assistant.email}</DataTableCell>
                  <DataTableCell align="right">
                    {canManage ? (
                      <button
                        type="button"
                        disabled={busyId === row.id}
                        onClick={() => removeAssignment(row.id)}
                        className="text-sm font-medium text-slate-600 hover:text-slate-900 disabled:opacity-50"
                      >
                        {busyId === row.id ? 'Removing…' : 'Remove'}
                      </button>
                    ) : (
                      <span className="text-sm text-slate-500">Assigned</span>
                    )}
                  </DataTableCell>
                </DataTableRow>
              ))
            )}
          </DataTableBody>
        </DataTable>

        <PaginationBar
          meta={meta}
          path="/assistants"
          label="assignments"
          query={{ advisor_id: advisor.id }}
        />
      </div>
    </AuthenticatedPage>
  )
}
