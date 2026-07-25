---
baseline_commit: 54b7970a40aa287c0507d2296c3c8e5820a8b526
---

# Story 6.1: Mark overdue tasks job

Status: done

<!-- Ultimate context engine analysis completed - comprehensive developer guide created -->

## Story

As the **system**,
I want to mark pending tasks past due as overdue daily,
So that dashboards and filters stay accurate (UJ-6).

**Epic:** 6 — Ship as a SaaS  
**Week:** 6  
**Fulfills:** FR-16  
**Depends on:** Story 3.1–3.2 tasks ✅, Solid Queue gem scaffold ✅  
**Unblocks:** Epic 6.2+ (Stripe); demo path UJ-6

---

## Acceptance Criteria

1. **Given** Solid Queue recurring config  
   **When** `MarkOverdueTasksJob` runs  
   **Then** tasks with `status: pending` and `due_date < Date.current` become `status: overdue`

2. **Given** the job runs twice  
   **When** no additional pending-past-due tasks exist  
   **Then** already-overdue tasks are unchanged (no error, no duplicate rows)

3. **Given** tasks marked `overdue` by the job  
   **When** a user opens Tasks with filter `overdue` or Completes an overdue task  
   **Then** overdue tasks still appear in the overdue filter  
   **And** Complete still works for overdue (not only `pending`) — otherwise the job breaks UJ-6

4. **Given** docs  
   **When** done  
   **Then** `docs/IMPLEMENTATION.md` has **Step 22** for Story 6.1

5. **Given** Epic 5 process  
   **When** shipping  
   **Then** work is on branch `feature/6-1-mark-overdue-tasks-job` from current `dev`; PR into **`dev`**; merge before starting 6.2

---

## Tasks / Subtasks

- [x] **Job** (AC: 1–2)
  - [x] Add `app/jobs/mark_overdue_tasks_job.rb` inheriting `ApplicationJob`
  - [x] Idempotent update: `Task.pending.where("due_date < ?", Date.current)` → `status: :overdue` (prefer bulk `update_all` or scoped `update_all` with enum value string `"overdue"`)
  - [x] Do **not** touch `completed`, already `overdue`, or future-dated pending
  - [x] Do **not** invent a new status; use existing enum key `overdue`

- [x] **Recurring schedule** (AC: 1)
  - [x] Add entry under `production:` in `config/recurring.yml` (class `MarkOverdueTasksJob`, daily schedule — match Solid Queue 1.4 recurring YAML style already used by `clear_solid_queue_finished_jobs`)
  - [x] Optionally mirror under `development:` so local `SOLID_QUEUE_IN_PUMA=1` demos the schedule (document how to run once: `bin/rails runner "MarkOverdueTasksJob.perform_now"`)

- [x] **Keep UJ-6 working after status flip** (AC: 3) — **required companion, not polish**
  - [x] `TasksController#apply_filter` `"overdue"`: stop selecting only `pending` + past due; align with `Task.overdue` scope (or `status: overdue` OR pending/in_progress past due)
  - [x] Allow Complete from `overdue` as well as `pending` (`can_complete?`, update action guard, lead show `can_complete`)
  - [x] Update controller tests that assert “overdue filter only pending past due”

- [x] **Tests** (AC: 1–3)
  - [x] Job test: pending + past due → overdue; future pending unchanged; completed unchanged; second run safe
  - [x] Controller (or existing tasks tests): overdue filter includes `status: overdue`; complete from overdue succeeds

- [x] **Docs + sprint**
  - [x] IMPLEMENTATION Step 22; refresh Not-done / project-context “Background job” row
  - [x] Story → review when green; `6-1-mark-overdue-tasks-job` → review then done after code review

### Review Findings

- [x] [Review][Defer] Daily schedule timezone unspecified [`config/recurring.yml`] — deferred, pre-existing (`config.time_zone` commented out); course demo OK with `Date.current` + documented `perform_now`
- [x] [Review][Defer] Nil `Task.status` excluded from job and overdue scope [`app/models/task.rb`] — deferred, pre-existing `allow_nil`; creates always set `pending`; AC is pending-only

---

## Dev Notes

### MUST follow

1. **Epic 5 retro:** branch-per-story; merge to `dev` before 6.2; elevated care on jobs (idempotent, no silent data damage). Triage: `docs/BUG_POLISH_TRIAGE.md` — trust/data mutations = patch now.
2. Model is **`Task`**, table `tasks` — not FollowUpTask. Enum already includes `overdue` ([Source: `app/models/task.rb`]).
3. **Timezone:** compare dates with `Date.current` (app TZ), not `Time.now` / UTC date unless config says otherwise. `due_date` is a **date** column.
4. **Dashboard already works:** `Task.overdue` scope counts status overdue **or** pending/in_progress past due ([Source: `app/models/task.rb`, `app/services/dashboard_metrics.rb`]). Job makes status match; do not break the scope.
5. **Known gap today:** tasks index overdue filter is **narrower** than `Task.overdue` — only `pending` + `due_date < today` ([Source: `app/controllers/tasks_controller.rb` `apply_filter`]). After the job, those rows become `overdue` and would **vanish** from the filter unless you fix AC3.
6. **Complete gap:** `can_complete?` / update require `pending?` only — overdue tasks become uncompletable unless fixed with AC3.
7. Do **not** change Stripe/subscription or deploy in this story.
8. Prefer `update_all` for the job body (no callbacks needed; Task has no overdue-specific callbacks). If using `update_all` with enums, set the DB string `"overdue"` (Rails enum storage).
9. Recurring YAML currently has only production cleanup ([Source: `config/recurring.yml`]). Solid Queue gem `1.4.0`; production uses `config.active_job.queue_adapter = :solid_queue` + separate `queue` DB. Dev defaults to `:async` unless `SOLID_QUEUE_IN_PUMA` — **job tests should call `perform_now`**, not rely on the queue DB.
10. Frozen string literal on new Ruby files; RuboCop Omakase.

