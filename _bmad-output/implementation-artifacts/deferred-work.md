# Deferred Work

## Deferred from: Epic 4 retrospective (2026-07-21)

- Pipeline pagination / unbounded board load — labeled; revisit if demo data grows
- Brittle `response.body` substring controller tests — strengthen in Epic 7 test pass
- Serialize/helper duplication (opportunities, fieldError, assignee queries) — extract when touching those files
- Validation remount loses submitted form values — keep redirect+reopen; promote if demo pain
- Mid-save opportunity card switch — polish if reproduced
- Counter cache / TasksTable extract / remaining professor polish — still deferred (modal a11y done)

## Deferred from: Epic 4 retrospective prep (2026-07-21)

- ~~No written bug/polish triage rule~~ ✅ `docs/BUG_POLISH_TRIAGE.md` (Project Lead + Amelia)
- ~~Modal/drawer a11y (Escape / focus trap / restore focus)~~ ✅ `useDialogA11y` on Task, Note, Meeting modals + Opportunity drawer

## Deferred from: code review of 4-3-opportunity-detail-drawer (2026-07-21)

- ~~Drawer dialog a11y (focus trap / Escape / restore focus) — same Week 7 modal a11y deferral as Meetings/Tasks/Notes~~ ✅
- Orphan stage_id deals omitted from board columns — already noted under 4.2; FK normally prevents
- Mid-save card switch remounts drawer via key — polish if demo pain
- Per-card policy(update?) on index serialize — batch/cache later if payload cost shows up
- Brittle response.body substring assertions in opportunities controller tests — strengthen in Week 7 test pass
- Stage select blank when record stage missing from stageOptions — tied to orphan-stage edge

## Deferred from: code review of 4-2-opportunities-pipeline-board (2026-07-21)

- Duplicated opportunity serialize/types vs lead show preview — extract shared later (Week 7)
- Unbounded full pipeline load (no pagination) — OK for MVP demo scale
- Orphan stage_id not present in OpportunityStage catalog — rare FK edge
- Unused `position` on client stage props — optional cleanup
- Empty OpportunityStage catalog empty-board copy — seeds always populate

## Deferred from: code review of 4-1-meetings-list-and-scheduling (2026-07-21)

- Silent invalid `user_id` fallback to lead owner / first assignable — same as tasks create
- Duplicated host/assignee listing queries across Meetings/Tasks/Leads controllers — extract later
- Duplicated `fieldError` helper in MeetingFormModal — share with FormFields later
- Validation remount loses submitted meeting form values — keep redirect+reopen (kickoff); revisit if demo pain
- ~~MeetingFormModal a11y (focus trap / Escape / backdrop) — Week 7~~ ✅ `useDialogA11y`
- Raw status enum strings in UI — humanize with Tasks polish
- Lead show meeting preview thinner than list row — intentional MVP preview
- Title max length / duration_minutes numericality — broader model guards later
- Tampered return_to / create-for-other-lead while viewing lead A — soft edges like notes/tasks

## Deferred from: Epic 3 retrospective / professor PR #20 (2026-07-21)

**Epic 4 kickoff — done (2026-07-21):**
- ~~Task status as Rails enum~~ ✅ `Task` enum `:status`
- ~~Extract formatDate / formatDateTime / formatCurrency~~ ✅ `app/javascript/lib/format.ts`
- ~~Shared atomic form fields~~ ✅ `app/javascript/components/ui/FormFields.tsx` (Task + Note modals)
- ~~Remove useEffect form/modal prop sync~~ ✅ set on submit via `transform`; modal-open derived from errors
- ~~Decide Inertia 422 vs redirect+reopen~~ ✅ keep **redirect + reopen modal** for CRM forms (matches Tasks/Notes; revisit only if remount UX hurts demo)
- ~~`verify_authorized` after-action~~ ✅ on `ApplicationController` (Sessions skipped; Dashboard/Meetings/Opportunities authorize)

**Week 7 (or earlier if demo pain):**
- Counter cache for lead task/note/meeting counts
- Extract TasksTable / fat page types
- ~~Modal a11y (focus trap / Escape / backdrop)~~ ✅ `app/javascript/hooks/useDialogA11y.ts` (2026-07-21)
- Remaining polish (mailto/tel, locale, empty copy, closed-only index)

## Deferred from: code review of 3-3-notes-timeline-on-lead (2026-07-14)

- Note content max length / oversized Inertia payload on lead show — MVP OK
- NoteFormModal a11y (focus trap / Escape / backdrop) — same polish as TaskFormModal
- Broader NotesController tests (admin create, return_to allowlist, timeline contract) — expand later
- When lead_id is inaccessible, soft errors can still land on a different allowlisted `return_to` lead — rare / abuse edge

## Deferred from: code review of 3-2-create-and-complete-tasks round 2 (2026-07-14)

