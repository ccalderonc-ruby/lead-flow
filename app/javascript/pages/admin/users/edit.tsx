import { Head, Link, useForm } from '@inertiajs/react'
import { FormEvent } from 'react'

import UserForm, {
  type UserFormOption,
  type UserFormValues,
} from '@/components/admin/UserForm'
import AuthenticatedPage from '@/components/layouts/AuthenticatedPage'

type AdminUsersEditProps = {
  user: {
    id: number
    name: string
    email: string
    role_id: number | null
    team_id: number | null
    country_id: number | null
    status: string
  }
  roles: UserFormOption[]
  teams: UserFormOption[]
  countries: UserFormOption[]
  can_disable: boolean
  can_edit_role: boolean
}

export default function AdminUsersEdit({
  user,
  roles,
  teams,
  countries,
  can_disable: canDisable,
  can_edit_role: canEditRole,
}: AdminUsersEditProps) {
  const form = useForm<UserFormValues>({
    name: user.name || '',
    email: user.email || '',
    role_id: user.role_id ? String(user.role_id) : '',
    team_id: user.team_id ? String(user.team_id) : '',
    country_id: user.country_id ? String(user.country_id) : '',
    status: user.status || 'active',
    password: '',
  })

  function submit(event: FormEvent) {
    event.preventDefault()
    form.put(`/admin/users/${user.id}`)
  }

  return (
    <AuthenticatedPage>
      <Head title={`Edit ${user.name}`} />

      <div className="mx-auto max-w-2xl">
        <div className="flex items-start justify-between gap-4">
          <div>
            <h1 className="text-2xl font-semibold text-slate-900">Edit user</h1>
            <p className="mt-1 text-slate-600">Update role, status, or password.</p>
          </div>
          <Link
            href="/admin/users"
            className="text-sm font-medium text-brand-ink hover:text-brand"
          >
            Back to users
          </Link>
        </div>

        <UserForm
          form={form}
          roles={roles}
          teams={teams}
          countries={countries}
          canDisable={canDisable}
          canEditRole={canEditRole}
          passwordRequired={false}
          submitLabel="Save user"
          processingLabel="Saving…"
          onSubmit={submit}
        />
      </div>
    </AuthenticatedPage>
  )
}
