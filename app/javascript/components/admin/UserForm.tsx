import { FormEvent } from 'react'

import { FormErrorBanner, RequiredFieldsHint, SelectField, TextField } from '@/components/ui/FormFields'

export type UserFormOption = {
  id: number
  name: string
}

export type UserFormValues = {
  name: string
  email: string
  role_id: string
  team_id: string
  country_id: string
  status: string
  password: string
  send_invite?: boolean
}

type UserFormProps = {
  form: {
    data: UserFormValues
    setData: {
      (key: keyof UserFormValues, value: string | boolean): void
    }
    processing: boolean
    errors: Record<string, string | string[] | undefined>
  }
  roles: UserFormOption[]
  teams: UserFormOption[]
  countries: UserFormOption[]
  canDisable: boolean
  canEditRole: boolean
  passwordRequired: boolean
  showInviteOption?: boolean
  submitLabel: string
  processingLabel: string
  onSubmit: (event: FormEvent) => void
}

function fieldError(errors: Record<string, string | string[] | undefined>, key: string): string | null {
  const value = errors[key]
  if (!value) return null
  return Array.isArray(value) ? value.join(', ') : value
}

export default function UserForm({
  form,
  roles,
  teams,
  countries,
  canDisable,
  canEditRole,
  passwordRequired,
  showInviteOption = false,
  submitLabel,
  processingLabel,
  onSubmit,
}: UserFormProps) {
  const { data, setData, processing, errors } = form
  const sendInvite = Boolean(data.send_invite)
  const passwordNeeded = passwordRequired && !sendInvite

  return (
    <form onSubmit={onSubmit} className="mt-8 space-y-5 rounded-xl border border-slate-200 bg-panel p-6">
      <FormErrorBanner message={fieldError(errors, 'base')} />
      <RequiredFieldsHint />

      <TextField
        id="name"
        label="Name"
        required
        value={data.name}
        onChange={(value) => setData('name', value)}
        error={fieldError(errors, 'name')}
      />

      <TextField
        id="email"
        label="Email"
        type="email"
        required
        value={data.email}
        onChange={(value) => setData('email', value)}
        error={fieldError(errors, 'email')}
      />

      <SelectField
        id="role_id"
        label="Role"
        required
        value={data.role_id}
        onChange={(value) => setData('role_id', value)}
        disabled={!canEditRole}
        error={fieldError(errors, 'role_id') || fieldError(errors, 'role')}
      >
        <option value="">Select a role</option>
        {roles.map((role) => (
          <option key={role.id} value={String(role.id)}>
            {role.name}
          </option>
        ))}
      </SelectField>
      {!canEditRole && (
        <p className="-mt-3 text-sm text-slate-500">You cannot change your own admin role.</p>
      )}

      <SelectField
        id="team_id"
        label="Team"
        required
        value={data.team_id}
        onChange={(value) => setData('team_id', value)}
        error={fieldError(errors, 'team_id') || fieldError(errors, 'team')}
      >
        <option value="">Select a team</option>
        {teams.map((team) => (
          <option key={team.id} value={String(team.id)}>
            {team.name}
          </option>
        ))}
      </SelectField>

      <SelectField
        id="country_id"
        label="Country"
        required
        value={data.country_id}
        onChange={(value) => setData('country_id', value)}
        error={fieldError(errors, 'country_id') || fieldError(errors, 'country')}
      >
        <option value="">Select a country</option>
        {countries.map((country) => (
          <option key={country.id} value={String(country.id)}>
            {country.name}
          </option>
        ))}
      </SelectField>

      <SelectField
        id="status"
        label="Status"
        required
        value={data.status}
        onChange={(value) => setData('status', value)}
        disabled={!canDisable && data.status !== 'disabled'}
        error={fieldError(errors, 'status')}
      >
        <option value="active">active</option>
        {canDisable || data.status === 'disabled' ? (
          <option value="disabled">disabled</option>
        ) : null}
      </SelectField>
      {!canDisable && (
        <p className="text-sm text-slate-500">You cannot disable your own account.</p>
      )}

      {showInviteOption && (
        <label className="flex items-start gap-3 rounded-lg border border-slate-200 bg-slate-50 px-3 py-3 text-sm text-slate-700">
          <input
            type="checkbox"
            checked={sendInvite}
            onChange={(event) => setData('send_invite', event.target.checked)}
            className="mt-0.5 h-4 w-4 rounded border-slate-300 text-brand focus:ring-brand"
          />
          <span>
            <span className="font-medium text-slate-900">Send invite email</span>
            <span className="mt-0.5 block text-slate-600">
              Email a link so they can set their own password. You can leave password blank.
            </span>
          </span>
        </label>
      )}

      <TextField
        id="password"
        label={
          passwordNeeded
            ? 'Password'
            : sendInvite
              ? 'Password (optional)'
              : 'Password (leave blank to keep current)'
        }
        type="password"
        required={passwordNeeded}
        minLength={passwordNeeded || data.password.length > 0 ? 8 : undefined}
        autoComplete="new-password"
        value={data.password}
        onChange={(value) => setData('password', value)}
        error={fieldError(errors, 'password')}
      />
      <p className="-mt-3 text-sm text-slate-500">
        {sendInvite
          ? 'Minimum 8 characters if you set a temporary password.'
          : `Minimum 8 characters${passwordNeeded ? '' : ' when changing'}.`}
      </p>

      <button
        type="submit"
        disabled={processing}
        className="inline-flex items-center justify-center rounded-lg bg-brand px-4 py-2 text-sm font-medium text-white hover:bg-brand-hover disabled:cursor-not-allowed disabled:opacity-60"
      >
        {processing ? processingLabel : submitLabel}
      </button>
    </form>
  )
}
