---
baseline_commit: 1be198b6c34b3186c10b5b61434ac3951c7e2470
---

# Story 2.3: Edit lead

Status: done

<!-- Ultimate context engine analysis completed - comprehensive developer guide created -->

## Story

As an **Advisor**,
I want to update lead information,
So that records stay accurate as deals progress.

**Epic:** 2 — Manage Leads  
**Week:** 2  
**Fulfills:** FR-6, UX-DR3  
**Depends on:** Stories 1.3 ✅, 2.2 ✅  
**Unblocks:** Story 2.4 (detail can link to edit; post-save redirect may switch to show)

---

## Acceptance Criteria

1. **Given** I am an Admin or the assigned Advisor on `/leads/:id/edit`  
   **When** I submit valid changes (name, email, company name, company country, lead country, stage, assigned user)  
   **Then** the lead is updated  
   **And** I am redirected to `/leads` with a flash notice  
   **Note:** FR-6 allows Detail or list. Detail is Story 2.4 — list redirect for this story (same as 2.2).

2. **Given** I am an Advisor not assigned to the lead  
   **When** I visit `/leads/:id/edit` or PATCH update  
   **Then** access is denied (Story 1.3 / `LeadPolicy#update?`)

3. **Given** I am an Assistant  
   **When** I visit edit or PATCH update  
   **Then** access is denied

4. **Given** required fields are missing or invalid, or email is taken by another lead  
   **When** I submit  
   **Then** Inertia validation errors display inline on the form  
   **And** the lead is not overwritten with invalid data

5. **Given** I change the company name to a typo/punctuation variant of an existing company  
   **When** the form saves  
   **Then** `Company.find_or_initialize_by_name` reuses that company (no duplicate)

6. **Given** I am on the leads index and may update a row’s lead  
   **When** `can_update` is true for that lead  
   **Then** I see an Edit link to `/leads/:id/edit`

---

## Tasks / Subtasks

- [x] **Routes** (AC: 1)
  - [x] Expand to `resources :leads, only: %i[index new create edit update]`

- [x] **Controller** (AC: 1–5)
  - [x] `before_action` / `set_lead` for edit/update — load via `policy_scope(Lead).find(params[:id])` then `authorize @lead`
  - [x] `edit` — render `leads/edit` with form props + current lead values (including company name / company country)
  - [x] `update` — reuse create’s company + assignment helpers; **do not** use create’s “reject if `find_or_initialize_by_email` persisted” path — update **this** lead in place
  - [x] On email change colliding with another lead → uniqueness error (model + `RecordNotUnique` rescue)
  - [x] On failure: redirect to `edit_lead_path(@lead)` with `inertia: { errors: … }` (server should also re-pass form props / lead values as needed)
  - [x] On success: `flash[:notice] = "Lead updated."` → `redirect_to leads_path`
  - [x] Advisor: force `user_id = current_user.id` on update (cannot reassign away); Admin: allowlist assignee

- [x] **Inertia page** (AC: 1, 4–6 / UX-DR3)
  - [x] Prefer extract shared form used by new + edit **or** thin `edit.tsx` that mirrors `new.tsx` with `useForm` + `put`/`patch` to `/leads/:id`
  - [x] Prefill all fields from lead props; include company country checkbox (`update_existing_company_country`, default false)
  - [x] Index: per-row Edit link when authorized (pass `can_update` on each serialized lead **or** compute client-side only if auth + assignment known — prefer server `can_update: policy(lead).update?` on each row)

- [x] **Tests**
  - [x] Assigned advisor / admin can edit + update → redirect + flash + DB change
  - [x] Advisor cannot edit/update admin-owned lead
  - [x] Assistant denied on edit/update
  - [x] Unauthenticated → login
  - [x] Validation errors + duplicate email (other lead) on update
  - [x] Company name variant reuses company; checkbox updates country when opted in
  - [x] Advisor assignment remains self after update even if tampered `user_id`
  - [x] Policy: assistant `update?` false (if not already)

- [x] **Docs**
  - [x] Update `docs/IMPLEMENTATION.md` Step for edit lead
  - [x] Update `docs/project-context.md` (edit lead shipped)

### Review Findings

- [x] [Review][Patch] Add admin GET edit + PATCH update (incl. reassignment) tests [test/controllers/leads_controller_test.rb]
- [x] [Review][Patch] Assert update path for company-country checkbox opt-in [test/controllers/leads_controller_test.rb]
- [x] [Review][Patch] Assert index `can_update:false` for assistant (no Edit CTA) [test/controllers/leads_controller_test.rb]
- [x] [Review][Patch] Add `key={lead.id}` so Inertia remounts form when editing a different lead [app/javascript/pages/leads/edit.tsx]
- [x] [Review][Patch] On update, only clear optional phone/estimated_value when those keys are present [app/controllers/leads_controller.rb]
- [x] [Review][Patch] Include current assignee in admin assignees list even if inactive/ineligible [app/controllers/leads_controller.rb]
- [x] [Review][Patch] Reject non-numeric `estimated_value` instead of silently nulling [app/controllers/leads_controller.rb]

- [x] [Review][Defer] Validation-failure remount shows DB values not submitted payload — deferred, same Inertia pattern as Story 2.2
- [x] [Review][Defer] Updating shared company country affects other leads on that company — deferred, product behavior with checkbox warning
- [x] [Review][Defer] No optimistic lock / stale update protection on concurrent edits — deferred, MVP out of scope
- [x] [Review][Defer] Unassigned advisor gets 404 via `policy_scope` rather than Pundit 403 — deferred, intentional fail-closed scoping

---

## Dev Notes

### MUST follow

