import { Head, Link, useForm } from '@inertiajs/react'
import { FormEvent } from 'react'

import LeadForm, {
  leadFormPayloadFromDom,
  type LeadFormDefaults,
  type LeadFormOption,
  type LeadFormValues,
} from '@/components/leads/LeadForm'
import AuthenticatedPage from '@/components/layouts/AuthenticatedPage'

type LeadEditRecord = {
  id: number
  name: string
  email: string
  phone: string | null
  estimated_value: string | number | null
  country_id: number | null
  stage_id: number | null
  user_id: number | null
  company_name: string
  company_country_id: number | null
}

type LeadsEditProps = {
  lead: LeadEditRecord
  countries: LeadFormOption[]
  stages: LeadFormOption[]
  assignees: LeadFormOption[]
  defaults: LeadFormDefaults
}

function LeadEditForm({ lead, countries, stages, assignees, defaults }: LeadsEditProps) {
  const form = useForm<LeadFormValues>({
    name: lead.name ?? '',
    email: lead.email ?? '',
    phone: lead.phone ?? '',
    estimated_value: lead.estimated_value != null ? String(lead.estimated_value) : '',
    company_name: lead.company_name ?? '',
    company_country_id: lead.company_country_id != null ? String(lead.company_country_id) : '',
    update_existing_company_country: false,
    country_id: lead.country_id != null ? String(lead.country_id) : '',
    stage_id: lead.stage_id != null ? String(lead.stage_id) : '',
    user_id: lead.user_id != null ? String(lead.user_id) : defaults.user_id ? String(defaults.user_id) : '',
  })

  function submit(event: FormEvent) {
    event.preventDefault()
    const root = event.currentTarget as HTMLFormElement
    form.transform((data) => leadFormPayloadFromDom(root, data))
    form.put(`/leads/${lead.id}`, {
      onFinish: () => {
        form.transform((data) => data)
      },
    })
  }

  return (
    <LeadForm
      form={form}
      countries={countries}
      stages={stages}
      assignees={assignees}
      defaults={defaults}
      submitLabel="Save changes"
      processingLabel="Saving…"
      onSubmit={submit}
    />
  )
}

export default function LeadsEdit(props: LeadsEditProps) {
  const { lead } = props

  return (
    <AuthenticatedPage>
      <Head title={`Edit ${lead.name}`} />

      <div className="mx-auto max-w-2xl">
        <div className="flex items-start justify-between gap-4">
          <div>
            <h1 className="text-2xl font-semibold text-slate-900">Edit lead</h1>
            <p className="mt-1 text-slate-600">Update prospect details and assignment.</p>
          </div>
          <Link href="/leads" className="text-sm font-medium text-brand-ink hover:text-brand">
            Back to leads
          </Link>
        </div>

        <LeadEditForm key={lead.id} {...props} />
      </div>
    </AuthenticatedPage>
  )
}
