import { Head, router } from '@inertiajs/react'
import { useState } from 'react'

import AuthenticatedPage from '@/components/layouts/AuthenticatedPage'
import PaginationBar, { type PaginationMeta } from '@/components/ui/PaginationBar'
import {
  DataTable,
  DataTableBody,
  DataTableCell,
  DataTableEmpty,
  DataTableHead,
  DataTableHeaderCell,
  DataTableRow,
} from '@/components/ui/DataTable'

export type BillingProps = {
  subscription_status: string
  billing_active: boolean
  cancel_at_period_end: boolean
  current_period_end: string | null
  stripe_customer_id: string | null
  stripe_subscription_id: string | null
}

export type MemberSubscriptionRow = {
  id: number
  name: string
  email: string
  role: string
  pro_access: boolean
  subscribed: boolean
  is_billing_admin: boolean
}

function isBillingAdminRole(role: string) {
  return role === 'billing_admin'
}

function formatPeriodEnd(iso: string | null) {
  if (!iso) return null
  const date = new Date(iso)
  if (Number.isNaN(date.getTime())) return null
  return date.toLocaleDateString(undefined, {
    year: 'numeric',
    month: 'long',
    day: 'numeric',
  })
}

type AdminSubscriptionsIndexProps = {
  billing: BillingProps
  members: MemberSubscriptionRow[]
  meta: PaginationMeta
  show_grant_all: boolean
  checkout_configured: boolean
}

