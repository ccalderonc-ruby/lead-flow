---
baseline_commit: d2619058ca17cd31d60dae34fa9f2fe1bf6ef095
---

# Story 2.4: Lead detail page

Status: done

<!-- Ultimate context engine analysis completed - comprehensive developer guide created -->

## Story

As a **User**,
I want to view a lead with all related activity,
So that I have full context before a call (UJ-2).

**Epic:** 2 — Manage Leads  
**Week:** 2  
**Fulfills:** FR-7, UX-DR4  
**Depends on:** Stories 1.3 ✅, 2.1 ✅, 2.3 ✅  
**Unblocks:** Epic 3 notes timeline / task actions on detail; create/update can redirect to show

---

## Acceptance Criteria

1. **Given** I am authorized (Admin any; Assistant any; Advisor assigned only)  
   **When** I visit `/leads/:id`  
   **Then** I see lead fields (name, email, phone, estimated value, last activity) plus company, stage, country, and assigned advisor  
   **And** I see sections for **tasks**, **meetings**, **notes**, and **opportunities** showing **counts and short preview lists** (not full CRUD — that is Epic 3/4)

2. **Given** I am an Advisor not assigned to the lead  
   **When** I visit `/leads/:id`  
   **Then** access is denied via scoped find → **404** (same fail-closed pattern as edit; do not invent a separate 403 path)

3. **Given** I am an Assistant  
   **When** I visit `/leads/:id`  
   **Then** I can view the lead (read-only)  
   **And** I do **not** see an Edit CTA (`can_update: false`)

4. **Given** I am on the leads index and may view a lead  
   **When** I click the lead **name**  
   **Then** I navigate to `/leads/:id`

5. **Given** create or update of a lead succeeds  
   **When** the save completes  
   **Then** redirect to `/leads/:id` (Lead Detail) with the existing flash notice  
   **Note:** Restores Story 2.2 / FR-6 preference now that show exists; list redirect was temporary for 2.2–2.3.

---

## Tasks / Subtasks

- [x] **Routes** (AC: 1)
  - [x] Expand to `resources :leads, only: %i[index show new create edit update]`

- [x] **Controller** (AC: 1–3, 5)
  - [x] Extend `before_action :set_lead` to include `show`
  - [x] `show` — `authorize @lead`; render `leads/show` with detail props
  - [x] Eager-load associations needed for detail + previews (`company`, `country`, `stage`, `user`, and related collections or counters)
  - [x] Pass `can_update: policy(@lead).update?`
  - [x] On successful create/update in `save_lead!`, `redirect_to lead_path(lead)` (not `leads_path`)
  - [x] Update create/update integration tests that assert `redirected_to leads_path` → `lead_path(...)`

- [x] **Inertia page** (AC: 1, 3–4 / UX-DR4)
  - [x] New `app/javascript/pages/leads/show.tsx` wrapped in `AuthenticatedPage`
  - [x] Header: lead name, Back to leads, Edit link when `can_update`
  - [x] Summary block for core fields + company / stage / country / advisor
  - [x] Four sections (tasks, meetings, notes, opportunities): count badge + preview rows (empty state when none)
  - [x] Index: wrap lead name in `Link` to `/leads/${id}` (keep Edit in Actions column)

- [x] **Tests**
  - [x] Assigned advisor / admin / assistant can GET show → success + component `leads/show`
  - [x] Advisor cannot show unassigned lead → 404
  - [x] Unauthenticated → login
  - [x] Assistant show has `can_update: false`; advisor/admin assigned show has `can_update: true` when appropriate
  - [x] Related-record counts/previews present for fixture lead with children (`leads(:sarah)`)
  - [x] Create + update success redirect to `lead_path`

- [x] **Docs**
  - [x] `docs/IMPLEMENTATION.md` — Step for lead detail; update “not implemented” table
  - [x] `docs/project-context.md` — mark Lead detail done; nudge create/update redirect note if needed

### Review Findings

- [x] [Review][Patch] Parse date-only ISO strings without local TZ day-shift [app/javascript/pages/leads/show.tsx:72]
- [x] [Review][Patch] Order meeting previews with `scheduled_on DESC NULLS LAST` [app/controllers/leads_controller.rb:198]
- [x] [Review][Patch] Assert show response includes company/stage/country/advisor/phone and related counts [test/controllers/leads_controller_test.rb]
- [x] [Review][Patch] Document `last activity` in IMPLEMENTATION Step 11 fields table [docs/IMPLEMENTATION.md]

- [x] [Review][Defer] Eight COUNT+SELECT queries per show — deferred, acceptable for MVP fixture sizes
- [x] [Review][Defer] Meeting preview omits start_time — deferred, Epic 4 meeting UX
- [x] [Review][Defer] Raw status strings / no mailto-tel / inert related rows — deferred, polish + Epic 3/4 write flows
- [x] [Review][Defer] Back-to-leads drops index search/page params — deferred, same pattern as edit
- [x] [Review][Defer] Duplicated currency/date helpers across leads pages — deferred, extract later if needed
- [x] [Review][Defer] Note truncate mid-grapheme / mid-word — deferred, rare for seeded content

---

## Dev Notes

### MUST follow

