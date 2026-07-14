---
baseline_commit: abeb740e88f2007a379ef4922e0b370bb5acce45
---

# Story 2.2: Create lead

Status: review

<!-- Ultimate context engine analysis completed - comprehensive developer guide created -->

## Story

As an **Advisor**,
I want to create a new lead with company and stage,
So that I can add prospects to my pipeline (UJ-2).

**Epic:** 2 — Manage Leads  
**Week:** 2  
**Fulfills:** FR-6, UX-DR3  
**Depends on:** Stories 1.3 ✅, 1.4 ✅, 2.1 ✅  
**Unblocks:** Story 2.3 (edit), Story 2.4 (detail expands show)

---

## Acceptance Criteria

1. **Given** I am an Admin or Advisor on `/leads/new`  
   **When** I submit valid data (name, email, company name, company country, lead country, stage, assigned user)  
   **Then** the lead is created  
   **And** I am redirected to `/leads` with a flash notice  
   **Note:** Epic AC says Lead Detail; FR-6 allows “Detail or list.” Detail is Story 2.4 — list redirect is required for this story. Do **not** implement full detail.

2. **Given** I enter a company name with typos/punctuation variants of an existing company  
   **When** the form saves  
   **Then** `Company.find_or_initialize_by_name` reuses the existing company (no duplicate row)

3. **Given** required fields are missing or invalid  
   **When** I submit  
   **Then** Inertia validation errors display inline on the form (`errors.field?.join(', ')`)

4. **Given** the email already belongs to another lead (case-insensitive)  
   **When** I submit  
   **Then** the form shows the uniqueness error (`already belongs to another lead`)  
   **And** no second lead is inserted  
   **And** existing lead attributes are **not** overwritten

5. **Given** I am an Assistant  
   **When** I visit `/leads/new` or POST create  
   **Then** access is denied (Pundit / existing not-authorized handling)

6. **Given** I am on the leads index  
   **When** I am allowed to create  
   **Then** I see a “New lead” link/button to `/leads/new`

---

## Tasks / Subtasks

- [x] **Routes** (AC: 1)
  - [x] Expand `resources :leads, only: %i[index new create]` in `config/routes.rb`

- [x] **Controller** (AC: 1–5)
  - [x] `new` — `authorize Lead`; pass form option props (countries, stages, assignable users)
  - [x] `create` — `authorize Lead`; company dedup + email find-or-initialize path; flash; redirect to `leads_path`
  - [x] Strong params for lead attrs + separate `company_name` / `company_country_id`
  - [x] On validation failure: re-render `leads/new` with `inertia: { errors: … }` (and preserve form options)
  - [x] Rescue concurrent `ActiveRecord::RecordNotUnique` on lead create → treat as email uniqueness error

- [x] **Inertia page** (AC: 1, 3, 4, 6 / UX-DR3)
  - [x] `app/javascript/pages/leads/new.tsx` with `useForm` POST to `/leads`
  - [x] Fields: name, email, company name, company country, lead country, stage, assigned user; optional phone + estimated_value
  - [x] Inline errors; disable submit while `processing`
  - [x] “New lead” CTA on `leads/index.tsx` via `can_create` prop (hidden for Assistant)

- [x] **Assignment rules** (AC: 1, 5)
  - [x] Advisor: force `user_id = current_user.id` server-side
  - [x] Admin: can assign any active User with advisor/admin role (pass list from `new`)
  - [x] Assistant: cannot create (policy already)

- [x] **Tests**
  - [x] Admin/Advisor can create with valid params → redirect + flash + record persisted
  - [x] Company name variants reuse same `company_id`
  - [x] Missing required fields → inertia errors
  - [x] Duplicate email → errors, count unchanged
  - [x] Assistant denied on `new`/`create`
  - [x] Advisor cannot assign lead to another user (forced to self)
  - [x] Unauthenticated → login
  - [x] Optional: `LeadPolicy` `create?` coverage if gap

