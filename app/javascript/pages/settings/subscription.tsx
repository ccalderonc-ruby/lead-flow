import { Head, router, usePage } from '@inertiajs/react'

import AuthenticatedPage from '@/components/layouts/AuthenticatedPage'

type SubscriptionPageProps = {
  subscription_status: string
  subscribed: boolean
  checkout_configured: boolean
}

export default function SubscriptionSettings({
  subscription_status: subscriptionStatus,
  subscribed,
  checkout_configured: checkoutConfigured,
}: SubscriptionPageProps) {
  const { url } = usePage()
  const checkoutParam = new URLSearchParams(url.split('?')[1] || '').get('checkout')
  const activationPending = checkoutParam === 'success' && !subscribed

  function startCheckout() {
    router.post('/settings/subscription')
  }

  return (
    <AuthenticatedPage>
      <Head title="Subscription" />

      <div className="max-w-xl">
        <h1 className="text-2xl font-semibold text-slate-900">Subscription</h1>
        <p className="mt-1 text-slate-600">
          LeadFlow Pro unlocks CSV export of your leads from the Leads page.
        </p>

        <div className="mt-8 space-y-4">
          <p className="text-sm text-slate-700">
            Status:{' '}
            <span className="font-semibold capitalize text-slate-900">{subscriptionStatus}</span>
          </p>

          {activationPending && (
            <p className="rounded-lg bg-sky-50 px-4 py-3 text-sm text-sky-900">
              Payment received. Waiting for Stripe to confirm — status updates when the webhook
              arrives.
            </p>
          )}

          {subscribed ? (
            <p className="rounded-lg bg-green-50 px-4 py-3 text-sm text-green-800">
              Your LeadFlow Pro subscription is active.
            </p>
          ) : (
            <>
              {!checkoutConfigured && (
                <p className="rounded-lg bg-amber-50 px-4 py-3 text-sm text-amber-900">
                  Stripe is not configured. Set STRIPE_SECRET_KEY, STRIPE_PRICE_ID, and
                  STRIPE_WEBHOOK_SECRET (see .env.example) to enable checkout.
                </p>
              )}
              <button
                type="button"
                disabled={!checkoutConfigured}
                onClick={startCheckout}
                className="inline-flex items-center justify-center rounded-lg bg-indigo-600 px-4 py-2 text-sm font-medium text-white hover:bg-indigo-500 disabled:cursor-not-allowed disabled:opacity-50"
              >
                Subscribe with Stripe
              </button>
            </>
          )}
        </div>
      </div>
    </AuthenticatedPage>
  )
}
