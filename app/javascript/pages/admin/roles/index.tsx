import { Head } from '@inertiajs/react'

import AuthenticatedPage from '@/components/layouts/AuthenticatedPage'

export type RoleOption = {
  id: number
  name: string
}

export type RoleMatrixRow = {
  role: string
  permissions: Record<string, string>
}

export type RoleMatrix = {
  columns: string[]
  rows: RoleMatrixRow[]
}

type AdminRolesIndexProps = {
  roles: RoleOption[]
  matrix: RoleMatrix
  read_only: boolean
}

const COLUMN_LABELS: Record<string, string> = {
  leads: 'Leads',
  opportunities: 'Opportunities',
  tasks: 'Tasks',
  meetings: 'Meetings',
  notes: 'Notes',
  users: 'Users',
}

export default function AdminRolesIndex({ roles, matrix, read_only: readOnly }: AdminRolesIndexProps) {
  return (
    <AuthenticatedPage>
      <Head title="Roles" />

      <div>
        <div>
          <h1 className="text-2xl font-semibold text-slate-900">Roles</h1>
          <p className="mt-1 text-slate-600">
            Seeded role definitions and access levels for the demo.
            {readOnly ? ' Permissions are fixed — they cannot be edited here.' : null}
          </p>
        </div>

        <div className="mt-6">
          <h2 className="text-sm font-semibold uppercase tracking-wide text-slate-500">Seeded roles</h2>
          {roles.length === 0 ? (
            <p className="mt-2 text-sm text-slate-600">No roles configured. Run seeds to load admin, advisor, and assistant.</p>
          ) : (
            <ul className="mt-2 flex flex-wrap gap-2">
              {roles.map((role) => (
                <li
                  key={role.id}
                  className="rounded-lg border border-slate-200 bg-white px-3 py-1.5 text-sm font-medium capitalize text-slate-800"
                >
                  {role.name}
                </li>
              ))}
            </ul>
          )}
        </div>

        {matrix.rows.length === 0 ? (
          <p className="mt-8 text-sm text-slate-600">Permission matrix unavailable until roles are seeded.</p>
        ) : (
          <div className="mt-8 overflow-x-auto rounded-xl border border-slate-200 bg-white">
            <table className="min-w-full divide-y divide-slate-200 text-left text-sm">
              <thead className="bg-slate-50 text-xs font-semibold uppercase tracking-wide text-slate-500">
                <tr>
                  <th className="px-4 py-3">Role</th>
                  {matrix.columns.map((column) => (
                    <th key={column} className="px-4 py-3">
                      {COLUMN_LABELS[column] ?? column}
                    </th>
                  ))}
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-100">
                {matrix.rows.map((row) => (
                  <tr key={row.role} className="text-slate-800">
                    <td className="px-4 py-3 font-medium capitalize">{row.role}</td>
                    {matrix.columns.map((column) => (
                      <td key={`${row.role}-${column}`} className="px-4 py-3 text-slate-600">
                        {row.permissions[column] ?? '—'}
                      </td>
                    ))}
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