- [x] **Docs**
  - [x] Update `docs/IMPLEMENTATION.md` Step for create lead
  - [x] Mark deferred-work items for email find-or-initialize / RecordNotUnique as done when implemented

---

## Dev Notes

### MUST follow (non-negotiable)

1. **Email is required + unique** (harder than epic AC list). Model + DB already enforce. Form must include email.
2. **Create path for email:**
   ```ruby
   lead = Lead.find_or_initialize_by_email(email_param)
   if lead.persisted?
     # DO NOT assign_attributes / update existing
     lead.errors.add(:email, "already belongs to another lead")
     # re-render new with errors
   else
     # assign lead attrs, attach company, save
   end
   ```
3. **Company create pattern** ([docs/DATA_MODEL.md](../../../docs/DATA_MODEL.md)):
   ```ruby
   company = Company.find_or_initialize_by_name(params[:company_name])
   company.country_id = params[:company_country_id] if company.new_record? || company.country_id.blank?
   # Prefer: always set country from form when provided so new companies validate
   company.country_id = params[:company_country_id] if params[:company_country_id].present?
   company.save!
   ```
   Two countries on the form: **company HQ** (`company_country_id`) and **lead location** (`country_id`). Both required for a good create. For an **existing** company, still accept lead `country_id`; do not invent a second company.
4. **Authorize** with Pundit (`authorize Lead` on new/create). `LeadPolicy#create?` → `admin? || advisor?`.
5. **Inertia:** inherit `InertiaController`; page wrapped in `AuthenticatedPage`; `useForm` only (no raw `fetch`).
6. **Flash:** `flash[:notice] = "Lead created."` (or similar) on success — shared via `InertiaController`.

### Concurrent duplicate email

```ruby
rescue ActiveRecord::RecordNotUnique
  lead = Lead.find_by_email(email_param) || Lead.new
  lead.errors.add(:email, "already belongs to another lead")
  # render new with errors (+ form options)
end
```

Wrap the save path carefully so company save failures also surface as field errors (not 500). Prefer transaction:

```ruby
ActiveRecord::Base.transaction do
  company.save!
  lead.save!
end
```

Map `ActiveRecord::RecordInvalid` to Inertia errors when needed.

### Do NOT

- Do not implement edit (2.3) or full lead detail activity timeline (2.4)
- Do not add tags, teams, opportunities, notes on this form
- Do not add company autocomplete API in this story — free-text `company_name` + normalize is enough (DATA_MODEL prefers autocomplete later)
- Do not loosen email uniqueness or skip `find_or_initialize_by_email`
- Do not use a new Form gem / Formik — stick to Inertia `useForm`
- Do not paginate gems / change index search behavior beyond CTA

### Form option props (suggested)

Pass JSON-serializable arrays from `new` (and again on failed `create`):

| Prop | Source |
|------|--------|
| `countries` | `Country.order(:name).pluck(:id, :name)` → `{ id, name }` |
| `stages` | `LeadStage.order(:position)` → `{ id, name }` |
| `assignees` | Users who can own leads (admin + advisor roles) — Admin only needs full list; Advisor can omit or single self |

### UI patterns to copy

- Login form: `app/javascript/pages/sessions/new.tsx` (`useForm`, `errors.field.join`)
- Leads layout/styling: `app/javascript/pages/leads/index.tsx` (slate/indigo Tailwind already in app — match, don’t invent a new design system)
- No Visily PNGs guaranteed under `docs/design/` — match existing CRM pages

### Routes today

```ruby
resources :leads, only: :index  # ← expand to index/new/create
```

### Policy notes

- Assistant can `index?` / `show?` but **not** `create?`
- Advisor create: force `user_id` to current user in controller so they cannot spoof assignment
- Admin: permit `user_id` from params if in assignee allowlist

### Testing standards

- `sign_in_as(users(:advisor))` / `users(:admin)` / `users(:assistant)`
- Assert Inertia responses where project already does — follow `test/controllers/leads_controller_test.rb` + `sessions_controller_test.rb`
- Prefer `assert_difference "Lead.count", 1` and `assert_no_difference` for email dupe
- Company reuse: create with `"Acme Corp"` then `"ACME CORP."` → same `company_id` (fixtures already have `companies(:acme)`)
- Run `bin/rails test` and `npm run check` before marking review

