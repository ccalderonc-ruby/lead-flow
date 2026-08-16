import { Link, useForm } from '@inertiajs/react'

import AuthCard from '@/components/layouts/AuthCard'
import Button from '@/components/ui/Button'

export default function PasswordResetNew() {
  const { data, setData, post, processing, errors } = useForm({
    email: '',
  })

  function submit(event: React.FormEvent) {
    event.preventDefault()
    post('/password_reset')
  }

  return (
    <AuthCard title="Forgot password" subtitle="We’ll email you a link to reset your password">
      <form onSubmit={submit} className="space-y-5">
        <div>
          <label htmlFor="email" className="block text-sm font-medium text-slate-700">
            Email
          </label>
          <input
            id="email"
            type="email"
            autoComplete="username"
            required
            value={data.email}
            onChange={(event) => setData('email', event.target.value)}
            className="mt-1 block w-full rounded-lg border border-slate-300 bg-panel px-3 py-2 text-sm text-slate-900 shadow-sm focus:border-brand focus:outline-none focus:ring-2 focus:ring-brand-muted"
          />
          {errors.email && <p className="mt-2 text-sm text-red-600">{errors.email.join(', ')}</p>}
        </div>

        <Button type="submit" disabled={processing} size="lg" className="w-full">
          {processing ? 'Sending…' : 'Send reset link'}
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
