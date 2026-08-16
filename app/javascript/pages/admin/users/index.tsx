import { Head, Link, router } from '@inertiajs/react'

import AuthenticatedPage from '@/components/layouts/AuthenticatedPage'

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
  function goToPage(page: number) {
    router.get('/admin/users', { page }, { preserveState: true })
  }

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

        {users.length === 0 ? (
          <p className="mt-8 text-slate-600">No users yet.</p>
        ) : (
          <div className="mt-8 overflow-x-auto rounded-xl border border-slate-200 bg-panel">
            <table className="min-w-full divide-y divide-slate-200 text-left text-sm">
              <thead className="bg-slate-50 text-xs font-semibold uppercase tracking-wide text-slate-500">
                <tr>
                  <th className="px-4 py-3">Name</th>
                  <th className="px-4 py-3">Email</th>
                  <th className="px-4 py-3">Role</th>
                  <th className="px-4 py-3">Status</th>
                  <th className="px-4 py-3">Team</th>
                  <th className="px-4 py-3">Actions</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-100">
                {users.map((user) => (
                  <tr key={user.id} className="text-slate-800">
                    <td className="px-4 py-3 font-medium">{user.name}</td>
                    <td className="px-4 py-3">{user.email}</td>
                    <td className="px-4 py-3 capitalize">{user.role}</td>
                    <td className="px-4 py-3 capitalize">{user.status}</td>
                    <td className="px-4 py-3">{user.team}</td>
                    <td className="px-4 py-3">
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
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}

        {meta.total_pages > 1 && (
          <div className="mt-4 flex items-center justify-between text-sm text-slate-600">
            <p>
              Page {meta.page} of {meta.total_pages} ({meta.total_count} users)
            </p>
            <div className="flex gap-2">
              <button
                type="button"
                disabled={meta.page <= 1}
                onClick={() => goToPage(meta.page - 1)}
                className="inline-flex min-h-11 items-center rounded-lg border border-slate-300 px-3 py-2.5 disabled:opacity-40"
              >
                Previous
              </button>
              <button
                type="button"
                disabled={meta.page >= meta.total_pages}
                onClick={() => goToPage(meta.page + 1)}
                className="inline-flex min-h-11 items-center rounded-lg border border-slate-300 px-3 py-2.5 disabled:opacity-40"
              >
                Next
              </button>
            </div>
          </div>
        )}
      </div>
    </AuthenticatedPage>
  )
}
