import { Head, Link, useForm } from '@inertiajs/react'
import { FormEvent } from 'react'

import LeadForm, {
  leadFormPayloadFromDom,
  type LeadFormDefaults,
  type LeadFormOption,
  type LeadFormValues,
} from '@/components/leads/LeadForm'
import AuthenticatedPage from '@/components/layouts/AuthenticatedPage'

type LeadsNewProps = {
  countries: LeadFormOption[]
  stages: LeadFormOption[]
  assignees: LeadFormOption[]
  defaults: LeadFormDefaults
}

export default function LeadsNew({ countries, stages, assignees, defaults }: LeadsNewProps) {
  const form = useForm<LeadFormValues>({
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
    const root = event.currentTarget as HTMLFormElement
    form.transform((data) => leadFormPayloadFromDom(root, data))
    form.post('/leads', {
      onFinish: () => {
        form.transform((data) => data)
      },
    })
  }

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

        <LeadForm
          form={form}
          countries={countries}
          stages={stages}
          assignees={assignees}
          defaults={defaults}
          submitLabel="Create lead"
          processingLabel="Saving…"
          onSubmit={submit}
        />
      </div>
    </AuthenticatedPage>
  )
}
