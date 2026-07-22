---
baseline_commit: e1f09010376928bbc178bc4fa9f91b51b027fcc7
---

# Story 3.1: Tasks list with filters

Status: done

<!-- Ultimate context engine analysis completed - comprehensive developer guide created -->

## Story

As an **Advisor**,
I want a tasks list filtered by mine, overdue, or all,
So that I prioritize follow-ups (UJ-6).

**Epic:** 3 — Track Follow-Ups  
**Week:** 3  
**Fulfills:** FR-8 (list + filters only), UX-DR5 (list portion)  
**Depends on:** Stories 1.3 ✅, 2.4 ✅  
**Unblocks:** Story 3.2 (create/complete from list + lead detail)

---

## Acceptance Criteria

1. **Given** I am authenticated and visit `/tasks`  
   **When** the page loads  
   **Then** I see a table of tasks **scoped to my role** with columns: **title**, **lead**, **due date**, **status**, **assignee**  
   **And** results are paginated (25 per page, same pattern as leads index)

2. **Given** I select filter **Overdue**  
   **When** applied  
   **Then** only **pending** tasks with **`due_date < today`** appear (within my role scope)  
   **Note:** Do **not** reuse `Task.overdue` for this filter — dashboard scope is broader (`in_progress` / `status: overdue`). AC is stricter.

3. **Given** I select filter **Mine**  
   **When** applied  
   **Then** I see only tasks assigned to me (`tasks.user_id = current_user.id`) within role scope

4. **Given** I select filter **All** (default)  
   **When** applied  
   **Then** I see the full role-scoped set (`TaskPolicy::Scope`)

5. **Given** I am an Advisor  
   **When** I view the list  
   **Then** I only see tasks on **leads assigned to me** (existing scope) — not org-wide

---

## Tasks / Subtasks

- [x] **Controller** (AC: 1–5)
  - [x] `authorize Task` + `policy_scope(Task)`
  - [x] Param `filter` ∈ `all|mine|overdue` (default `all`); sanitize like leads `q`
  - [x] Apply filter after scope; paginate 25/page; order by `due_date ASC, id ASC`
  - [x] Props: `{ tasks, meta: { filter, page, per_page, total_count, total_pages } }`
  - [x] Eager-load `:lead, :user`

- [x] **Inertia page** (AC: 1–4)
  - [x] Replace `PlaceholderPage` in `tasks/index.tsx`
  - [x] Filter control (All / Mine / Overdue) via `router.get('/tasks', { filter, page: 1 }, { preserveState: true })`
  - [x] Table + empty state + pagination Prev/Next
  - [x] **Do not** add New Task / Complete UI (Story 3.2)

- [x] **Fixtures + tests**
  - [x] Expand fixtures as needed (future pending, completed past-due) for filter edge cases
  - [x] Controller tests: auth required; advisor scope; all/mine/overdue filters; assistant/admin see broader scope
  - [x] Policy scope tests if not already covered

- [x] **Docs**
  - [x] `docs/IMPLEMENTATION.md` step for tasks list
  - [x] `docs/project-context.md` — tasks list shipped

### Review Findings

- [x] [Review][Patch] Redirect invalid `filter` to canonical All URL so props and query string match [app/controllers/tasks_controller.rb]
- [x] [Review][Patch] Assert serialized task shape + pagination meta in controller tests [test/controllers/tasks_controller_test.rb]
- [x] [Review][Patch] Add `aria-pressed` (and radiogroup label) on filter buttons [app/javascript/pages/tasks/index.tsx]
- [x] [Review][Patch] Tighten `TasksMeta.filter` type (drop `| string`); guard `formatDate` against invalid dates [app/javascript/pages/tasks/index.tsx]

- [x] [Review][Defer] Overdue list vs `Task.overdue`/dashboard diverge by design (AC pending-only) — deferred, document if product wants unify later
- [x] [Review][Defer] Shared fixtures bump dashboard overdue counts — deferred, acceptable coupling for MVP
- [x] [Review][Defer] Status humanization / filter-aware empty copy — deferred, polish
- [x] [Review][Defer] Clamped `page` left in URL / preserveState races — deferred, same pattern as leads index
- [x] [Review][Defer] Broader TaskPolicy action tests beyond index/scope — deferred, Story 3.2+ when write paths ship