- Skip full `form_options` on tasks index when `can_create` is false — MVP payload size
- Duplicate assignee listing query on lead show via `default_task_assignee_id` — extract later
- List modal preselects first lead instead of forcing an explicit choice — UX polish
- No request/system tests for modal reopen-on-errors or Complete in-flight disable — add when expanding e2e

## Deferred from: code review of 3-2-create-and-complete-tasks (2026-07-14)

- Dialog a11y (focus trap / Escape / backdrop dismiss) on TaskFormModal — polish
- Tasks index eagerly loads all in-scope leads into props for New Task — OK for MVP fixture sizes
- Duplicated admin/advisor assignee queries in LeadsController + TasksController — extract later
- No Task status inclusion or due_date format guard beyond presence — create hard-codes pending
- Changing lead in list modal does not refresh default assignee toward that lead’s advisor — UX polish
- Invalid/omitted user_id silently falls back to lead owner / first assignable — rare with seeded roles

## Deferred from: code review of 3-1-tasks-list-with-filters (2026-07-14)

- Overdue list vs `Task.overdue`/dashboard diverge by design (AC is pending-only) — unify only if product wants one definition
- Shared fixtures bump dashboard overdue counts — acceptable coupling for MVP
- Status humanization / filter-aware empty copy — polish
- Clamped `page` left in URL / preserveState races — same pattern as leads index
- Broader TaskPolicy action tests beyond index/scope — when write paths ship (3.2+)

## Later backlog (parked after Epic 2 retro — 2026-07-13)

Not required to start Epic 3. Revisit when polishing form UX or before/while adding more authorized controllers:

- **Inertia form-error remount** — On validation failure, lead forms remount from server props and can lose submitted field values (deferred in 2.2 + 2.3). Decide: accept for Epic 3 task/note forms, or fix a shared keep-values pattern.
- **`verify_authorized` after-action** — Pundit safety net so controller actions cannot forget `authorize`. Optional hardening before/during Epic 3 Tasks/Notes controllers.

## Deferred from: code review of 2-4-lead-detail-page (2026-07-13)

- Eight COUNT+SELECT queries per show — acceptable for MVP fixture sizes
- Meeting preview omits start_time — Epic 4 meeting UX
- Raw status strings / no mailto-tel / inert related rows — polish + Epic 3/4 write flows
- Back-to-leads drops index search/page params — same pattern as edit
- Duplicated currency/date helpers across leads pages — extract later if needed
- Note truncate mid-grapheme / mid-word — rare for seeded content

## Deferred from: code review of 2-3-edit-lead (2026-07-13)

- Validation-failure remount shows DB values not submitted payload — same Inertia pattern as Story 2.2
- Updating shared company country affects other leads on that company — checkbox warning is the UX notice
- No optimistic lock / stale update protection on concurrent edits — MVP out of scope
- Unassigned advisor gets 404 via `policy_scope` rather than Pundit 403 — intentional fail-closed scoping

## Deferred from: code review of 2-2-create-lead (2026-07-13)

- Concurrent `RecordNotUnique` automated test — flaky without dedicated concurrency harness
- Form remount loses client `useForm` values after error redirect — matches SessionsController Inertia pattern

## Deferred from: code review of 2-1-leads-index-with-search (2026-07-13)

- Closed leads still appear in index — AC lists all assigned stages; revisit if product wants open-only
- USD hardcoded for estimated value — MVP course demo; localize later if needed
- ~~Wire `Lead.find_or_initialize_by_email` into create/import path — Story 2.2~~ ✅ done in Story 2.2
- ~~Rescue/retry concurrent `RecordNotUnique` on lead create — Story 2.2~~ ✅ done in Story 2.2
- ~~Create success still redirects to list (not detail) until Story 2.4~~ ✅ done in Story 2.4
## Deferred from: code review of 1-6-readme-course-compliance (2026-07-05)

- Pipeline stage transitions listed as non-CRUD — acceptable; emphasizes kanban UX beyond bare CRUD

## Deferred from: code review of 1-5-dashboard-with-summary-metrics (2026-07-05)

- No automated perf assertion for 2s dashboard load AC — dev hardware check sufficient for MVP
- `seed_dashboard_sample_data` defined at top level in seeds.rb — standard Rails seed pattern

## Deferred from: code review of 1-4-app-layout-and-role-aware-navigation (2026-07-05)

- Mobile nav overlay does not auto-close on nav link click — UX polish for later
- CRM index controllers have no Pundit authorize yet — Epic 2 CRUD scope

## Deferred from: code review of 1-3-role-based-authorization (2026-07-05)

- Wire `authorize` in all CRUD controllers as Epic 2+ lands — policies exist but only `/admin/users` calls `authorize` today
- Add `after_action :verify_authorized` once resource controllers exist in ApplicationController
