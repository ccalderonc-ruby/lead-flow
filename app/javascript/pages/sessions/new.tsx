import { Head, Link, useForm, usePage } from '@inertiajs/react'

import Button from '@/components/ui/Button'
import Card from '@/components/ui/Card'
import FlashBanner from '@/components/ui/FlashBanner'
import ThemeToggle from '@/components/ui/ThemeToggle'
import type { SharedProps } from '@/types'

export default function Login() {
  const { flash } = usePage<SharedProps>().props
  const { data, setData, post, processing, errors } = useForm({
    email: '',
    password: '',
  })

  function submit(event: React.FormEvent) {
    event.preventDefault()
    post('/session')
  }

  return (
    <div className="relative flex min-h-screen items-center justify-center bg-surface px-4">
      <Head title="Sign in" />
      <div className="absolute right-4 top-4">
        <ThemeToggle />
      </div>

      <Card className="w-full max-w-md p-8" padding="none">
        <div className="mb-6 text-center">
          <h1 className="text-2xl font-semibold text-ink">LeadFlow</h1>
          <p className="mt-2 text-sm text-slate-600">Sign in to your account</p>
        </div>

        <FlashBanner notice={flash?.notice} alert={flash?.alert} />

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
              className="mt-1 block w-full rounded-lg border border-slate-300 bg-panel px-3 py-2 text-sm text-slate-900 shadow-sm focus:border-brand focus:outline-none focus:ring-2 focus:ring-brand-muted"
            />
            {errors.email && (
              <p className="mt-2 text-sm text-red-600">{errors.email.join(', ')}</p>
            )}
          </div>

          <div>
            <div className="flex items-center justify-between gap-3">
              <label htmlFor="password" className="block text-sm font-medium text-slate-700">
                Password
              </label>
              <Link
                href="/forgot-password"
                className="text-sm font-medium text-brand-ink hover:text-brand"
              >
                Forgot password?
              </Link>
            </div>
            <input
              id="password"
              type="password"
              autoComplete="current-password"
              value={data.password}
              onChange={(event) => setData('password', event.target.value)}
              className="mt-1 block w-full rounded-lg border border-slate-300 bg-panel px-3 py-2 text-sm text-slate-900 shadow-sm focus:border-brand focus:outline-none focus:ring-2 focus:ring-brand-muted"
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
