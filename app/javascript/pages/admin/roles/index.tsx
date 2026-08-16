import { Head } from '@inertiajs/react'

import AuthenticatedPage from '@/components/layouts/AuthenticatedPage'
import {
  DataTable,
  DataTableBody,
  DataTableCell,
  DataTableHead,
  DataTableHeaderCell,
  DataTableRow,
} from '@/components/ui/DataTable'

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
                  className="rounded-lg border border-slate-200 bg-panel px-3 py-1.5 text-sm font-medium capitalize text-slate-800"
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
          <DataTable className="mt-8">
            <DataTableHead>
              <tr>
                <DataTableHeaderCell>Role</DataTableHeaderCell>
                {matrix.columns.map((column) => (
                  <DataTableHeaderCell key={column}>
                    {COLUMN_LABELS[column] ?? column}
                  </DataTableHeaderCell>
                ))}
              </tr>
            </DataTableHead>
            <DataTableBody>
              {matrix.rows.map((row) => (
                <DataTableRow key={row.role} hover={false} className="text-slate-800">
                  <DataTableCell className="font-medium capitalize">{row.role}</DataTableCell>
                  {matrix.columns.map((column) => (
                    <DataTableCell key={`${row.role}-${column}`} className="text-slate-600">
                      {row.permissions[column] ?? '—'}
                    </DataTableCell>
                  ))}
                </DataTableRow>
              ))}
            </DataTableBody>
          </DataTable>
        )}
      </div>
    </AuthenticatedPage>
  )
}
