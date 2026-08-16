import { Head, useForm } from '@inertiajs/react'

import Button from '@/components/ui/Button'
import Card from '@/components/ui/Card'

export default function Login() {
  const { data, setData, post, processing, errors } = useForm({
    email: '',
    password: '',
  })

  function submit(event: React.FormEvent) {
    event.preventDefault()
    post('/session')
  }

  return (
    <div className="flex min-h-screen items-center justify-center bg-surface px-4">
      <Head title="Sign in" />

      <Card className="w-full max-w-md p-8" padding="none">
        <div className="mb-8 text-center">
          <h1 className="text-2xl font-semibold text-ink">LeadFlow</h1>
          <p className="mt-2 text-sm text-slate-600">Sign in to your account</p>
        </div>

        <form onSubmit={submit} className="space-y-5">
          <div>
            <label htmlFor="email" className="block text-sm font-medium text-slate-700">
              Email
            </label>
            <input
              id="email"
              type="email"
              autoComplete="username"
              value={data.email}
              onChange={(event) => setData('email', event.target.value)}
              className="mt-1 block w-full rounded-lg border-slate-300 shadow-sm focus:border-brand focus:outline-none focus:ring-2 focus:ring-brand-muted"
            />
            {errors.email && (
              <p className="mt-2 text-sm text-red-600">{errors.email.join(', ')}</p>
            )}
          </div>

          <div>
            <label htmlFor="password" className="block text-sm font-medium text-slate-700">
              Password
            </label>
            <input
              id="password"
              type="password"
              autoComplete="current-password"
              value={data.password}
              onChange={(event) => setData('password', event.target.value)}
              className="mt-1 block w-full rounded-lg border-slate-300 shadow-sm focus:border-brand focus:outline-none focus:ring-2 focus:ring-brand-muted"
            />
          </div>

          <Button type="submit" disabled={processing} size="lg" className="w-full">
            {processing ? 'Signing in…' : 'Sign in'}
          </Button>
        </form>
      </Card>
    </div>
  )
}
