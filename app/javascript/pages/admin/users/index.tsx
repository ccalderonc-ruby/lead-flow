import { Head, Link } from '@inertiajs/react'

import AuthenticatedPage from '@/components/layouts/AuthenticatedPage'
import Button from '@/components/ui/Button'
import EmptyState from '@/components/ui/EmptyState'
import PageHeader from '@/components/ui/PageHeader'
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
        <PageHeader
          title="Users"
          description="Create and manage team accounts."
          actions={
            canCreate ? (
              <Button href="/admin/users/new">+ New User</Button>
            ) : undefined
          }
        />

        <DataTable className="mt-2">
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