---

## Dev Notes

### MUST follow

1. Inherit `InertiaController`; `AuthenticatedPage`.
2. `authorize Task` before querying.
3. Overdue filter = `status: "pending"` AND `due_date < Date.current` only.
4. Role scope comes from existing `TaskPolicy::Scope` — do not reinvent (advisor = tasks on leads they own).
5. Reuse leads index UX patterns (table, slate/indigo, meta pagination).
6. **Do not** implement create/complete/modals (3.2) or notes timeline (3.3).

### Filter application sketch

```ruby
scoped = policy_scope(Task)
scoped =
  case filter
  when "mine" then scoped.where(user_id: current_user.id)
  when "overdue" then scoped.where(status: "pending").where("due_date < ?", Date.current)
  else scoped # "all"
  end
```

### Serialize row

```ruby
{
  id:, title:,
  lead: lead&.name,
  lead_id: lead&.id, # optional link to /leads/:id
  due_date: due_date&.iso8601,
  status:,
  assignee: user&.name
}
```

Optional: link lead name to `/leads/:id` (nice-to-have, reuse detail from 2.4).

### Role cheat sheet

| Role | All | Mine | Overdue |
|------|-----|------|---------|
| Admin | All tasks | Assigned to admin | Pending past-due (all) |
| Assistant | All tasks | Assigned to assistant | Pending past-due (all) |
| Advisor | On their leads | On their leads + assigned to them | On their leads + pending past-due |

### Do NOT

- Do not change `Task.overdue` dashboard scope as part of this story
- Do not add New Task button / modal
- Do not mark tasks complete
- Do not build notes UI

### Previous epic intelligence

- Leads index: param sanitization, page clamp, `includes`, Inertia meta
- Lead detail already shows task previews — list is the full workspace
- Epic 2 retro: lead-detail CTAs are Story 3.2; form remount deferred

### Git / branch

- Branch: `feature/epic-3-track-follow-ups`
- Baseline: `e1f0901` (Epic 2 on `dev`)
- Target PR base: `dev`

### References

- [epics.md Story 3.1](../../planning-artifacts/epics.md)
- [TaskPolicy](../../../app/policies/task_policy.rb)
- [LeadsController#index](../../../app/controllers/leads_controller.rb)
- [leads/index.tsx](../../../app/javascript/pages/leads/index.tsx)
- [DashboardMetrics / Task.overdue](../../../app/models/task.rb)

### Project structure

| Path | Action |
|------|--------|
| `app/controllers/tasks_controller.rb` | UPDATE |
| `app/javascript/pages/tasks/index.tsx` | UPDATE |
| `test/fixtures/tasks.yml` | UPDATE |
| `test/controllers/tasks_controller_test.rb` | NEW |
| `test/policies/task_policy_test.rb` | NEW or UPDATE if missing |
| `docs/IMPLEMENTATION.md` | UPDATE |
| `docs/project-context.md` | UPDATE |
| `sprint-status.yaml` | UPDATE |

---

## Dev Agent Record

### Agent Model Used

Composer (dev-story)

### Debug Log References

### Completion Notes List

- `/tasks` list with All / Mine / Overdue; role scope via TaskPolicy; overdue = pending + due_date < today
- Lead name links to detail; no create/complete UI (deferred to 3.2)
- Added fixtures for future/completed/assistant-assigned tasks; dashboard overdue expectations updated
- 141 tests passing; `npm run check` clean

### File List

- `app/controllers/tasks_controller.rb`
- `app/javascript/pages/tasks/index.tsx`
- `test/fixtures/tasks.yml`
- `test/controllers/tasks_controller_test.rb`
- `test/policies/task_policy_test.rb`
- `test/services/dashboard_metrics_test.rb`
- `test/controllers/dashboard_controller_test.rb`
- `docs/IMPLEMENTATION.md`
- `docs/project-context.md`
- `_bmad-output/implementation-artifacts/stories/3-1-tasks-list-with-filters.md`
- `_bmad-output/implementation-artifacts/sprint-status.yaml`

### Change Log

- 2026-07-13: Implemented Story 3.1 tasks list with filters; status → review
- 2026-07-14: Applied all code-review patches; status → done