1. **Authorize the record:** `authorize lead` after scoped find — not class-level `authorize Lead` alone.
2. **Email:** required + unique excluding self. Update attributes on `@lead`; if email taken by another → Inertia error. Never call create’s “persisted find_or_initialize reject” path for update.
3. **Company:** same as 2.2 — `find_or_initialize_by_name`, keep existing HQ country unless `update_existing_company_country`, blank-company guard, `RecordNotUnique` discrimination (company vs email), `InvalidForeignKey` rescue, preflight validation so company + lead errors both surface.
4. **Inertia:** `useForm` only; inherit `InertiaController`; `AuthenticatedPage`.
5. **Do not** implement show/detail activity timeline (2.4).

### Recommended shared structure

Extract helpers already on `LeadsController` (`form_props`, `build_company_for_create` → rename to shared `build_company_from_params`, `apply_company_country!`, `assigned_user_id`, `validation_error_hash`, `not_unique_errors`).

For the React side, prefer a shared component:

```
app/javascript/pages/leads/form.tsx   # or components/leads/LeadForm.tsx
app/javascript/pages/leads/new.tsx    # wrapper
app/javascript/pages/leads/edit.tsx   # wrapper with put(`/leads/${id}`)
```

If extraction costs too much scope, duplicate `edit.tsx` from `new.tsx` and keep fields in sync — note debt in Completion Notes.

### Prefill props (edit)

Pass JSON-serializable lead form values, e.g.:

```ruby
lead: {
  id:, name:, email:, phone:, estimated_value:,
  country_id:, stage_id:, user_id:,
  company_name: lead.company&.name,
  company_country_id: lead.company&.country_id
}
```

Plus existing `form_props` (countries, stages, assignees, defaults). For edit, `force_assignee` still true for advisors.

### Index Edit CTA

Extend `serialize_lead` with `can_update: policy(lead).update?` and render Edit link next to the row (or in name cell). Assistants never get the link.

### Do NOT

- Do not build full lead detail (2.4)
- Do not add tags/teams/notes/opportunities on this form
- Do not allow advisors to reassign leads
- Do not loosen email uniqueness
- Do not add Formik / raw fetch

### Previous story intelligence (2.2)

- Create path hardened after review: checkbox for company country, `policy(Lead).create?`, preflight validations, Inertia error assertions in tests
- Local uncommitted 2.2 review patches may still be in the working tree — include them when implementing 2.3 on the same branch (or commit 2.2 patches first)
- Deferred: concurrent RecordNotUnique test; form remount after error (still true for edit redirect pattern)

### Git / branch

- Branch: `feature/epic-2-manage-leads`
- Recent: Story 2.2 create lead (`ac4620e`+)
- Target PR base when ready: `dev`

### References

- [epics.md Story 2.3](../../planning-artifacts/epics.md)
- [Story 2.2](./2-2-create-lead.md)
- [LeadPolicy](../../../app/policies/lead_policy.rb)
- [LeadsController](../../../app/controllers/leads_controller.rb)
- [leads/new.tsx](../../../app/javascript/pages/leads/new.tsx)
- [docs/project-context.md](../../../docs/project-context.md)
- [docs/DATA_MODEL.md](../../../docs/DATA_MODEL.md)

### Project structure (files to touch)

| Path | Action |
|------|--------|
| `config/routes.rb` | UPDATE |
| `app/controllers/leads_controller.rb` | UPDATE |
| `app/javascript/pages/leads/edit.tsx` | NEW |
| `app/javascript/pages/leads/new.tsx` | UPDATE if shared extract |
| `app/javascript/pages/leads/index.tsx` | UPDATE — Edit links |
| `test/controllers/leads_controller_test.rb` | UPDATE |
| `test/policies/lead_policy_test.rb` | UPDATE optional |
| `docs/IMPLEMENTATION.md` | UPDATE |
| `docs/project-context.md` | UPDATE |
| `sprint-status.yaml` | UPDATE |

---

## Dev Agent Record

### Agent Model Used

Composer (dev-story)

### Debug Log References

- Full suite: 120 tests, 391 assertions, 0 failures
- `npm run check` passes
- RuboCop clean on LeadsController

### Completion Notes List

- Routes: `edit` / `update` added
- Shared `LeadForm` extracted for new + edit
- `save_lead!` shared create/update path; edit updates in place (no find_or_initialize email reject)
- Index rows include `can_update` + Edit link
- Advisor assignment forced on update; list redirect + flash

### File List

- config/routes.rb
- app/controllers/leads_controller.rb
- app/javascript/components/leads/LeadForm.tsx
- app/javascript/pages/leads/new.tsx
- app/javascript/pages/leads/edit.tsx
- app/javascript/pages/leads/index.tsx
- test/controllers/leads_controller_test.rb
- test/policies/lead_policy_test.rb
- docs/IMPLEMENTATION.md
- docs/project-context.md
- _bmad-output/implementation-artifacts/sprint-status.yaml
- _bmad-output/implementation-artifacts/stories/2-3-edit-lead.md

### Change Log

- 2026-07-13: Implemented Story 2.3 edit lead; status → review
- 2026-07-13: Applied all code-review patches; status → done

---

## Open questions (resolved for implementer)

| Question | Decision |
|----------|----------|
| Redirect target | `/leads` + flash until Story 2.4 |
| Shared form vs copy | Prefer shared extract; copy OK if faster |
| Email on update | Change allowed; uniqueness vs other leads |
| Company country checkbox | Same as create (default keep) |
| Advisor reassignment | Forced to self server-side |
| Index Edit CTA | Yes, via per-lead `can_update` |
| Assistant deny | Explicit AC + tests |