### Current code (read before editing)

| File | Role |
|------|------|
| `app/models/task.rb` | enum + `scope :overdue` |
| `app/jobs/application_job.rb` | base class only |
| `config/recurring.yml` | production cleanup only — **extend** |
| `config/queue.yml` | Solid Queue workers (already) |
| `app/controllers/tasks_controller.rb` | overdue filter + complete guards — **UPDATE for AC3** |
| `app/controllers/leads_controller.rb` | show preview `can_complete: task.pending?` — **UPDATE for AC3** |
| `test/fixtures/tasks.yml` | several `pending` with `due_date: 2026-07-01` (past relative to “today” in Jul 2026+) |
| `app/services/demo_seeds.rb` | seeds past-due pending tasks — job will flip them when run |

### Suggested job shape

```ruby
class MarkOverdueTasksJob < ApplicationJob
  queue_as :default

  def perform
    Task.pending.where("due_date < ?", Date.current)
      .update_all(status: Task.statuses[:overdue], updated_at: Time.current)
  end
end
```

(Adjust if project prefers not touching `updated_at`; either is fine if tests don’t assert it.)

### Recurring example (Solid Queue 1.4)

```yaml
production:
  mark_overdue_tasks:
    class: MarkOverdueTasksJob
    queue: default
    schedule: at 1am every day
  clear_solid_queue_finished_jobs:
    # existing…
```

### Git / branch

- Baseline: `54b7970` (merge of PR #30 / Epic 5 on `dev`)
- Branch: `feature/6-1-mark-overdue-tasks-job` from latest `origin/dev`
- PR base: **`dev`**
- Do **not** stack 6.2 on this branch before merge

### References

- [epics.md Story 6.1](../../planning-artifacts/epics.md) — FR-16 ACs
- [PRD FR-16 / UJ-6](../../planning-artifacts/prds/prd-leadflow-crm-2026-07-05/prd.md)
- [Epic 5 retro](../epic-5-retro-2026-07-25.md) — branch-per-story + job care
- [BUG_POLISH_TRIAGE](../../../docs/BUG_POLISH_TRIAGE.md)
- [Task model](../../../app/models/task.rb)
- [TasksController](../../../app/controllers/tasks_controller.rb)

### Verification

```bash
bin/rails test test/jobs/mark_overdue_tasks_job_test.rb test/controllers/tasks_controller_test.rb test/models/task_test.rb
bin/rails runner "MarkOverdueTasksJob.perform_now"
npm run check   # only if TS touched (likely none)
```

### Out of scope / defer

- Marking `in_progress` past-due (AC says **pending** only; dashboard scope already treats in_progress past due as overdue without status flip)
- Frontend unit tests for tasks filter
- Enabling Solid Queue in development by default (document optional `SOLID_QUEUE_IN_PUMA`)
- Stripe / CSV / Kamal (6.2–6.4)

---

## Dev Agent Record

### Agent Model Used

Composer (dev-story)

### Debug Log References

### Completion Notes List

- Added `MarkOverdueTasksJob` with idempotent `update_all` for pending past-due → overdue.
- Registered daily recurring schedule in `config/recurring.yml` (production + development).
- Aligned tasks overdue filter with `Task.overdue`; Complete works for pending and overdue (tasks + lead show).
- Tests: job unit tests + controller overdue/complete coverage; full suite 246 green.
- Docs: IMPLEMENTATION Step 22; project-context jobs row updated.
- Code review: AC clean; deferred timezone + nil-status; dismissed inert default-dev Solid Queue (documented `perform_now` / optional `SOLID_QUEUE_IN_PUMA`).

### File List

- `app/jobs/mark_overdue_tasks_job.rb`
- `test/jobs/mark_overdue_tasks_job_test.rb`
- `config/recurring.yml`
- `app/controllers/tasks_controller.rb`
- `app/controllers/leads_controller.rb`
- `test/controllers/tasks_controller_test.rb`
- `docs/IMPLEMENTATION.md`
- `docs/project-context.md`
- `_bmad-output/implementation-artifacts/stories/6-1-mark-overdue-tasks-job.md`
- `_bmad-output/implementation-artifacts/sprint-status.yaml`

### Change Log

- 2026-07-25: Created Story 6.1 context; status → ready-for-dev
- 2026-07-25: Implemented MarkOverdueTasksJob + UJ-6 companion fixes; status → review
- 2026-07-25: Code review — no patches; 2 deferred; status → done
