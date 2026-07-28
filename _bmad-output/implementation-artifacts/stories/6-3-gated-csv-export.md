---
baseline_commit: 893fbc73921fc7ca24ebf1a0e10a7941ee635458
---

# Story 6.3: Gated CSV export

Status: done

<!-- Ultimate context engine analysis completed - comprehensive developer guide created -->

## Story

As a **subscribed Advisor**,
I want to export my leads as CSV,
So that the Stripe integration demonstrates value (UJ-7).

**Epic:** 6 — Ship as a SaaS  
**Week:** 6  
**Fulfills:** FR-15 (gated feature portion)  
**Depends on:** Story 6.2 merged to `dev` (PR #32 — `User#subscribed?`, shared `auth.user.subscribed`) ✅  
**Unblocks:** Story 6.4 production deploy; demo path UJ-7 end-to-end

---

## Acceptance Criteria

1. **Given** I am an Advisor **without** an active subscription  
   **When** I click Export CSV on the leads list  
   **Then** I am prompted to subscribe (link/redirect to `/settings/subscription` — do **not** start Stripe Checkout from this click alone; epic AC says “prompted to subscribe”)

2. **Given** I have an **active** subscription (`subscription_status == "active"`)  
   **When** I export  
   **Then** a CSV downloads with **my** policy-scoped leads (advisor = assigned leads only)

3. **Given** Assistant, guest, or unsubscribed user bypasses the UI  
   **When** they hit the export endpoint directly  
   **Then** they are denied (server-side gate — trust boundary; do not defer)

4. **Given** docs  
   **When** done  
   **Then** `docs/IMPLEMENTATION.md` has **Step 24** for Story 6.3  
   **And** subscription page copy no longer says CSV is “coming next”

5. **Given** Epic 5 process  
   **When** shipping  
   **Then** branch `feature/6-3-gated-csv-export` from **`origin/dev` after #32**; one PR into `dev`; do not stack 6.4 until merged

---

## Tasks / Subtasks

- [x] **Prerequisite**
  - [x] Confirm PR #32 is on `origin/dev`; set `baseline_commit` to merge SHA (`893fbc7…`)
  - [x] Branch `feature/6-3-gated-csv-export` from `origin/dev`

- [x] **Authorization** (AC: 2–3) — **trust boundary**
  - [x] Add `LeadPolicy#export?` — **Advisor + `user.subscribed?`** only
  - [x] `verify_authorized` must pass on the export action
  - [x] Fail closed: inactive subscription → redirect with clear message

- [x] **Export endpoint** (AC: 2)
  - [x] Route: `collection { get :export }` → `GET /leads/export`
  - [x] `LeadsController#export` — authorize + `policy_scope` + optional `q`/`stage_id`
  - [x] `send_data` CSV attachment via `LeadsCsv`
  - [x] Columns: name, email, company, stage, advisor, last_activity_at, estimated_value
  - [x] Stdlib/`csv` gem — no reinvented parser

- [x] **UI** (AC: 1)
  - [x] Export CSV when `can_export`; Subscribe CTA when inactive advisor
  - [x] Full-page `<a href>` download (not Inertia visit)
  - [x] `can_export` / `show_subscribe_for_export` props from index

- [x] **Copy / fixtures**
  - [x] Subscription page copy updated
  - [x] `advisor_subscribed` fixture with `subscription_status: active`

- [x] **Tests** (AC: 1–3)
  - [x] Subscribed advisor CSV scoped; inactive/assistant/guest denied; policy matrix; index props

- [x] **Docs + sprint**
  - [x] IMPLEMENTATION Step 24; project-context
  - [x] Story → review when green

### Review Findings

- [x] [Review][Patch] Export link must use applied `meta.q`, not unsubmitted search draft [`app/javascript/pages/leads/index.tsx:73`]
- [x] [Review][Patch] Sanitize CSV text cells against spreadsheet formula injection (`=`, `+`, `-`, `@`) [`app/services/leads_csv.rb:28`]
- [x] [Review][Patch] Align CSV `last_activity_at` with index (`last_activity_at || updated_at`) [`app/services/leads_csv.rb:34`]
- [x] [Review][Patch] Inactive advisor hitting `/leads/export` redirects to `/settings/subscription` with subscribe message (not generic root Pundit flash) [`app/controllers/leads_controller.rb:58`]
- [x] [Review][Patch] Prepend UTF-8 BOM for Excel-friendly CSV [`app/controllers/leads_controller.rb:71`]
- [x] [Review][Patch] Strengthen tests: subscribed index props; export `q`/`stage_id`; Content-Disposition filename [`test/controllers/leads_controller_test.rb`]
- [x] [Review][Defer] Unbounded in-memory CSV generation / no streaming [`app/services/leads_csv.rb`] — deferred, course-scale data OK
- [x] [Review][Defer] Extract shared index/export scoped-query helper [`app/controllers/leads_controller.rb`] — deferred, advisor path has no `user_id` filter
- [x] [Review][Defer] Dedicated `LeadsCsv` unit tests — deferred, covered lightly via controller
- [x] [Review][Defer] `advisor_subscribed` fixture has no assigned leads — deferred, controller tests activate `users(:advisor)`

---

## Dev Notes

(See create-story body above for full guardrails — preserved in git history / prior version.)

### References

- [epics.md Story 6.3](../../planning-artifacts/epics.md)
- [PRD FR-15 / UJ-7](../../planning-artifacts/prds/prd-leadflow-crm-2026-07-05/prd.md)
- [Story 6.2](./6-2-stripe-checkout-and-webhook.md)

### Verification

```bash
bin/rails test test/controllers/leads_controller_test.rb test/policies/lead_policy_test.rb
npm run check
```

---

## Dev Agent Record

### Agent Model Used

Composer (create-story + dev-story)

### Debug Log References

- Added explicit `csv` gem (Ruby 3.4 default-gem warning)
- Vite test manifest race: rebuild with `bin/vite build --mode=test` if flaky

### Completion Notes List

- Server-side `LeadPolicy#export?` + `GET /leads/export` with scoped CSV
- Unsubscribed advisors get Subscribe CTA → `/settings/subscription`
- Full suite green after Vite rebuild; `npm run check` clean

### File List

- `Gemfile` / `Gemfile.lock`
- `app/controllers/leads_controller.rb`
- `app/policies/lead_policy.rb`
- `app/services/leads_csv.rb`
- `app/javascript/pages/leads/index.tsx`
- `app/javascript/pages/settings/subscription.tsx`
- `config/routes.rb`
- `docs/IMPLEMENTATION.md`
- `docs/project-context.md`
- `test/controllers/leads_controller_test.rb`
- `test/fixtures/users.yml`
- `test/policies/lead_policy_test.rb`
- `_bmad-output/implementation-artifacts/sprint-status.yaml`
- `_bmad-output/implementation-artifacts/stories/6-3-gated-csv-export.md`

### Change Log

- 2026-07-25: Created Story 6.3; implemented gated CSV export; status → review
- 2026-07-27: Code review patches applied; status → done
