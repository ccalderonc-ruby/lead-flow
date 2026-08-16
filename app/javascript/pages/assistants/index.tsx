import { Head, router } from '@inertiajs/react'
import { FormEvent, useState } from 'react'

import AuthenticatedPage from '@/components/layouts/AuthenticatedPage'
import { SelectField } from '@/components/ui/FormFields'

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
  can_manage: boolean
  managed_advisors: AssistantUser[]
}

export default function AssistantsIndex({
  advisor,
  assignments,
  available_assistants: availableAssistants,
  can_manage: canManage,
  managed_advisors: managedAdvisors,
}: AssistantsIndexProps) {
  const [assistantId, setAssistantId] = useState(
    availableAssistants[0] ? String(availableAssistants[0].id) : '',
  )
  const [busyId, setBusyId] = useState<number | null>(null)
  const [assigning, setAssigning] = useState(false)

  function switchAdvisor(nextAdvisorId: string) {
    router.get('/assistants', { advisor_id: nextAdvisorId }, { preserveState: true })
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
        <div className="flex flex-col gap-4 sm:flex-row sm:items-end sm:justify-between">
          <div>
            <h1 className="text-2xl font-semibold text-slate-900">Assistants</h1>
            <p className="mt-1 text-slate-600">
              Assign assistants who can view and support {advisor.name}&apos;s leads, tasks,
              meetings, notes, and opportunities.
            </p>
          </div>
        </div>

        {managedAdvisors.length > 0 && (
          <div className="mt-6 max-w-md">
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
            className="mt-8 flex flex-col gap-3 rounded-xl border border-slate-200 bg-white p-4 sm:flex-row sm:items-end"
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

        {assignments.length === 0 ? (
          <p className="mt-8 text-slate-600">No assistants assigned yet.</p>
        ) : (
          <div className="mt-8 overflow-x-auto rounded-xl border border-slate-200 bg-white">
            <table className="min-w-full divide-y divide-slate-200 text-left text-sm">
              <thead className="bg-slate-50 text-xs font-semibold uppercase tracking-wide text-slate-500">
                <tr>
                  <th className="px-4 py-3">Name</th>
                  <th className="px-4 py-3">Email</th>
                  <th className="px-4 py-3 text-right">Actions</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-100">
                {assignments.map((row) => (
                  <tr key={row.id} className="text-slate-800">
                    <td className="px-4 py-3 font-medium">{row.assistant.name}</td>
                    <td className="px-4 py-3">{row.assistant.email}</td>
                    <td className="px-4 py-3 text-right">
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
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </div>
    </AuthenticatedPage>
  )
}
