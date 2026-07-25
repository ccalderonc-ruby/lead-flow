---
baseline_commit: 3b9bc8ccbfdee5193668ab400d079db957c311ce
---

# Story 5.4: Advanced lead filters

Status: done

<!-- Ultimate context engine analysis completed - comprehensive developer guide created -->

## Story

As an **Admin**,
I want to filter leads by stage and assigned advisor,
So that I can review team workload (UJ-2).

**Epic:** 5 — Administer the Team  
**Week:** 5 polish  
**Fulfills:** FR-5 (filters)  
**Depends on:** Story 2.1 leads index ✅, Epic 1 policies ✅  
**Unblocks:** Epic 5 retrospective (last story in epic)

---

## Acceptance Criteria

1. **Given** I am Admin on `/leads`  
   **When** I filter by **LeadStage** and/or **assigned User**  
   **Then** the table updates to matching leads  
   **And** search `q` + pagination still work together with filters

2. **Given** I am Advisor on `/leads`  
   **When** I filter by stage  
   **Then** results stay within **my assigned leads only** (`policy_scope` first)  
   **And** I do **not** get an assignee filter control (or server ignores `user_id`)

3. **Given** Assistant (or Advisor)  
   **When** they pass a forged `user_id` query param  
   **Then** it does **not** expand scope beyond `policy_scope(Lead)`

4. **Given** docs  
   **When** done  
   **Then** `docs/IMPLEMENTATION.md` has **Step 21** for Story 5.4

---

## Tasks / Subtasks

- [x] **Controller filters** (AC: 1–3)
  - [x] Parse safe `stage_id` / `user_id` (array-first, Integer or nil; invalid → ignore)
  - [x] Apply `where(stage_id:)` / `where(user_id:)` **after** `policy_scope(Lead).search(query)`
  - [x] Assignee filter **admin only**; non-admins never apply `user_id`
  - [x] Extend `meta` with `stage_id`, `user_id` (null when unset)
  - [x] Pass `stages` options (`LeadStage.order(:position)`); pass `assignees` + `can_filter_assignee` for admin (reuse `assignable_users` eligibility)

- [x] **UI** (AC: 1–2)
  - [x] Stage `SelectField` for all roles that can open `/leads`
  - [x] Assignee `SelectField` only when `can_filter_assignee`
  - [x] `router.get` retains `q`, `stage_id`, `user_id`; filter change resets `page: 1`
  - [x] Clear/empty option = no filter

- [x] **Tests** (AC: 1–3)
  - [x] Admin: stage-only, assignee-only, combined
  - [x] Advisor: stage filters own leads; cannot see other advisor’s lead via stage; `user_id` ignored
  - [x] Invalid params ignored; meta echoes applied filters; pagination keeps filters

- [x] **Docs + sprint**
  - [x] IMPLEMENTATION Step 21; Not-done table
  - [x] Story → done; `5-4-advanced-lead-filters` → done (review patches applied)

### Review Findings

- [x] [Review][Patch] Ignore nonexistent / non-assignable filter IDs [`app/controllers/leads_controller.rb:18`] — only apply `stage_id` if `LeadStage` exists; only apply admin `user_id` if in `assignable_users`; otherwise treat as unset (`nil` in meta).
- [x] [Review][Patch] Filter/pagination drops unsubmitted search text [`app/javascript/pages/leads/index.tsx:90`] — `setStageFilter` / `setAssigneeFilter` / `goToPage` should pass local `query`, not only `meta.q`.
- [x] [Review][Patch] Assignee label says “advisor” but options include admins [`app/javascript/pages/leads/index.tsx`] — rename to **Assignee** (matches FR-5 assigned user + `assignable_users`).
- [x] [Review][Patch] Add tests for ignored bad IDs + assistant stage filter [`test/controllers/leads_controller_test.rb`]
- [x] [Review][Defer] No frontend Inertia filter tests — deferred, residual (repo pattern is controller/integration)
- [x] [Review][Defer] Stages/assignees loaded every index request — deferred, fine for course scale

---

## Dev Notes

### MUST follow

1. **Extend** existing `q` + pagination — do **not** rewrite `Lead.search` or client-filter the table.
2. Always: `policy_scope(Lead)` → search → filters → count/page.
3. Use `SelectField` from FormFields.
4. Match tasks index navigation: `router.get(..., { preserveState: true })`.
5. Existing leads `useEffect` for search input sync is OK to keep.
6. Triage: `docs/BUG_POLISH_TRIAGE.md`.

### Git / branch

- Baseline: `3b9bc8c` (Epic 5.1–5.3 commit)
- Branch: `feature/5-4-advanced-lead-filters`
- PR base: **`dev`**

### References

- [epics.md Story 5.4](../../planning-artifacts/epics.md)
- [PRD FR-5](../../planning-artifacts/prds/prd-leadflow-crm-2026-07-05/prd.md)
- [LeadsController](../../../app/controllers/leads_controller.rb)
- [BUG_POLISH_TRIAGE](../../../docs/BUG_POLISH_TRIAGE.md)

### Verification

```bash
bin/rails test test/controllers/leads_controller_test.rb
npm run check
```

---

## Dev Agent Record

### Agent Model Used

Composer (create-story + dev-story)

### Debug Log References

### Completion Notes List

- Extended leads index with `stage_id` / admin-only `user_id` after `policy_scope` + search.
- UI: FormFields stage select for all; assignee select when `can_filter_assignee`.
- Filters compose with `q` and pagination; invalid IDs ignored.
- Tests: 8 new filter cases; full suite 236 green; `npm run check` clean.
- Docs: IMPLEMENTATION Step 21.
- Code review patches: validate stage/assignee existence; preserve local search on filter/page; rename Assignee label; extra tests.

### File List

- `app/controllers/leads_controller.rb`
- `app/javascript/pages/leads/index.tsx`
- `test/controllers/leads_controller_test.rb`
- `docs/IMPLEMENTATION.md`
- `docs/project-context.md`
- `_bmad-output/implementation-artifacts/stories/5-4-advanced-lead-filters.md`
- `_bmad-output/implementation-artifacts/sprint-status.yaml`

### Change Log

- 2026-07-22: Created Story 5.4 context; status → ready-for-dev
- 2026-07-22: Implemented stage + admin assignee filters; status → review
- 2026-07-25: Applied code-review patches; status → done
