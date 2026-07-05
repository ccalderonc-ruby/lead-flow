# Story 1.5: Dashboard with summary metrics

Status: done

## Story

As a **User**,
I want a dashboard showing my key counts and pipeline value,
So that I know what needs attention when I start my day (UJ-1).

**Epic:** 1 — Access the CRM  
**Week:** 1  
**Fulfills:** FR-12, UX-DR1  
**Depends on:** Stories 1.3 ✅, 1.4 ✅

---

## Acceptance Criteria

1. **Given** I am authenticated as Advisor  
   **When** I visit `/`  
   **Then** I see widgets: open leads (assigned), overdue tasks, upcoming meetings (7 days), pipeline value  
   **And** counts reflect only my assigned/scoped records

2. **Given** I am authenticated as Admin  
   **When** I visit `/`  
   **Then** widgets show organization-wide totals

3. **Given** seed data is loaded  
   **When** the dashboard loads  
   **Then** it renders in under 2 seconds on dev hardware

4. **And** root route `/` renders Dashboard (`inertia_example` removed)

---

## Tasks / Subtasks

- [x] **Dashboard metrics service** (AC: 1, 2)
  - [x] `DashboardMetrics` using Pundit policy scopes
  - [x] Model scopes: open leads, overdue tasks, upcoming meetings, active pipeline

- [x] **Dashboard UI** (AC: 1, 3)
  - [x] Metric cards on `dashboard/index.tsx`
  - [x] Currency formatting for pipeline value

- [x] **Controller + cleanup** (AC: 4)
  - [x] Pass metrics props from `DashboardController`
  - [x] Remove `inertia_example` route and dead code

- [x] **Dev seeds** (AC: 3)
  - [x] Sample leads, tasks, meetings, opportunities for local dashboard

- [x] **Tests** (AC: 1, 2)
  - [x] `DashboardMetrics` unit tests (advisor vs admin scoping)
  - [x] Dashboard controller auth smoke test

- [x] **Docs**
  - [x] Update `docs/IMPLEMENTATION.md` Step 6

---

## Dev Notes

### Metric definitions

| Widget | Rule |
|--------|------|
| Open leads | Assigned/scoped leads where stage ≠ Closed |
| Overdue tasks | `status = overdue` OR (`pending`/`in_progress` AND `due_date < today`) |
| Upcoming meetings | `status = scheduled` AND `scheduled_on` within next 7 days |
| Pipeline value | Sum of opportunity `value` where stage ∉ {Won, Lost} |

### Scoping

Use existing policy scopes (`LeadPolicy::Scope`, etc.). Advisor → assigned only; Admin & Assistant → org-wide.

### Do NOT

- Do not build full CRUD or charts (Epic 2+)
- Do not implement `MarkOverdueTasksJob` (Epic 6)

### References

- [epics.md](../../planning-artifacts/epics.md#story-15-dashboard-with-summary-metrics)
- [addendum.md](../../planning-artifacts/prds/prd-leadflow-crm-2026-07-05/addendum.md)

---

## Dev Agent Record

### Agent Model Used

Composer (dev-story)

### Debug Log References

- Full suite: 75 tests, 180 assertions, 0 failures
- `npm run check` passes

### Completion Notes List

- `DashboardMetrics` aggregates four widgets via Pundit policy scopes
- Model scopes on Lead, Task, Meeting, Opportunity for reusable query logic
- Dashboard UI: four metric cards with USD pipeline formatting
- Removed `inertia_example` route, controller, and pages
- Dev seeds create sample CRM records when database is empty (re-run safe)

### Review Findings

- [x] [Review][Patch] Stale `inertia_example` references in IMPLEMENTATION.md [docs/IMPLEMENTATION.md] — applied
- [x] [Review][Patch] `Meeting` model missing `# frozen_string_literal: true` [app/models/meeting.rb] — applied
- [x] [Review][Patch] `Task.overdue` should exclude completed tasks [app/models/task.rb] — applied
- [x] [Review][Patch] Controller test only checked HTTP 200, not metrics props [test/controllers/dashboard_controller_test.rb] — applied
- [x] [Review][Defer] No automated perf assertion for 2s load AC [test/controllers/dashboard_controller_test.rb] — deferred, dev hardware check sufficient for MVP
- [x] [Review][Defer] `seed_dashboard_sample_data` defined at top level in seeds.rb [db/seeds.rb] — deferred, standard Rails seed pattern

### File List

- app/services/dashboard_metrics.rb
- app/models/lead.rb
- app/models/task.rb
- app/models/meeting.rb
- app/models/opportunity.rb
- app/controllers/dashboard_controller.rb
- app/javascript/pages/dashboard/index.tsx
- app/javascript/components/dashboard/MetricCard.tsx
- config/routes.rb
- db/seeds.rb
- test/services/dashboard_metrics_test.rb
- test/controllers/dashboard_controller_test.rb
- test/fixtures/lead_stages.yml
- test/fixtures/leads.yml
- test/fixtures/opportunity_stages.yml
- test/fixtures/opportunities.yml
- test/fixtures/tasks.yml
- docs/IMPLEMENTATION.md
- docs/project-context.md
