import { Head, Link, useForm } from '@inertiajs/react'
import { FormEvent } from 'react'

import UserForm, {
  type UserFormOption,
  type UserFormValues,
} from '@/components/admin/UserForm'
import AuthenticatedPage from '@/components/layouts/AuthenticatedPage'

type AdminUsersNewProps = {
  user: {
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

export default function AdminUsersNew({
  user,
  roles,
  teams,
  countries,
  can_disable: canDisable,
  can_edit_role: canEditRole,
}: AdminUsersNewProps) {
  const form = useForm<UserFormValues>({
    name: user.name || '',
    email: user.email || '',
    role_id: user.role_id ? String(user.role_id) : '',
    team_id: user.team_id ? String(user.team_id) : '',
    country_id: user.country_id ? String(user.country_id) : '',
    status: user.status || 'active',
    password: '',
    send_invite: true,
  })

  function submit(event: FormEvent) {
    event.preventDefault()
    form.post('/admin/users')
  }

  return (
    <AuthenticatedPage>
      <Head title="New user" />

      <div className="mx-auto max-w-2xl">
        <div className="flex items-start justify-between gap-4">
          <div>
            <h1 className="text-2xl font-semibold text-slate-900">New user</h1>
            <p className="mt-1 text-slate-600">
              Onboard a teammate with a role. Invite them by email or set a password yourself.
            </p>
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
          passwordRequired
          showInviteOption
          submitLabel="Create user"
          processingLabel="Saving…"
          onSubmit={submit}
        />
      </div>
    </AuthenticatedPage>
  )
}
