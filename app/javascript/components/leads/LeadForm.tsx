import { Link, usePage } from '@inertiajs/react'
import { FormEvent } from 'react'

import { FieldError, RequiredMark } from '@/components/ui/FormFields'
import type { SharedProps } from '@/types'

export type LeadFormOption = {
  id: number
  name: string
}

export type LeadFormDefaults = {
  user_id: number | null
  force_assignee: boolean
}

export type LeadFormValues = {
  name: string
  email: string
  phone: string
  estimated_value: string
  company_name: string
  company_country_id: string
  update_existing_company_country: boolean
  country_id: string
  stage_id: string
  user_id: string
}

/** Prefer current DOM values so submit works even if React controlled state lagged. */
export function leadFormPayloadFromDom(root: HTMLFormElement, data: LeadFormValues): LeadFormValues {
  const valueOf = (id: string) =>
    (root.querySelector(`#${id}`) as HTMLInputElement | HTMLSelectElement | null)?.value

  const checkbox = root.querySelector('#update_existing_company_country') as HTMLInputElement | null

  return {
    ...data,
    name: valueOf('name') || data.name,
    email: valueOf('email') || data.email,
    phone: valueOf('phone') ?? data.phone,
    estimated_value: valueOf('estimated_value') ?? data.estimated_value,
    company_name: valueOf('company_name') || data.company_name,
    company_country_id: valueOf('company_country_id') || data.company_country_id,
    update_existing_company_country: checkbox ? checkbox.checked : data.update_existing_company_country,
    country_id: valueOf('country_id') || data.country_id,
    stage_id: valueOf('stage_id') || data.stage_id,
    user_id: valueOf('user_id') || data.user_id,
  }
}

type LeadFormProps = {
  // Inertia useForm return — kept loose to avoid version-specific Form generics.
  form: {
    data: LeadFormValues
    setData: (key: keyof LeadFormValues, value: string | boolean) => void
    processing: boolean
    errors: Record<string, string | string[] | undefined>
  }
  countries: LeadFormOption[]
  stages: LeadFormOption[]
  assignees: LeadFormOption[]
  defaults: LeadFormDefaults
  submitLabel: string
  processingLabel: string
  onSubmit: (event: FormEvent) => void
  onCancel?: () => void
  embedded?: boolean
}

function fieldError(errors: Record<string, string | string[] | undefined>, key: string): string | null {
  const value = errors[key]
  if (!value) return null
  return Array.isArray(value) ? value.join(', ') : value
}

const inputClassName =
  'mt-1 block w-full rounded-lg border border-slate-300 px-3 py-2 text-sm text-slate-900 focus:border-brand focus:outline-none focus:ring-2 focus:ring-brand-muted'

const inputErrorClassName =
  'mt-1 block w-full rounded-lg border border-red-300 px-3 py-2 text-sm text-slate-900 focus:border-red-500 focus:outline-none focus:ring-2 focus:ring-red-200'

export default function LeadForm({
  form,
  countries,
  stages,
  assignees,
  defaults,
  submitLabel,
  processingLabel,
  onSubmit,
  onCancel,
  embedded = false,
}: LeadFormProps) {
  const { auth } = usePage<SharedProps>().props
  const { data, setData, processing, errors } = form

  const assigneeLabel =
    defaults.force_assignee && auth.user
      ? auth.user.name
      : null

  return (
    <form
      onSubmit={onSubmit}
      className={
        embedded
          ? 'space-y-5'
          : 'mt-8 space-y-5 rounded-xl border border-slate-200 bg-white p-6'
      }
    >
      {fieldError(errors, 'base') && (
        <p className="rounded-lg border border-red-200 bg-red-50 px-3 py-2 text-sm text-red-700" role="alert">
          {fieldError(errors, 'base')}
        </p>
      )}

      <p className="text-sm text-slate-500">
        Required fields are marked with <RequiredMark />
      </p>

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
          className={fieldError(errors, 'name') ? inputErrorClassName : inputClassName}
          aria-invalid={fieldError(errors, 'name') ? true : undefined}
        />
        <FieldError error={fieldError(errors, 'name')} />
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
          className={inputClassName}
        />
        <FieldError error={fieldError(errors, 'email')} />
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
          className={inputClassName}
        />
        <FieldError error={fieldError(errors, 'phone')} />
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
          className={inputClassName}
        />
        <FieldError error={fieldError(errors, 'company_name')} />
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
          className={inputClassName}
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
            className="mt-0.5 rounded border-slate-300 text-brand-ink focus:ring-brand"
            checked={data.update_existing_company_country}
            onChange={(event) => setData('update_existing_company_country', event.target.checked)}
          />
          <span>
            If this company already exists, update its country to the selection above (otherwise keep the
            existing company country).
          </span>
        </label>
        <FieldError error={fieldError(errors, 'company_country_id')} />
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
          className={inputClassName}
        >
          <option value="">Select country</option>
          {countries.map((country) => (
            <option key={country.id} value={country.id}>
              {country.name}
            </option>
          ))}
        </select>
        <FieldError error={fieldError(errors, 'country')} />
        <FieldError error={fieldError(errors, 'country_id')} />
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
          className={inputClassName}
        >
          <option value="">Select stage</option>
          {stages.map((stage) => (
            <option key={stage.id} value={stage.id}>
              {stage.name}
            </option>
          ))}
        </select>
        <FieldError error={fieldError(errors, 'stage')} />
        <FieldError error={fieldError(errors, 'stage_id')} />
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
            className={inputClassName}
          >
            <option value="">Select user</option>
            {assignees.map((assignee) => (
              <option key={assignee.id} value={assignee.id}>
                {assignee.name}
              </option>
            ))}
          </select>
        )}
        <FieldError error={fieldError(errors, 'user')} />
        <FieldError error={fieldError(errors, 'user_id')} />
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
          className={inputClassName}
        />
        <FieldError error={fieldError(errors, 'estimated_value')} />
      </div>

      <div className="flex justify-end gap-3 pt-2">
        {onCancel ? (
          <button
            type="button"
            onClick={onCancel}
            disabled={processing}
            className="rounded-lg border border-slate-300 px-4 py-2 text-sm font-medium text-slate-700 hover:bg-slate-50 disabled:cursor-not-allowed disabled:opacity-50"
          >
            Cancel
          </button>
        ) : (
          <Link
            href="/leads"
            className="rounded-lg border border-slate-300 px-4 py-2 text-sm font-medium text-slate-700 hover:bg-slate-50"
          >
            Cancel
          </Link>
        )}
        <button
          type="submit"
          disabled={processing}
          className="rounded-lg bg-brand px-4 py-2 text-sm font-medium text-white hover:bg-brand-hover disabled:opacity-50"
        >
          {processing ? processingLabel : submitLabel}
        </button>
      </div>
    </form>
  )
}
