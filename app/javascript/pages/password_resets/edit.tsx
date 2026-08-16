import { Link, useForm } from '@inertiajs/react'

import AuthCard from '@/components/layouts/AuthCard'
import Button from '@/components/ui/Button'

type PasswordResetEditProps = {
  token: string
  email: string
}

export default function PasswordResetEdit({ token, email }: PasswordResetEditProps) {
  const { data, setData, patch, processing, errors } = useForm({
    token,
    password: '',
    password_confirmation: '',
  })

  function submit(event: React.FormEvent) {
    event.preventDefault()
    patch('/password_reset')
  }

  return (
    <AuthCard title="Choose a new password" subtitle={`Resetting password for ${email}`}>
      <form onSubmit={submit} className="space-y-5">
        <input type="hidden" name="token" value={data.token} />

        <div>
          <label htmlFor="password" className="block text-sm font-medium text-slate-700">
            New password
          </label>
          <input
            id="password"
            type="password"
            autoComplete="new-password"
            required
            minLength={8}
            value={data.password}
            onChange={(event) => setData('password', event.target.value)}
            className="mt-1 block w-full rounded-lg border border-slate-300 bg-panel px-3 py-2 text-sm text-slate-900 shadow-sm focus:border-brand focus:outline-none focus:ring-2 focus:ring-brand-muted"
          />
          {errors.password && (
            <p className="mt-2 text-sm text-red-600">{errors.password.join(', ')}</p>
          )}
        </div>

        <div>
          <label htmlFor="password_confirmation" className="block text-sm font-medium text-slate-700">
            Confirm password
          </label>
          <input
            id="password_confirmation"
            type="password"
            autoComplete="new-password"
            required
            minLength={8}
            value={data.password_confirmation}
            onChange={(event) => setData('password_confirmation', event.target.value)}
            className="mt-1 block w-full rounded-lg border border-slate-300 bg-panel px-3 py-2 text-sm text-slate-900 shadow-sm focus:border-brand focus:outline-none focus:ring-2 focus:ring-brand-muted"
          />
          {errors.password_confirmation && (
            <p className="mt-2 text-sm text-red-600">{errors.password_confirmation.join(', ')}</p>
          )}
        </div>

        <Button type="submit" disabled={processing} size="lg" className="w-full">
          {processing ? 'Updating…' : 'Update password'}
        </Button>
      </form>

      <p className="mt-6 text-center text-sm text-slate-600">
        <Link href="/login" className="font-medium text-brand-ink hover:text-brand">
          Back to sign in
        </Link>
      </p>
    </AuthCard>
  )
}
