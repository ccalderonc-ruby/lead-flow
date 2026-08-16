import { useForm } from '@inertiajs/react'
import { FormEvent, useRef } from 'react'

import LeadForm, {
  leadFormPayloadFromDom,
  type LeadFormDefaults,
  type LeadFormOption,
  type LeadFormValues,
} from '@/components/leads/LeadForm'
import { useDialogA11y } from '@/hooks/useDialogA11y'

type LeadFormModalProps = {
  open: boolean
  onClose: () => void
  countries: LeadFormOption[]
  stages: LeadFormOption[]
  assignees: LeadFormOption[]
  defaults: LeadFormDefaults
  returnTo: string
}

export default function LeadFormModal({
  open,
  onClose,
  countries,
  stages,
  assignees,
  defaults,
  returnTo,
}: LeadFormModalProps) {
  const form = useForm<LeadFormValues & { return_to: string }>({
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
    return_to: returnTo,
  })
  const dialogRef = useRef<HTMLDivElement>(null)

  function resetForm() {
    form.setData({
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
      return_to: returnTo,
    })
    form.clearErrors()
  }

  function handleClose() {
    if (form.processing) return
    resetForm()
    onClose()
  }

  useDialogA11y({ open, onClose: handleClose, containerRef: dialogRef })

  if (!open) return null

  function submit(event: FormEvent) {
    event.preventDefault()
    const root = event.currentTarget as HTMLFormElement
    form.transform((data) => ({
      ...leadFormPayloadFromDom(root, data),
      return_to: returnTo,
    }))
    form.post('/leads', {
      preserveScroll: true,
      onSuccess: () => {
        resetForm()
        onClose()
      },
      onFinish: () => {
        form.transform((data) => data)
      },
    })
  }

  return (
    <div ref={dialogRef} className="fixed inset-0 z-50 flex items-center justify-center bg-slate-900/40 p-4">
      <div
        role="dialog"
        aria-modal="true"
        aria-labelledby="lead-form-title"
        className="max-h-[min(90dvh,90vh)] w-full max-w-2xl overflow-y-auto rounded-xl bg-panel p-6 shadow-xl"
      >
        <h2 id="lead-form-title" className="text-lg font-semibold text-slate-900">
          New lead
        </h2>
        <p className="mt-1 text-sm text-slate-600">Add a prospect to the pipeline.</p>

        <div className="mt-6">
          <LeadForm
            form={form}
            countries={countries}
            stages={stages}
            assignees={assignees}
            defaults={defaults}
            submitLabel="Create lead"
            processingLabel="Saving…"
            onSubmit={submit}
            onCancel={handleClose}
            embedded
          />
        </div>
      </div>
    </div>
  )
}
