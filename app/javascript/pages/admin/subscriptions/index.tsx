import { Head, router, usePage } from '@inertiajs/react'
import { useState } from 'react'

import AuthenticatedPage from '@/components/layouts/AuthenticatedPage'

export type AdvisorSubscriptionRow = {
  id: number
  name: string
  email: string
  subscription_status: string
  subscribed: boolean
  stripe_customer_id: string | null
}

type AdminSubscriptionsIndexProps = {
  advisors: AdvisorSubscriptionRow[]
  checkout_configured: boolean
  focused_user_id: number | null
}

export default function AdminSubscriptionsIndex({
  advisors,
  checkout_configured: checkoutConfigured,
  focused_user_id: focusedUserId,
}: AdminSubscriptionsIndexProps) {
  const { url } = usePage()
  const checkoutParam = new URLSearchParams(url.split('?')[1] || '').get('checkout')
  const [startingForId, setStartingForId] = useState<number | null>(null)

  const focusedAdvisor =
    focusedUserId != null ? advisors.find((advisor) => advisor.id === focusedUserId) : null
  const activationPending =
    checkoutParam === 'success' && focusedAdvisor != null && !focusedAdvisor.subscribed

  function startCheckout(userId: number) {
    if (startingForId != null) return
    setStartingForId(userId)
    router.post(
      '/admin/subscriptions',
      { user_id: userId },
      {
        onFinish: () => setStartingForId(null),
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
            Manage LeadFlow Pro for advisors. CSV export unlocks when an advisor is subscribed.
          </p>
        </div>

        {!checkoutConfigured && (
          <p className="mt-6 rounded-lg bg-amber-50 px-4 py-3 text-sm text-amber-900">
            Stripe is not configured. Set STRIPE_SECRET_KEY, STRIPE_PRICE_ID, and
            STRIPE_WEBHOOK_SECRET (see .env.example) to enable checkout.
          </p>
        )}

        {activationPending && (
          <p className="mt-6 rounded-lg bg-sky-50 px-4 py-3 text-sm text-sky-900">
            Payment received for {focusedAdvisor.name}. Waiting for Stripe to confirm — status
            updates when the webhook arrives.
          </p>
        )}

        {advisors.length === 0 ? (
          <p className="mt-8 text-slate-600">No advisors yet.</p>
        ) : (
          <div className="mt-8 overflow-x-auto rounded-xl border border-slate-200 bg-white">
            <table className="min-w-full divide-y divide-slate-200 text-left text-sm">
              <thead className="bg-slate-50 text-xs font-semibold uppercase tracking-wide text-slate-500">
                <tr>
                  <th className="px-4 py-3">Advisor</th>
                  <th className="px-4 py-3">Email</th>
                  <th className="px-4 py-3">Status</th>
                  <th className="px-4 py-3 text-right">Actions</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-100">
                {advisors.map((advisor) => (
                  <tr
                    key={advisor.id}
                    className={`text-slate-800 ${
                      focusedUserId === advisor.id ? 'bg-indigo-50/40' : ''
                    }`}
                  >
                    <td className="px-4 py-3 font-medium">{advisor.name}</td>
                    <td className="px-4 py-3">{advisor.email}</td>
                    <td className="px-4 py-3">
                      <span
                        className={`inline-flex rounded-full px-2.5 py-0.5 text-xs font-medium capitalize ${
                          advisor.subscribed
                            ? 'bg-green-50 text-green-800'
                            : 'bg-slate-100 text-slate-700'
                        }`}
                      >
                        {advisor.subscription_status}
                      </span>
                    </td>
                    <td className="px-4 py-3 text-right">
                      {advisor.subscribed ? (
                        <span className="text-sm text-slate-500">Active</span>
                      ) : (
                        <button
                          type="button"
                          disabled={!checkoutConfigured || startingForId === advisor.id}
                          onClick={() => startCheckout(advisor.id)}
                          className="text-sm font-medium text-indigo-600 hover:text-indigo-500 disabled:cursor-not-allowed disabled:opacity-50"
                        >
                          {startingForId === advisor.id ? 'Starting…' : 'Subscribe with Stripe'}
                        </button>
                      )}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </div>
    </AuthenticatedPage>
  )
}
