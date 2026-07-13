# Story 2.1: Leads index with search

Status: done

## Story

As an **Advisor**,
I want to see and search my assigned leads in a table,
So that I can find prospects quickly (UJ-2).

**Epic:** 2 — Manage Leads  
**Week:** 2  
**Fulfills:** FR-5, UX-DR2  
**Depends on:** Stories 1.3 ✅, 1.4 ✅

---

## Acceptance Criteria

1. **Given** I am an Advisor with assigned leads  
   **When** I visit `/leads`  
   **Then** I see a table with name, company, stage, advisor, last activity, estimated value  
   **And** only my assigned leads appear

2. **Given** I am an Admin  
   **When** I visit `/leads`  
   **Then** I see all leads

3. **Given** I type in the search box  
   **When** I search by name, email, or company  
   **Then** the list filters matching records

4. **And** pagination shows 25 leads per page

---

## Tasks / Subtasks

- [x] **Controller** (AC: 1–4)
  - [x] `authorize Lead` + `policy_scope(Lead)`
  - [x] Search by name, email, company (case-insensitive)
  - [x] Paginate 25 per page; pass `leads` + `meta` props

- [x] **Model**
  - [x] `Lead.search` scope/query helper

- [x] **Inertia page** (AC: 1, 3, 4 / UX-DR2)
  - [x] Table columns: name, company, stage, advisor, last activity, value
  - [x] Search box (GET `q` via Inertia)
  - [x] Pagination controls (page / total)

- [x] **Tests**
  - [x] Advisor sees only assigned leads
  - [x] Admin sees all leads
  - [x] Search filters by name/email/company
  - [x] Unauthenticated redirected to login

- [x] **Docs**
  - [x] Update `docs/IMPLEMENTATION.md`

---

## Dev Notes

### Do NOT

- Do not add stage/advisor filters yet (Story 5.4)
- Do not implement create/edit/detail (Stories 2.2–2.4)
- Do not add a new pagination gem — use limit/offset

### Patterns

- Inherit `InertiaController`; wrap page in `AuthenticatedPage`
- Serialize associations as plain strings for JSON props
- Assistant policy scope = all (read); same as admin for index scoping

### References

- [epics.md](../../planning-artifacts/epics.md#story-21-leads-index-with-search)
- [LeadPolicy](../../../app/policies/lead_policy.rb)

---

## Dev Agent Record

### Agent Model Used

Composer (dev-story)

### Debug Log References

- Full suite: 80 tests, 215 assertions, 0 failures
- `npm run check` passes

### Completion Notes List

- `Lead.search` uses ILIKE on name/email + EXISTS company name match
- `LeadsController#index` authorizes, policy-scopes, paginates 25/page
- Inertia table with search + previous/next pagination
- Stage/advisor filters deferred to Story 5.4

- Mandatory unique lead email (normalized); `Lead.find_or_initialize_by_email` for create path in Story 2.2

### Review Findings

- [x] [Review][Patch] Strip/cap `q` and harden `page` parsing [app/controllers/leads_controller.rb] — applied
- [x] [Review][Patch] Sync search input with `meta.q`; stop using `replace: true` [app/javascript/pages/leads/index.tsx] — applied
- [x] [Review][Patch] Safe association serialization; send value as string not float [app/controllers/leads_controller.rb] — applied
- [x] [Review][Patch] Add pagination / whitespace / array-page tests [test/controllers/leads_controller_test.rb] — applied
- [x] [Review][Defer] Closed leads still appear in index — deferred, AC lists all assigned; not open-only
- [x] [Review][Defer] USD hardcoded for estimated value — deferred, MVP course demo
- [x] [Review][Patch] Require unique email (presence + DB index + find_or_initialize) [app/models/lead.rb] — applied (post-done scope)
- [x] [Review][Patch] Tighten email unique index + blank CHECK; harden array `q` [db/migrate, leads_controller] — applied
- [x] [Review][Patch] Assistant scope, case-insensitive search, email update/non-overwrite tests — applied
- [x] [Review][Defer] Wire `find_or_initialize_by_email` into create path — deferred, Story 2.2
- [x] [Review][Defer] Rescue concurrent RecordNotUnique on create — deferred, Story 2.2

### File List

- app/controllers/leads_controller.rb
- app/models/lead.rb
- app/javascript/pages/leads/index.tsx
- test/controllers/leads_controller_test.rb
- test/models/lead_test.rb
- db/migrate/20260713205648_add_unique_email_index_to_leads.rb
- db/migrate/20260713205933_require_email_on_leads.rb
- db/migrate/20260713210214_tighten_lead_email_uniqueness.rb
- docs/IMPLEMENTATION.md
- docs/project-context.md
- docs/DATA_MODEL.md
- _bmad-output/implementation-artifacts/sprint-status.yaml
- _bmad-output/implementation-artifacts/stories/2-1-leads-index-with-search.md
