import { Head, Link } from '@inertiajs/react'

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

export type AdminUserRow = {
  id: number
  name: string
  email: string
  role: string
  status: string
  team: string
  can_update: boolean
}

export type AdminUsersMeta = {
  page: number
  per_page: number
  total_count: number
  total_pages: number
}

type AdminUsersIndexProps = {
  users: AdminUserRow[]
  meta: AdminUsersMeta
  can_create: boolean
}

export default function AdminUsersIndex({
  users,
  meta,
  can_create: canCreate,
}: AdminUsersIndexProps) {
  return (
    <AuthenticatedPage>
      <Head title="Users" />

      <div>
        <div className="flex flex-col gap-4 sm:flex-row sm:items-end sm:justify-between">
          <div>
            <h1 className="text-2xl font-semibold text-slate-900">Users</h1>
            <p className="mt-1 text-slate-600">Create and manage team accounts.</p>
          </div>

          {canCreate && (
            <Link
              href="/admin/users/new"
              className="inline-flex items-center justify-center rounded-lg bg-brand px-4 py-2 text-sm font-medium text-white hover:bg-brand-hover"
            >
              New user
            </Link>
          )}
        </div>

        <DataTable className="mt-8">
          <DataTableHead>
            <tr>
              <DataTableHeaderCell>Name</DataTableHeaderCell>
              <DataTableHeaderCell>Email</DataTableHeaderCell>
              <DataTableHeaderCell>Role</DataTableHeaderCell>
              <DataTableHeaderCell>Status</DataTableHeaderCell>
              <DataTableHeaderCell>Team</DataTableHeaderCell>
              <DataTableHeaderCell>Actions</DataTableHeaderCell>
            </tr>
          </DataTableHead>
          <DataTableBody>
            {users.length === 0 ? (
              <DataTableEmpty colSpan={6}>
                <EmptyState
                  title="No users yet"
                  description="Create the first team account to get started."
                  action={
                    canCreate
                      ? { label: 'New user', href: '/admin/users/new' }
                      : undefined
                  }
                />
              </DataTableEmpty>
            ) : (
              users.map((user) => (
                <DataTableRow key={user.id} hover={false} className="text-slate-800">
                  <DataTableCell className="font-medium">{user.name}</DataTableCell>
                  <DataTableCell>{user.email}</DataTableCell>
                  <DataTableCell className="capitalize">{user.role}</DataTableCell>
                  <DataTableCell className="capitalize">{user.status}</DataTableCell>
                  <DataTableCell>{user.team}</DataTableCell>
                  <DataTableCell>
                    {user.can_update ? (
                      <Link
                        href={`/admin/users/${user.id}/edit`}
                        className="inline-flex min-h-11 items-center px-1 font-medium text-brand-ink hover:text-brand"
                      >
                        Edit
                      </Link>
                    ) : (
                      <span className="text-slate-400">—</span>
                    )}
                  </DataTableCell>
                </DataTableRow>
              ))
            )}
          </DataTableBody>
        </DataTable>

        <PaginationBar meta={meta} path="/admin/users" label="users" />
      </div>
    </AuthenticatedPage>
  )
}
