import { Link, usePage } from '@inertiajs/react'
import { FormEvent } from 'react'

import {
  FieldError,
  FormErrorBanner,
  RequiredFieldsHint,
  RequiredMark,
  SelectField,
  TextField,
} from '@/components/ui/FormFields'
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
          : 'mt-8 space-y-5 rounded-xl border border-slate-200 bg-panel p-6'
      }
    >
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

      <TextField
        id="phone"
        label="Phone"
        type="tel"
        value={data.phone}
        onChange={(value) => setData('phone', value)}
        error={fieldError(errors, 'phone')}
        placeholder="Optional"
      />

      <TextField
        id="company_name"
        label="Company"
        required
        value={data.company_name}
        onChange={(value) => setData('company_name', value)}
        error={fieldError(errors, 'company_name')}
      />

      <div>
        <SelectField
          id="company_country_id"
          label="Company country"
          required
          value={data.company_country_id}
          onChange={(value) => setData('company_country_id', value)}
          error={fieldError(errors, 'company_country_id')}
        >
          <option value="">Select country</option>
          {countries.map((country) => (
            <option key={country.id} value={country.id}>
              {country.name}
            </option>
          ))}
        </SelectField>
        <label className="mt-2 flex items-start gap-2 text-sm text-slate-600">
          <input
            type="checkbox"
            id="update_existing_company_country"
            className="mt-0.5 rounded border-slate-300 text-brand-ink focus:ring-brand"
            checked={data.update_existing_company_country}
            onChange={(event) => setData('update_existing_company_country', event.target.checked)}
          />
          <span>
            If this company already exists, update its country to the selection above (otherwise keep the
            existing company country).
          </span>
        </label>
      </div>

      <SelectField
        id="country_id"
        label="Lead country"
        required
        value={data.country_id}
        onChange={(value) => setData('country_id', value)}
        error={fieldError(errors, 'country') || fieldError(errors, 'country_id')}
      >
        <option value="">Select country</option>
        {countries.map((country) => (
          <option key={country.id} value={country.id}>
            {country.name}
          </option>
        ))}
      </SelectField>

      <SelectField
        id="stage_id"
        label="Stage"
        required
        value={data.stage_id}
        onChange={(value) => setData('stage_id', value)}
        error={fieldError(errors, 'stage') || fieldError(errors, 'stage_id')}
      >
        <option value="">Select stage</option>
        {stages.map((stage) => (
          <option key={stage.id} value={stage.id}>
            {stage.name}
          </option>
        ))}
      </SelectField>

      {defaults.force_assignee ? (
        <div>
          <p className="block text-sm font-medium text-slate-700">
            Assigned user <RequiredMark />
          </p>
          <p className="mt-1 rounded-lg border border-slate-200 bg-slate-50 px-3 py-2 text-sm text-slate-700">
            {assigneeLabel}
          </p>
          <FieldError error={fieldError(errors, 'user') || fieldError(errors, 'user_id')} />
        </div>
      ) : (
        <SelectField
          id="user_id"
          label="Assigned user"
          required
          value={data.user_id}
          onChange={(value) => setData('user_id', value)}
          error={fieldError(errors, 'user') || fieldError(errors, 'user_id')}
        >
          <option value="">Select user</option>
          {assignees.map((assignee) => (
            <option key={assignee.id} value={assignee.id}>
              {assignee.name}
            </option>
          ))}
        </SelectField>
      )}

      <TextField
        id="estimated_value"
        label="Estimated value"
        type="number"
        value={data.estimated_value}
        onChange={(value) => setData('estimated_value', value)}
        error={fieldError(errors, 'estimated_value')}
        placeholder="Optional"
        min={0}
        step={1}
      />

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