1. **Authorize the record:** `authorize @lead` after `policy_scope(Lead).find` — same as edit.
2. **Assistant can show, cannot update** — already in `LeadPolicy`; surface with `can_update` only.
3. **Inertia:** inherit `InertiaController`; props JSON-serializable; page `leads/show`.
4. **Previews only** — do not add New Task / New Note modals, note compose, or opportunity CRUD (Stories 3.x / 4.x).
5. **No tags/teams UI** — Tier 2; skip unless already trivial.
6. **Do not** use Formik or raw `fetch`.

### Recommended show props shape

```ruby
{
  lead: {
    id:, name:, email:, phone:, estimated_value: (string),
    last_activity_at: (iso8601),
    company: name, country: name, stage: name, advisor: name,
    can_update: policy(lead).update?
  },
  tasks: { count:, items: [{ id:, title:, due_date:, status: }] },
  meetings: { count:, items: [{ id:, title:, scheduled_on:, status: }] },
  notes: { count:, items: [{ id:, content_preview:, author:, created_at: }] },
  opportunities: { count:, items: [{ id:, title:, value:, stage: }] }
}
```

Preview `items`: newest-first, cap ~5. `content_preview`: truncate note content server-side (e.g. 120 chars).

Eager-load example:

```ruby
@lead = policy_scope(Lead)
  .includes(:company, :country, :stage, :user, :tasks, :meetings, :notes, opportunities: :stage)
  .find(params[:id])
```

Or load counts + limited queries in `show_props` to avoid loading huge collections — either is fine for MVP fixture sizes.

### Index name link

```tsx
<Link href={`/leads/${lead.id}`} className="...">
  {lead.name}
</Link>
```

Any authenticated user who can see the row can open show (index already role-scoped).

### Create/update redirect

In `save_lead!` change:

```ruby
redirect_to lead_path(lead)
```

Update **all** controller tests that expect `leads_path` after create/update.

### UX / Visily

- UX-DR4: sections/tabs for related records — **sections** are enough for MVP (no client tab router required).
- Match existing leads pages: `text-2xl` title, slate/indigo Tailwind, `AuthenticatedPage`.
- No `docs/design/` export in repo — follow index/edit visual language.

### Do NOT

- Do not implement notes timeline CRUD (Story 3.3) or task complete (3.2)
- Do not add meetings/opportunities write flows
- Do not change LeadPolicy show/scope semantics
- Do not redirect assistants away from show
- Do not over-fetch unbounded related records without a limit

### Previous story intelligence (2.3)

- Shared `LeadForm`; edit uses `key={lead.id}`
- `policy_scope` → 404 for unassigned advisor (deferred intentional)
- Index already has `can_update` per row
- Create/update shared via `save_lead!` — single place to flip success redirect
- Tests assert Inertia component string in response body (`'"component":"leads/edit"'`)

### Git / branch

- Branch: `feature/epic-2-manage-leads`
- Baseline: `d261905` (Story 2.3)
- Target PR base when ready: `dev`

### References

- [epics.md Story 2.4](../../planning-artifacts/epics.md)
- [PRD FR-7](../../planning-artifacts/prds/prd-leadflow-crm-2026-07-05/prd.md)
- [Story 2.3](./2-3-edit-lead.md)
- [LeadPolicy](../../../app/policies/lead_policy.rb)
- [LeadsController](../../../app/controllers/leads_controller.rb)
- [leads/index.tsx](../../../app/javascript/pages/leads/index.tsx)
- [docs/DATA_MODEL.md](../../../docs/DATA_MODEL.md)
- [docs/project-context.md](../../../docs/project-context.md)

### Project structure (files to touch)

| Path | Action |
|------|--------|
| `config/routes.rb` | UPDATE — add `:show` |
| `app/controllers/leads_controller.rb` | UPDATE — show + redirect + serializers |
| `app/javascript/pages/leads/show.tsx` | NEW |
| `app/javascript/pages/leads/index.tsx` | UPDATE — name → detail Link |
| `test/controllers/leads_controller_test.rb` | UPDATE |
| `docs/IMPLEMENTATION.md` | UPDATE |
| `docs/project-context.md` | UPDATE |
| `sprint-status.yaml` | UPDATE |

---

## Dev Agent Record

### Agent Model Used

Composer (dev-story)

### Debug Log References

- Rebuilt Vite test assets (`bin/vite build --mode=test`) after adding `leads/show` entrypoint

### Completion Notes List

- Added `/leads/:id` show with field summary + task/meeting/note/opportunity counts and previews (cap 5)
- Index lead names link to detail; Edit CTA unchanged via `can_update`
- Create/update success now redirects to `lead_path` (Story 2.2 / FR-6 alignment)
- 130 tests passing; `npm run check` clean

### File List

- `config/routes.rb`
- `app/controllers/leads_controller.rb`
- `app/javascript/pages/leads/show.tsx`
- `app/javascript/pages/leads/index.tsx`
- `test/controllers/leads_controller_test.rb`
- `docs/IMPLEMENTATION.md`
- `docs/project-context.md`
- `_bmad-output/implementation-artifacts/stories/2-4-lead-detail-page.md`
- `_bmad-output/implementation-artifacts/sprint-status.yaml`

### Change Log

- 2026-07-13: Implemented Story 2.4 lead detail; status → review
- 2026-07-13: Applied all code-review patches; status → done
