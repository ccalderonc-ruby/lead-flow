import { Head, Link, useForm, usePage } from '@inertiajs/react'
import { FormEvent } from 'react'

import AuthenticatedPage from '@/components/layouts/AuthenticatedPage'
import type { SharedProps } from '@/types'

type Option = {
  id: number
  name: string
}

type LeadsNewProps = {
  countries: Option[]
  stages: Option[]
  assignees: Option[]
  defaults: {
    user_id: number | null
    force_assignee: boolean
  }
}

function fieldError(errors: Record<string, string | string[] | undefined>, key: string): string | null {
  const value = errors[key]
  if (!value) return null
  return Array.isArray(value) ? value.join(', ') : value
}

function RequiredMark() {
  return <span className="text-red-600"> *</span>
}

export default function LeadsNew({ countries, stages, assignees, defaults }: LeadsNewProps) {
  const { auth } = usePage<SharedProps>().props
  const { data, setData, post, processing, errors } = useForm({
    name: '',
    email: '',
    phone: '',
    estimated_value: '',
    company_name: '',
    company_country_id: '',
    update_existing_company_country: false,
    country_id: '',
    stage_id: '',
    user_id: defaults.user_id ? String(defaults.user_id) : '',
  })

  function submit(event: FormEvent) {
    event.preventDefault()
    post('/leads')
  }

  const assigneeLabel =
    defaults.force_assignee && auth.user
      ? auth.user.name
      : null

  return (
    <AuthenticatedPage>
      <Head title="New lead" />

      <div className="mx-auto max-w-2xl">
        <div className="flex items-start justify-between gap-4">
          <div>
            <h1 className="text-2xl font-semibold text-slate-900">New lead</h1>
            <p className="mt-1 text-slate-600">Add a prospect to the pipeline.</p>
          </div>
          <Link href="/leads" className="text-sm font-medium text-indigo-600 hover:text-indigo-500">
            Back to leads
          </Link>
        </div>

        <form onSubmit={submit} className="mt-8 space-y-5 rounded-xl border border-slate-200 bg-white p-6">
          {fieldError(errors, 'base') && (
            <p className="rounded-lg border border-red-200 bg-red-50 px-3 py-2 text-sm text-red-700">
              {fieldError(errors, 'base')}
            </p>
          )}

          <div>
            <label htmlFor="name" className="block text-sm font-medium text-slate-700">
              Name
              <RequiredMark />
            </label>
            <input
              id="name"
              type="text"
              required
              value={data.name}
              onChange={(event) => setData('name', event.target.value)}
              className="mt-1 block w-full rounded-lg border border-slate-300 px-3 py-2 text-sm text-slate-900 focus:border-indigo-500 focus:outline-none focus:ring-2 focus:ring-indigo-200"
            />
            {fieldError(errors, 'name') && (
              <p className="mt-1 text-sm text-red-600">{fieldError(errors, 'name')}</p>
            )}
          </div>

          <div>
            <label htmlFor="email" className="block text-sm font-medium text-slate-700">
              Email
              <RequiredMark />
            </label>
            <input
              id="email"
              type="email"
              required
              value={data.email}
              onChange={(event) => setData('email', event.target.value)}
              className="mt-1 block w-full rounded-lg border border-slate-300 px-3 py-2 text-sm text-slate-900 focus:border-indigo-500 focus:outline-none focus:ring-2 focus:ring-indigo-200"
            />
            {fieldError(errors, 'email') && (
              <p className="mt-1 text-sm text-red-600">{fieldError(errors, 'email')}</p>
            )}
          </div>

          <div>
            <label htmlFor="phone" className="block text-sm font-medium text-slate-700">
              Phone <span className="font-normal text-slate-400">(optional)</span>
            </label>
            <input
              id="phone"
              type="tel"
              value={data.phone}
              onChange={(event) => setData('phone', event.target.value)}
              className="mt-1 block w-full rounded-lg border border-slate-300 px-3 py-2 text-sm text-slate-900 focus:border-indigo-500 focus:outline-none focus:ring-2 focus:ring-indigo-200"
            />
            {fieldError(errors, 'phone') && (
              <p className="mt-1 text-sm text-red-600">{fieldError(errors, 'phone')}</p>
            )}
          </div>

          <div>
            <label htmlFor="company_name" className="block text-sm font-medium text-slate-700">
              Company
              <RequiredMark />
            </label>
            <input
              id="company_name"
              type="text"
              required
              value={data.company_name}
              onChange={(event) => setData('company_name', event.target.value)}
              className="mt-1 block w-full rounded-lg border border-slate-300 px-3 py-2 text-sm text-slate-900 focus:border-indigo-500 focus:outline-none focus:ring-2 focus:ring-indigo-200"
            />
            {fieldError(errors, 'company_name') && (
              <p className="mt-1 text-sm text-red-600">{fieldError(errors, 'company_name')}</p>
            )}
          </div>

          <div>
            <label htmlFor="company_country_id" className="block text-sm font-medium text-slate-700">
              Company country
              <RequiredMark />
            </label>
            <select
              id="company_country_id"
              required
              value={data.company_country_id}
              onChange={(event) => setData('company_country_id', event.target.value)}
              className="mt-1 block w-full rounded-lg border border-slate-300 px-3 py-2 text-sm text-slate-900 focus:border-indigo-500 focus:outline-none focus:ring-2 focus:ring-indigo-200"
            >
              <option value="">Select country</option>
              {countries.map((country) => (
                <option key={country.id} value={country.id}>
                  {country.name}
                </option>
              ))}
            </select>
            <label className="mt-2 flex items-start gap-2 text-sm text-slate-600">
              <input
                type="checkbox"
                className="mt-0.5 rounded border-slate-300 text-indigo-600 focus:ring-indigo-500"
                checked={data.update_existing_company_country}
                onChange={(event) => setData('update_existing_company_country', event.target.checked)}
              />
              <span>
                If this company already exists, update its country to the selection above (otherwise keep
                the existing company country).
              </span>
            </label>
            {fieldError(errors, 'company_country_id') && (
              <p className="mt-1 text-sm text-red-600">{fieldError(errors, 'company_country_id')}</p>
            )}
          </div>

          <div>
            <label htmlFor="country_id" className="block text-sm font-medium text-slate-700">
              Lead country
              <RequiredMark />
            </label>
            <select
              id="country_id"
              required
              value={data.country_id}
              onChange={(event) => setData('country_id', event.target.value)}
              className="mt-1 block w-full rounded-lg border border-slate-300 px-3 py-2 text-sm text-slate-900 focus:border-indigo-500 focus:outline-none focus:ring-2 focus:ring-indigo-200"
            >
              <option value="">Select country</option>
              {countries.map((country) => (
                <option key={country.id} value={country.id}>
                  {country.name}
                </option>
              ))}
            </select>
            {fieldError(errors, 'country') && (
              <p className="mt-1 text-sm text-red-600">{fieldError(errors, 'country')}</p>
            )}
            {fieldError(errors, 'country_id') && (
              <p className="mt-1 text-sm text-red-600">{fieldError(errors, 'country_id')}</p>
            )}
          </div>

          <div>
            <label htmlFor="stage_id" className="block text-sm font-medium text-slate-700">
              Stage
              <RequiredMark />
            </label>
            <select
              id="stage_id"
              required
              value={data.stage_id}
              onChange={(event) => setData('stage_id', event.target.value)}
              className="mt-1 block w-full rounded-lg border border-slate-300 px-3 py-2 text-sm text-slate-900 focus:border-indigo-500 focus:outline-none focus:ring-2 focus:ring-indigo-200"
            >
              <option value="">Select stage</option>
              {stages.map((stage) => (
                <option key={stage.id} value={stage.id}>
                  {stage.name}
                </option>
              ))}
            </select>
            {fieldError(errors, 'stage') && (
              <p className="mt-1 text-sm text-red-600">{fieldError(errors, 'stage')}</p>
            )}
            {fieldError(errors, 'stage_id') && (
              <p className="mt-1 text-sm text-red-600">{fieldError(errors, 'stage_id')}</p>
            )}
          </div>

          <div>
            <label htmlFor="user_id" className="block text-sm font-medium text-slate-700">
              Assigned user
              <RequiredMark />
            </label>
            {defaults.force_assignee ? (
              <p className="mt-1 rounded-lg border border-slate-200 bg-slate-50 px-3 py-2 text-sm text-slate-700">
                {assigneeLabel}
              </p>
            ) : (
              <select
                id="user_id"
                required
                value={data.user_id}
                onChange={(event) => setData('user_id', event.target.value)}
                className="mt-1 block w-full rounded-lg border border-slate-300 px-3 py-2 text-sm text-slate-900 focus:border-indigo-500 focus:outline-none focus:ring-2 focus:ring-indigo-200"
              >
                <option value="">Select user</option>
                {assignees.map((assignee) => (
                  <option key={assignee.id} value={assignee.id}>
                    {assignee.name}
                  </option>
                ))}
              </select>
            )}
            {fieldError(errors, 'user') && (
              <p className="mt-1 text-sm text-red-600">{fieldError(errors, 'user')}</p>
            )}
            {fieldError(errors, 'user_id') && (
              <p className="mt-1 text-sm text-red-600">{fieldError(errors, 'user_id')}</p>
            )}
          </div>

          <div>
            <label htmlFor="estimated_value" className="block text-sm font-medium text-slate-700">
              Estimated value <span className="font-normal text-slate-400">(optional)</span>
            </label>
            <input
              id="estimated_value"
              type="number"
              min="0"
              step="1"
              value={data.estimated_value}
              onChange={(event) => setData('estimated_value', event.target.value)}
              className="mt-1 block w-full rounded-lg border border-slate-300 px-3 py-2 text-sm text-slate-900 focus:border-indigo-500 focus:outline-none focus:ring-2 focus:ring-indigo-200"
            />
            {fieldError(errors, 'estimated_value') && (
              <p className="mt-1 text-sm text-red-600">{fieldError(errors, 'estimated_value')}</p>
            )}
          </div>

          <div className="flex justify-end gap-3 pt-2">
            <Link
              href="/leads"
              className="rounded-lg border border-slate-300 px-4 py-2 text-sm font-medium text-slate-700 hover:bg-slate-50"
            >
              Cancel
            </Link>
            <button
              type="submit"
              disabled={processing}
              className="rounded-lg bg-indigo-600 px-4 py-2 text-sm font-medium text-white hover:bg-indigo-500 disabled:opacity-50"
            >
              {processing ? 'Saving…' : 'Create lead'}
            </button>
          </div>
        </form>
      </div>
    </AuthenticatedPage>
  )
}