### Previous story intelligence (2.1)

- Index already authorizes + serializes leads; add CTA only
- Email helpers and unique index **already shipped** — wire them, don’t re-migrate
- Deferred explicitly into this story: wire `find_or_initialize_by_email`; rescue `RecordNotUnique`
- Hardened param pattern from index: `Array(params[:x]).first` when relevant; keep create params simple nested hash
- Search/history: don't break index GET `q` / pagination

### Git intelligence

- Latest: `abeb740` Story 2.1 leads index + email uniqueness
- Branch: `feature/epic-2-manage-leads`
- Target PR base when ready: `dev` (not `main`)

### Project context reference

- [docs/project-context.md](../../../docs/project-context.md) — Inertia `useForm`, email uniqueness, company dedup, `InertiaController`
- [docs/DATA_MODEL.md](../../../docs/DATA_MODEL.md) — create lead / company pattern, role matrix
- [epics.md Story 2.2](../../planning-artifacts/epics.md) — original ACs
- [Lead model](../../../app/models/lead.rb) — `find_or_initialize_by_email`
- [Company model](../../../app/models/company.rb) — `find_or_initialize_by_name`
- [LeadPolicy](../../../app/policies/lead_policy.rb) — `create?`

### Project structure (files to touch)

| Path | Action |
|------|--------|
| `config/routes.rb` | UPDATE — add `new`/`create` |
| `app/controllers/leads_controller.rb` | UPDATE — `new`/`create` + private helpers |
| `app/javascript/pages/leads/new.tsx` | NEW |
| `app/javascript/pages/leads/index.tsx` | UPDATE — New lead CTA |
| `test/controllers/leads_controller_test.rb` | UPDATE — create/auth cases |
| `test/policies/lead_policy_test.rb` | UPDATE optional — `create?` |
| `docs/IMPLEMENTATION.md` | UPDATE |
| `_bmad-output/implementation-artifacts/deferred-work.md` | UPDATE — clear 2.2 deferrals when done |

---

## Dev Agent Record

### Agent Model Used

Composer (dev-story)

### Debug Log References

- Full suite: 105 tests, 317 assertions, 0 failures
- `npm run check` passes
- RuboCop clean on touched Ruby files

### Completion Notes List

- Routes expanded to `index` / `new` / `create`
- Create uses `Lead.find_or_initialize_by_email` (reject if persisted) + `Company.find_or_initialize_by_name`
- Rescues `RecordInvalid` and `RecordNotUnique` with Inertia errors
- Advisor assignment forced server-side; Admin picks from assignee list
- Index CTA gated by `can_create` prop from Pundit
- Success redirects to `/leads` with flash (detail deferred to 2.4)

### File List

- config/routes.rb
- app/controllers/leads_controller.rb
- app/javascript/pages/leads/new.tsx
- app/javascript/pages/leads/index.tsx
- test/controllers/leads_controller_test.rb
- test/policies/lead_policy_test.rb
- docs/IMPLEMENTATION.md
- docs/project-context.md
- _bmad-output/implementation-artifacts/deferred-work.md
- _bmad-output/implementation-artifacts/sprint-status.yaml
- _bmad-output/implementation-artifacts/stories/2-2-create-lead.md

### Change Log

- 2026-07-13: Implemented Story 2.2 create lead end-to-end; status → review

---

## Open questions (non-blocking)

Resolved in this story file for the implementer:

| Question | Decision |
|----------|----------|
| Email missing from epic AC | Required — model truth |
| `find_or_initialize` update vs reject | Reject: show uniqueness error; never overwrite |
| Redirect to detail (2.4 not built) | Redirect to `/leads` + flash; FR-6 OK |
| Company UX autocomplete vs text | Free-text + normalize this story |
| Advisor assignment | Force `user_id` to current user server-side |
| Optional fields | phone + estimated_value only; rest later |