export default function AdminSubscriptionsIndex({
  billing,
  members,
  meta,
  show_grant_all: showGrantAll,
  checkout_configured: checkoutConfigured,
}: AdminSubscriptionsIndexProps) {
  const [startingCheckout, setStartingCheckout] = useState(false)
  const [busyUserId, setBusyUserId] = useState<number | null>(null)
  const [grantingAll, setGrantingAll] = useState(false)
  const [canceling, setCanceling] = useState(false)
  const [resuming, setResuming] = useState(false)

  const periodEndLabel = formatPeriodEnd(billing.current_period_end)

  function startCheckout() {
    if (startingCheckout) return
    setStartingCheckout(true)
    router.post(
      '/admin/subscriptions',
      {},
      {
        onFinish: () => setStartingCheckout(false),
      },
    )
  }

  function cancelSubscription() {
    if (canceling) return
    const confirmed = window.confirm(
      periodEndLabel
        ? `Cancel LeadFlow Pro? Access stays active until ${periodEndLabel}.`
        : 'Cancel LeadFlow Pro? Access stays active until the end of the current billing period.',
    )
    if (!confirmed) return

    setCanceling(true)
    router.post(
      '/admin/subscriptions/cancel',
      {},
      {
        onFinish: () => setCanceling(false),
      },
    )
  }

  function resumeSubscription() {
    if (resuming) return
    setResuming(true)
    router.post(
      '/admin/subscriptions/resume',
      {},
      {
        onFinish: () => setResuming(false),
      },
    )
  }

  function setMemberAccess(userId: number, proAccess: boolean) {
    if (busyUserId != null) return
    setBusyUserId(userId)
    router.patch(
      '/admin/subscriptions/access',
      { user_id: userId, pro_access: proAccess },
      {
        onFinish: () => setBusyUserId(null),
      },
    )
  }

  function grantAll() {
    if (grantingAll) return
    setGrantingAll(true)
    router.post(
      '/admin/subscriptions/grant_all',
      {},
      {
        onFinish: () => setGrantingAll(false),
      },
    )
  }

  return (
    <AuthenticatedPage>
      <Head title="Subscriptions" />

      <div>
        <div>
          <h1 className="text-2xl font-semibold text-slate-900">Subscriptions</h1>
          <p className="mt-1 text-slate-600">
            As billing admin you subscribe the organization to LeadFlow Pro, then grant Pro access to
            admins, advisors, and assistants.
          </p>
        </div>

        {!checkoutConfigured && (
          <p className="mt-6 rounded-lg bg-amber-50 px-4 py-3 text-sm text-amber-900">
            Stripe is not configured. Set STRIPE_SECRET_KEY, STRIPE_PRICE_ID, and
            STRIPE_WEBHOOK_SECRET (see .env.example) to enable checkout.
          </p>
        )}

        <section className="mt-8 rounded-xl border border-slate-200 bg-panel p-6">
          <div className="flex flex-col gap-4 sm:flex-row sm:items-start sm:justify-between">
            <div>
              <h2 className="text-lg font-semibold text-slate-900">Organization billing</h2>
              <p className="mt-1 text-sm text-slate-600">
                Status:{' '}
                <span className="font-medium capitalize text-slate-900">
                  {billing.subscription_status}
                </span>
              </p>
              {billing.billing_active && billing.cancel_at_period_end && (
                <p className="mt-2 text-sm text-amber-800">
                  Cancellation scheduled
                  {periodEndLabel ? `. Pro access remains until ${periodEndLabel}.` : ' at period end.'}
                </p>
              )}
              {billing.billing_active && !billing.cancel_at_period_end && periodEndLabel && (
                <p className="mt-2 text-sm text-slate-500">Current period ends {periodEndLabel}.</p>
              )}
            </div>

            <div className="flex flex-col items-stretch gap-2 sm:items-end">
              {billing.billing_active ? (
                <>
                  <span className="inline-flex rounded-full bg-green-50 px-3 py-1 text-sm font-medium text-green-800">
                    LeadFlow Pro active
                  </span>
                  {billing.cancel_at_period_end ? (
                    <button
                      type="button"
                      disabled={!checkoutConfigured || resuming}
                      onClick={resumeSubscription}
                      className="text-sm font-medium text-brand-ink hover:text-brand disabled:opacity-50"
                    >
                      {resuming ? 'Resuming…' : 'Keep subscription'}
                    </button>
                  ) : (
                    <button
                      type="button"
                      disabled={!checkoutConfigured || canceling}
                      onClick={cancelSubscription}
                      className="text-sm font-medium text-slate-600 hover:text-slate-900 disabled:opacity-50"
                    >
                      {canceling ? 'Canceling…' : 'Cancel subscription'}
                    </button>
                  )}
                </>
              ) : (
                <button
                  type="button"
                  disabled={!checkoutConfigured || startingCheckout}
                  onClick={startCheckout}
                  className="inline-flex items-center justify-center rounded-lg bg-brand px-4 py-2 text-sm font-medium text-white hover:bg-brand-hover disabled:cursor-not-allowed disabled:opacity-50"
                >
                  {startingCheckout ? 'Starting…' : 'Subscribe with Stripe'}
                </button>
              )}
            </div>
          </div>
        </section>

        <section className="mt-8">
          <div className="flex flex-col gap-3 sm:flex-row sm:items-end sm:justify-between">
            <div>
              <h2 className="text-lg font-semibold text-slate-900">Team access</h2>
              <p className="mt-1 text-sm text-slate-600">
                Grant Pro features to users after the organization is subscribed.
              </p>
            </div>
            {showGrantAll && (
              <button
                type="button"
                disabled={grantingAll}
                onClick={grantAll}
                className="text-sm font-medium text-brand-ink hover:text-brand disabled:opacity-50"
              >
                {grantingAll ? 'Granting…' : 'Grant access to everyone'}
              </button>
            )}
          </div>

          <DataTable className="mt-4">
            <DataTableHead>
              <tr>
                <DataTableHeaderCell>Name</DataTableHeaderCell>
                <DataTableHeaderCell>Role</DataTableHeaderCell>
                <DataTableHeaderCell>Access</DataTableHeaderCell>
                <DataTableHeaderCell align="right">Actions</DataTableHeaderCell>
              </tr>
            </DataTableHead>
            <DataTableBody>
              {members.length === 0 ? (
                <DataTableEmpty colSpan={4}>
                  <p className="px-6 py-12 text-center text-slate-600">No team members yet.</p>
                </DataTableEmpty>
              ) : (
                members.map((member) => (
                  <DataTableRow key={member.id} hover={false} className="text-slate-800">
                    <DataTableCell>
                      <div className="font-medium">{member.name}</div>
                      <div className="text-slate-500">{member.email}</div>
                    </DataTableCell>
                    <DataTableCell className="capitalize">
                      {member.role === 'billing_admin' ? 'Billing admin' : member.role}
                    </DataTableCell>
                    <DataTableCell>
                      <span
                        className={`inline-flex rounded-full px-2.5 py-0.5 text-xs font-medium ${
                          member.subscribed
                            ? 'bg-green-50 text-green-800'
                            : 'bg-slate-100 text-slate-700'
                        }`}
                      >
                        {member.subscribed ? 'Pro' : 'No access'}
                      </span>
                    </DataTableCell>
                    <DataTableCell align="right">
                      {isBillingAdminRole(member.role) ? (
                        <span className="text-sm text-slate-500">Billing admin</span>
                      ) : !billing.billing_active ? (
                        <span className="text-sm text-slate-500">Subscribe first</span>
                      ) : member.pro_access ? (
                        <button
                          type="button"
                          disabled={busyUserId === member.id}
                          onClick={() => setMemberAccess(member.id, false)}
                          className="text-sm font-medium text-slate-600 hover:text-slate-900 disabled:opacity-50"
                        >
                          {busyUserId === member.id ? 'Updating…' : 'Revoke'}
                        </button>
                      ) : (
                        <button
                          type="button"
                          disabled={busyUserId === member.id}
                          onClick={() => setMemberAccess(member.id, true)}
                          className="text-sm font-medium text-brand-ink hover:text-brand disabled:opacity-50"
                        >
                          {busyUserId === member.id ? 'Updating…' : 'Grant access'}
                        </button>
                      )}
                    </DataTableCell>
                  </DataTableRow>
                ))
              )}
            </DataTableBody>
          </DataTable>

          <PaginationBar meta={meta} path="/admin/subscriptions" label="members" />
        </section>
      </div>
    </AuthenticatedPage>
  )
}
