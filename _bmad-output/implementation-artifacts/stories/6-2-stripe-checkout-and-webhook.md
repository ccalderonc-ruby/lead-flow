---
baseline_commit: 4716f97fee2980b9b3948f0543efbadc96abbe0e
---

# Story 6.2: Stripe checkout and webhook

Status: done

<!-- Ultimate context engine analysis completed - comprehensive developer guide created -->

## Story

As an **Advisor**,
I want to subscribe via Stripe test checkout,
So that I can access premium features (UJ-7).

**Epic:** 6 — Ship as a SaaS  
**Week:** 6  
**Fulfills:** FR-15 (checkout + webhook portion)  
**Depends on:** Auth/roles ✅; Story 6.1 merged to `dev` (PR #31 — merge before branching)  
**Unblocks:** Story 6.3 gated CSV export

---

## Acceptance Criteria

1. **Given** Stripe test keys configured (credentials or ENV)  
   **When** an Advisor opens subscription settings and starts checkout  
   **Then** the server creates a Stripe Checkout Session and redirects the browser to Stripe (test mode)

2. **Given** Stripe sends a signed `checkout.session.completed` webhook  
   **When** the webhook handler verifies the signature and processes the event  
   **Then** the matching **User** gets `subscription_status` = `active`

3. **Given** a forged or unsigned webhook body  
   **When** posted to the webhook endpoint  
   **Then** the request is rejected (no status change)

4. **Given** Assistant (or unauthenticated)  
   **When** they attempt to start checkout  
   **Then** they are denied (Advisor-only; Admin optional — prefer Advisor-only per epic)

5. **Given** docs  
   **When** done  
   **Then** `docs/IMPLEMENTATION.md` has **Step 23** for Story 6.2  
   **And** README notes which ENV/credentials keys are required for local Stripe test mode

6. **Given** Epic 5 process  
   **When** shipping  
   **Then** branch `feature/6-2-stripe-checkout-and-webhook` from **`origin/dev` after #31 is merged**; one PR into `dev`; do not stack 6.3 until merged

---

## Tasks / Subtasks

- [x] **Prerequisite**
  - [x] Merge PR #31 (Story 6.1) into `dev` before creating/pushing the 6.2 feature branch
  - [x] Set story frontmatter `baseline_commit` to the merge SHA on `origin/dev`

- [x] **Dependencies + config** (AC: 1, 5)
  - [x] Add official `stripe` gem; `bundle install`
  - [x] Document required secrets (do **not** commit real keys): e.g. `STRIPE_SECRET_KEY`, `STRIPE_PUBLISHABLE_KEY`, `STRIPE_WEBHOOK_SECRET`, `STRIPE_PRICE_ID` (or Rails credentials equivalents)
  - [x] Optional: `.env.example` listing key names only (empty values)

- [x] **Schema + model** (AC: 2)
  - [x] Migration on `users`: at least `subscription_status` (string, default `"inactive"`; allow `active` / `inactive`)
  - [x] Recommended: `stripe_customer_id`, `stripe_subscription_id` (nullable strings) for reliable webhook → user mapping
  - [x] `User` helpers: `subscribed?` → `subscription_status == "active"`; validate inclusion of status values
  - [x] Fixtures default `inactive`; one fixture or test factory path for `active` (needed by 6.3 later)

- [x] **Checkout (authenticated)** (AC: 1, 4)
  - [x] Routes: e.g. `resource :subscription, only: %i[show create], controller: "subscriptions"` under path `/settings/subscription` **or** `namespace :settings { resource :subscription ... }` matching PRD assumption
  - [x] `SubscriptionsController#show` — Inertia page with current status + “Subscribe” CTA (Advisor)
  - [x] `SubscriptionsController#create` — `Stripe::Checkout::Session.create` server-side; `redirect_to session.url, allow_other_host: true`
  - [x] Success/cancel URLs back to app (settings page with flash)
  - [x] Pundit: new `SubscriptionPolicy` (or authorize a PORO) — Advisor `show?`/`create?`; deny assistant; skip or allow admin only if product wants (default **Advisor only**)
  - [x] `verify_authorized` must pass (ApplicationController after_action)
  - [x] Nav: add Subscription link for advisors (and only those roles) in `navigation.ts` / layout

- [x] **Webhook (unauthenticated, signed)** (AC: 2–3) — **trust boundary; do not defer**
  - [x] Route: `post "/webhooks/stripe", to: "webhooks/stripe#create"` (or similar)
  - [x] Controller inherits carefully: **no** session auth; `skip_forgery_protection`; `skip_after_action :verify_authorized`; allow unauthenticated
  - [x] Verify with `Stripe::Webhook.construct_event(payload, sig_header, webhook_secret)` — rescue → 400
  - [x] Handle `checkout.session.completed`: resolve User (prefer `client_reference_id` / metadata `user_id` set at Session create; fallback `customer` email only if documented and tested)
  - [x] Idempotent: already-active user stays active; unknown user → log + 200 or 404 (prefer 200 after log to avoid Stripe retry storms for junk) — document choice
  - [x] Return 200 on success

- [x] **Shared props (minimal)** (AC: 1)
  - [x] Optionally share `subscription_status` or `subscribed` on `AuthUser` via `InertiaController` for UI (keeps 6.3 simpler) — if added, update `app/javascript/types/index.ts`

- [x] **Tests** (AC: 1–4)
  - [x] Checkout create: Advisor succeeds (stub `Stripe::Checkout::Session.create`); Assistant/guest denied
  - [x] Webhook: valid signature → user active; invalid signature → no change + non-2xx
  - [x] Idempotent second webhook
  - [x] Stub Stripe in tests — no live network

- [x] **Docs + sprint**
  - [x] IMPLEMENTATION Step 23; project-context Stripe row
  - [x] Story → review when green

### Review Findings

- [x] [Review][Patch] Add `dotenv-rails` so local `.env` Stripe keys load (Decision: 1.1)
- [x] [Review][Patch] Require webhook secret in `StripeConfig.configured?` so Subscribe stays disabled until webhook is wired (Decision: 2.1)
- [x] [Review][Patch] Set `Stripe.api_key` from `StripeConfig` at request time (boot-time initializer can be nil/stale vs live ENV) [config/initializers/stripe.rb:5]
- [x] [Review][Patch] Gate entitlement on `payment_status` (and reject blank `subscription` for subscription mode) before setting `active` [app/controllers/webhooks/stripe_controller.rb:40]
- [x] [Review][Patch] Success/cancel return UX — show flash/pending notice (`?checkout=success|cancel`); empty `useEffect` today [app/javascript/pages/settings/subscription.tsx:19]
- [x] [Review][Patch] Teardown mutated `ENV["STRIPE_*"]` / `Stripe.api_key` in controller tests [test/controllers/settings/subscriptions_controller_test.rb:6]
- [x] [Review][Patch] Add Stripe idempotency key on Checkout Session create [app/controllers/settings/subscriptions_controller.rb:27]
- [x] [Review][Patch] After signature verify, rescue handler errors → log + 200 (avoid infinite Stripe retries on permanent errors) [app/controllers/webhooks/stripe_controller.rb:24]
- [x] [Review][Patch] Document unknown-user → log + 200 in IMPLEMENTATION Step 23 [docs/IMPLEMENTATION.md:811]
- [x] [Review][Patch] Reuse `stripe_customer_id` when present instead of always `customer_email` [app/controllers/settings/subscriptions_controller.rb:33]
- [x] [Review][Patch] Guard blank Checkout Session `url` before redirect [app/controllers/settings/subscriptions_controller.rb:37]
- [x] [Review][Patch] Rescue unexpected construct_event failures (e.g. missing signature) as 400 [app/controllers/webhooks/stripe_controller.rb:17]
- [x] [Review][Patch] Strengthen tests: assert Session create attrs; unknown-user webhook; guest POST denied [test/controllers/]
- [x] [Review][Defer] Unique indexes on `stripe_customer_id` / `stripe_subscription_id` [db/migrate/20260725172104_add_subscription_fields_to_users.rb] — deferred, pre-existing not required for 6.2 ACs
- [x] [Review][Defer] Optional real `Stripe::Webhook.construct_event` signature test (beyond intentional stubs) — deferred, pre-existing not required for 6.2 ACs
- [x] [Review][Defer] Dedicated `active` subscription fixture for 6.3 reuse — deferred, pre-existing not required for 6.2 ACs (`update!` path satisfies story)

---

## Dev Notes

### MUST follow

1. **Merge #31 first** — Epic 5 retro: one branch per story; merge to `dev` before basing the next. #31 is open/green at story creation.
2. **Elevated care on webhooks/payments** — patch signature verification, authz on checkout, CSRF skip only on webhook. Triage: `docs/BUG_POLISH_TRIAGE.md`.
3. **CSV export is Story 6.3** — do **not** implement gated export here; only set `subscription_status` so 6.3 can gate.
4. Checkout Session **server-side only** — never put secret key in frontend.
5. Pass `client_reference_id: current_user.id.to_s` (and/or metadata) when creating the Session so webhook can find the user without relying on email alone.
6. `User#status` (`active`/`disabled`) is **account** status — do **not** overload it for billing. Use **`subscription_status`**.
7. No Stripe gem yet — add it. No `.env.example` yet — create if documenting ENV names.
8. Kamal `env.secret` currently only `RAILS_MASTER_KEY` — documenting keys for 6.2/6.4 is enough; wiring Kamal secrets can wait for deploy story unless easy.
9. Frozen string literal; RuboCop; `bin/rails test` green; `npm run check` if TS touched.
10. Prefer FormFields / existing layout patterns; new dialogs need `useDialogA11y` (settings page may not need a dialog).

### Current gaps (from repo scan)

| Area | State |
|------|--------|
| `users` schema | No subscription/Stripe columns |
| Gemfile | No `stripe` |
| Routes | No settings/webhooks |
| Nav | No Subscription item |
| CSRF skip | Nowhere yet — webhook must add it |
| `verify_authorized` | Global after_action — webhook must skip |

### Suggested shape (illustrative)

```ruby
# Session create (authenticated)
Stripe::Checkout::Session.create(
  mode: "subscription",
  line_items: [ { price: ENV.fetch("STRIPE_PRICE_ID"), quantity: 1 } ],
  success_url: ...,
  cancel_url: ...,
  client_reference_id: current_user.id.to_s,
  customer_email: current_user.email
)
```

```ruby
# Webhook
event = Stripe::Webhook.construct_event(request.body.read, request.env["HTTP_STRIPE_SIGNATURE"], webhook_secret)
# on checkout.session.completed → User.find(...).update!(subscription_status: "active", ...)
```

### Local Stripe CLI (document in IMPLEMENTATION)

```bash
stripe listen --forward-to localhost:3000/webhooks/stripe
# use printed whsec_… as STRIPE_WEBHOOK_SECRET
```

### Git / branch

- **Before branch:** merge https://github.com/ccalderonc-ruby/lead-flow/pull/31  
- Branch: `feature/6-2-stripe-checkout-and-webhook` from latest `origin/dev`  
- PR base: **`dev`**  
- Do **not** stack 6.3 on this branch before merge

### References

- [epics.md Story 6.2](../../planning-artifacts/epics.md)
- [PRD FR-15 / UJ-7](../../planning-artifacts/prds/prd-leadflow-crm-2026-07-05/prd.md)
- [Epic 5 retro](../epic-5-retro-2026-07-25.md)
- [BUG_POLISH_TRIAGE](../../../docs/BUG_POLISH_TRIAGE.md)
- [InertiaController share](../../../app/controllers/inertia_controller.rb)
- [Authentication](../../../app/controllers/concerns/authentication.rb)
- [navigation.ts](../../../app/javascript/lib/navigation.ts)

### Verification

```bash
bin/rails test test/controllers/subscriptions_controller_test.rb test/controllers/webhooks/stripe_controller_test.rb test/models/user_test.rb
npm run check
```

### Out of scope / defer

- Gated CSV export (6.3)
- Stripe Customer Portal / cancel / plan changes
- Live-mode keys
- Billing UI beyond single Subscribe CTA + status
- Marking `in_progress` overdue tasks (6.1 defer)

---

## Open questions (non-blocking defaults)

1. **Admin subscribe?** Default **no** — epic says Advisor.  
2. **Webhook unknown user?** Default **200 + log** (avoid infinite Stripe retries).  
3. **Keys via ENV vs credentials?** Prefer ENV for local/Stripe CLI; credentials OK if documented.

---

## Dev Agent Record

### Agent Model Used

Composer (dev-story)

### Debug Log References

- Minitest 6 has no `Object#stub`; added `stub_singleton` helper in `test_helper.rb`
- Wrapped Stripe SDK behind `StripeCheckout` / `StripeWebhook` for test isolation
- `.env.example` was ignored by `/.env*`; un-ignored via `!/.env.example`

### Completion Notes List

- PR #31 merged; branch cut from `origin/dev` @ `4716f97`
- Advisor-only checkout at `/settings/subscription`; webhook at `POST /webhooks/stripe` with signature verify
- Unknown user on webhook → log + 200 (idempotent activate for known users)
- Full suite: 256 runs, 0 failures; `npm run check` clean
- Code review patches applied: dotenv-rails, webhook-required configured?, payment_status gate, checkout hardening, UX flash, stronger tests (260 green)

### File List

- `.env.example`
- `.gitignore`
- `Gemfile` / `Gemfile.lock`
- `README.md`
- `app/controllers/inertia_controller.rb`
- `app/controllers/settings/subscriptions_controller.rb`
- `app/controllers/webhooks/stripe_controller.rb`
- `app/javascript/components/layouts/AppLayout.tsx`
- `app/javascript/lib/navigation.ts`
- `app/javascript/pages/settings/subscription.tsx`
- `app/javascript/types/index.ts`
- `app/models/user.rb`
- `app/policies/subscription_policy.rb`
- `app/services/stripe_checkout.rb`
- `app/services/stripe_webhook.rb`
- `config/initializers/stripe.rb`
- `config/routes.rb`
- `db/migrate/20260725172104_add_subscription_fields_to_users.rb`
- `db/schema.rb`
- `docs/IMPLEMENTATION.md`
- `docs/project-context.md`
- `lib/stripe_config.rb`
- `test/controllers/settings/subscriptions_controller_test.rb`
- `test/controllers/webhooks/stripe_controller_test.rb`
- `test/models/user_test.rb`
- `test/test_helper.rb`
- `_bmad-output/implementation-artifacts/sprint-status.yaml`
- `_bmad-output/implementation-artifacts/stories/6-2-stripe-checkout-and-webhook.md`

### Change Log

- 2026-07-25: Created Story 6.2 context; status → ready-for-dev; prerequisite merge PR #31
- 2026-07-25: Implemented Stripe checkout + webhook; status → review
- 2026-07-25: Code review patches applied; status → done
