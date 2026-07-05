---
title: LeadFlow CRM
status: final
created: 2026-07-05
updated: 2026-07-05T12:31:00-06:00
project: lead-flow
branch: cursor/data-model-v2
---

# PRD: LeadFlow CRM

*Working title confirmed.*

## 0. Document Purpose

This PRD defines **LeadFlow CRM** for Cheyenne Calderon's Ruby on Rails + React course project. It is the source of truth for epics, stories, UX, and architecture workflows.

**Audience:** Course instructor, developer (Cheyenne), AI implementation agents.

**Structure:** Glossary-anchored vocabulary; features grouped with globally numbered FRs; assumptions tagged and indexed.

**Existing inputs this PRD builds on (does not duplicate):**

| Artifact | Location |
|----------|----------|
| Project context & implementation state | `docs/project-context.md` |
| Data model (Tier 1+2) | `docs/DATA_MODEL.md` |
| Implementation log | `docs/IMPLEMENTATION.md` |
| UI designs (15 screens) | Visily export — see `addendum.md` |
| Course Week 1 specification | User-provided assignment checklist |

**Technical how** (stack versions, migration gotchas, auth architecture) lives in `addendum.md`.

---

## 1. Vision

Financial advisors, insurance agents, and consultants often track leads in spreadsheets, notes apps, and messaging threads. Information gets lost, follow-ups are missed, and pipeline visibility is poor.

**LeadFlow CRM** is a lightweight web CRM that centralizes leads, follow-up **Tasks**, **Meetings**, **Notes**, and **Opportunities** in one place. Advisors see their assigned pipeline; assistants add notes and tasks; admins manage users and roles.

The product must demonstrate real-world full-stack patterns—authentication, authorization, relational modeling, React UI via Inertia, automated tests, background jobs, Stripe payments, and production deployment—while remaining completable in the remaining **~7 weeks** of the course.

**Why this scope:** A freelancer/advisor CRM matches the course's recommended project size, maps cleanly to the approved data model, and aligns with existing Visily UI designs.

---

## 2. Target User

### 2.1 Jobs To Be Done

- **Advisor:** "When I have many prospects, I want one place to see who needs follow-up today so I don't lose deals."
- **Advisor:** "When a lead moves through stages, I want to update status and log interactions without switching tools."
- **Assistant:** "When the advisor is busy, I want to add notes and schedule tasks on their behalf."
- **Admin:** "When the team grows, I want to assign roles and control who sees what."
- **Student (builder):** "When I demo to my professor, I want a working SaaS that proves Rails + React + Postgres + tests + deploy."

### 2.2 Non-Users (v1)

- Multi-tenant SaaS customers (single-org academic demo only)
- Mobile-native users (responsive web only)
- Marketing automation / email campaign platforms
- Full accounting or invoicing

### 2.3 Key User Journeys

- **UJ-1. Elena signs in and sees her day.**
  - **Persona + context:** Elena, financial advisor, starts Monday morning.
  - **Entry state:** Logged out; opens `http://localhost:3000`.
  - **Path:** Redirected to `/login` → enters email/password → lands on **Dashboard** showing open leads count, overdue tasks, upcoming meetings, pipeline value.
  - **Climax:** She immediately sees three overdue tasks and clicks through to the first lead.
  - **Resolution:** Authenticated session; sidebar nav available (Dashboard, Leads, Tasks, Meetings, Opportunities).
  - **Edge case:** Invalid credentials → inline error on login form; session not created.

- **UJ-2. Elena filters leads and opens a record.**
  - **Persona + context:** Elena needs to find "Acme Corp" before a call.
  - **Entry state:** Authenticated; on Leads list (table view).
  - **Path:** Types in search → filters by stage "Qualified" → clicks row → **Lead Detail** shows company, stage, assigned advisor, related tasks/meetings/notes/opportunities.
  - **Climax:** She adds a **Note** from the timeline without leaving the page.
  - **Resolution:** Note persisted; lead `last_activity_at` updated.

- **UJ-3. Elena moves a deal through the pipeline.**
  - **Persona + context:** A proposal was sent; Elena updates the opportunity.
  - **Entry state:** On **Opportunities Pipeline** (kanban/columns by stage).
  - **Path:** Opens opportunity drawer → changes stage to "Proposal" → sets value and close date → saves.
  - **Climax:** Pipeline column counts and dashboard total value reflect the change.
  - **Resolution:** Drawer closes; flash confirmation shown.

- **UJ-4. Carlos (assistant) creates a follow-up task.**
  - **Persona + context:** Carlos supports Elena; cannot edit leads but can task and note.
  - **Entry state:** Authenticated as **Assistant** on Lead Detail.
  - **Path:** Opens New Task modal → sets title, due date, assignee (Elena) → saves.
  - **Climax:** Task appears on Tasks list and lead detail.
  - **Edge case:** Assistant attempts to delete a lead → 403 / redirect with alert.

- **UJ-5. Admin Jordan provisions a new advisor.**
  - **Persona + context:** Jordan, admin, onboarding a hire.
  - **Entry state:** Admin on **Users List**.
  - **Path:** New user → name, email, role Advisor, team → save → user receives dev password `[ASSUMPTION: email invite out of scope; admin sets temp password in v1]`.
  - **Climax:** New advisor can log in and sees empty assigned-leads list.

- **UJ-6. Elena checks overdue follow-ups (background job).**
  - **Persona + context:** Tasks past due date should surface automatically.
  - **Entry state:** Daily job has run overnight.
  - **Path:** Elena opens Dashboard → "Overdue tasks" widget shows count → filters Tasks list by overdue.
  - **Climax:** Tasks with `due_date < today` and pending status show as overdue.

- **UJ-7. Elena upgrades via Stripe (course demo).**
  - **Persona + context:** Export feature gated behind subscription.
  - **Entry state:** Advisor on Leads list; clicks "Export CSV".
  - **Path:** Redirected to Stripe Checkout (test mode) → completes payment → webhook marks subscription active → export succeeds.
  - **Climax:** Subscription status visible on user profile or settings.

---

## 3. Glossary

- **Lead** — Central CRM record for a prospective or active client. Belongs to one **Company**, **Country**, **LeadStage**, and assigned **User** (advisor).
- **Company** — Organization a lead works for. Deduplicated via `normalized_name`.
- **Country** — Seeded ISO reference; no free-text country on leads.
- **LeadStage** — Pipeline column for lead status (e.g. Prospect, Qualified). Ordered by `position`.
- **Opportunity** — Sales deal linked to one **Lead**. Has **OpportunityStage** and monetary `value`.
- **OpportunityStage** — Deal pipeline stage (e.g. Prospect, Won, Lost).
- **Task** — Follow-up action on a **Lead** with required `due_date`. `[ASSUMPTION: README "FollowUpTask" renamed to Task in implementation.]`
- **Meeting** — Scheduled interaction with a **Lead** (`scheduled_on`, `start_time`).
- **Note** — Text entry on a **Lead** with required `content`.
- **User** — Authenticated account with `has_secure_password`. Belongs to one **Role**.
- **Role** — One of `admin`, `advisor`, `assistant`. Determines authorization.
- **Team** — Optional sales team grouping for users and leads.
- **Tag** — Label for leads/notes (Tier 2; UI optional in MVP).
- **Dashboard** — Home surface after login with summary metrics (UJ-1).
- **Pipeline** — Visual board of **Opportunities** by **OpportunityStage** (UJ-3).

---

## 4. Features

### 4.1 Authentication & Session Management

**Description:** Session-based login/logout using Rails cookie session. Login page is a React Inertia page. Unauthenticated requests to protected routes redirect to `/login`. Realizes UJ-1.

**Status:** Partially implemented — backend + login UI exist; dashboard redirect target still placeholder.

**Functional Requirements:**

#### FR-1: User sign-in

A **User** can sign in with email and password. Realizes UJ-1.

**Consequences (testable):**
- Valid credentials create `session[:user_id]` and redirect to Dashboard.
- Invalid credentials redirect to login with field error; no session created.
- Email lookup is case-insensitive (normalized strip + downcase).

#### FR-2: User sign-out

An authenticated **User** can sign out. Realizes UJ-1.

**Consequences (testable):**
- `DELETE /logout` clears session and redirects to login.
- Subsequent requests to protected routes redirect to login.

**Notes:** Already covered by 6 controller tests. Extend when Dashboard becomes root.

---

### 4.2 Role-Based Authorization

**Description:** Every mutating action checks **Role**. Admin has full access; Advisor scoped to assigned **Leads**; Assistant read-mostly with create on **Task** and **Note**. Realizes UJ-4, UJ-5.

**Functional Requirements:**

#### FR-3: Enforce role permissions

The system enforces permissions per the matrix in `addendum.md`. Realizes UJ-4, UJ-5.

**Consequences (testable):**
- Advisor cannot access `/admin/*` routes (403 or redirect).
- Advisor cannot update a **Lead** not assigned to them.
- Assistant can create **Note** and **Task** but cannot delete **Lead**.
- Admin can CRUD all records.
- Controller/integration tests cover at least one denial per role.

---

### 4.3 Application Shell & Navigation

**Description:** Authenticated layout with sidebar matching Visily Dashboard chrome: logo, nav links (Dashboard, Leads, Tasks, Meetings, Opportunities), user menu (profile, sign out). Nav items hidden by role where applicable. Realizes UJ-1.

**Functional Requirements:**

#### FR-4: App layout with role-aware navigation

An authenticated **User** sees a consistent app shell on all CRM pages. Realizes UJ-1.

**Consequences (testable):**
- `auth.user` (id, name, email, role) available on all Inertia pages.
- Admin sees Users/Roles nav; Advisor does not.
- Root route `/` renders Dashboard (replaces inertia example page).

---

### 4.4 Lead Management

**Description:** CRUD for **Leads** with table list, search, filters, create/edit form, and detail view. Advisor sees assigned leads only; Admin sees all. Realizes UJ-2.

**Functional Requirements:**

#### FR-5: List and search leads

An **Advisor** can list their assigned **Leads**; an **Admin** can list all. Realizes UJ-2.

**Consequences (testable):**
- Table columns: name, company, stage, advisor, last activity, estimated value.
- Search matches name, email, company name.
- Filter by **LeadStage** and assigned **User** (admin only).
- Pagination or reasonable limit `[ASSUMPTION: 25 per page]`.

#### FR-6: Create and edit leads

An **Advisor** or **Admin** can create and update **Leads**. Realizes UJ-2.

**Consequences (testable):**
- Required fields enforced: name, company, country, stage, assigned user.
- Company selected or created via normalized lookup.
- Validation errors returned via Inertia errors hash.
- Successful save redirects to Lead Detail or list with flash notice.

#### FR-7: View lead detail

An authorized **User** can view a **Lead** with related **Tasks**, **Meetings**, **Notes**, **Opportunities**. Realizes UJ-2.

**Consequences (testable):**
- Unauthorized lead access returns 403/404 for Advisor.
- Detail page shows tabs or sections for child records.

---

### 4.5 Tasks & Notes

**Description:** **Tasks** with due dates and overdue highlighting; **Notes** timeline on lead. Realizes UJ-2, UJ-4, UJ-6.

**Functional Requirements:**

#### FR-8: Manage tasks

An authorized **User** can create and complete **Tasks** on a **Lead**. Realizes UJ-4, UJ-6.

**Consequences (testable):**
- `due_date` required; cannot save without it.
- Tasks list page with filter: mine / overdue / all (role-scoped).
- New Task modal from lead detail and tasks list.
- Status transitions: pending → completed.

#### FR-9: Manage notes

An authorized **User** can add **Notes** on a **Lead**. Realizes UJ-2, UJ-4.

**Consequences (testable):**
- `content` required.
- Notes display chronologically on Lead Detail (timeline).
- Shows author name and timestamp.

---

### 4.6 Meetings & Opportunities

**Description:** **Meetings** list and schedule modal; **Opportunities** pipeline board with detail drawer. Realizes UJ-3.

**Functional Requirements:**

#### FR-10: Schedule meetings

An **Advisor** or **Admin** can CRUD **Meetings** on assigned/all **Leads**. Realizes UJ-3.

**Consequences (testable):**
- Meetings list sorted by upcoming date.
- Schedule modal captures title, date, time, location/virtual link.
- Meeting appears on Dashboard "upcoming" widget.

#### FR-11: Track opportunity pipeline

An **Advisor** or **Admin** can manage **Opportunities** on a visual pipeline. Realizes UJ-3.

**Consequences (testable):**
- Pipeline columns map to **OpportunityStage** records.
- Opportunity drawer: title, value (>0 when set), stage, close date, description.
- Moving stage updates counts on Dashboard.

---

### 4.7 Dashboard & Reporting

**Description:** Summary widgets for at-a-glance workload. Realizes UJ-1, UJ-6.

**Functional Requirements:**

#### FR-12: Dashboard metrics

An authenticated **User** sees role-appropriate summary metrics. Realizes UJ-1, UJ-6.

**Consequences (testable):**
- Widgets: open leads count, overdue tasks, upcoming meetings (7 days), pipeline value (open opportunities).
- Advisor metrics scoped to assigned records; Admin sees org totals.
- Page loads in < 2s on seed data `[ASSUMPTION: dev hardware]`.

---

### 4.8 Admin — Users & Roles

**Description:** Admin-only user and role management screens per Visily designs. Realizes UJ-5.

**Functional Requirements:**

#### FR-13: Admin user management

An **Admin** can list, create, edit, and disable **Users**. Realizes UJ-5.

**Consequences (testable):**
- Cannot delete self.
- Role assignment required.
- Password set on create `[ASSUMPTION: min 8 chars]`.

#### FR-14: Admin role visibility

An **Admin** can view **Role** definitions and permission summary (read-only in MVP). Realizes UJ-5.

**Consequences (testable):**
- Role Management page lists admin/advisor/assistant with permission matrix display.
- `[ASSUMPTION: dynamic permission editing deferred — roles are seeded]`

---

### 4.9 Monetization (Stripe — Course Requirement)

**Description:** Test-mode Stripe Checkout for a single "LeadFlow Pro" plan. One gated feature demonstrates subscription. Realizes UJ-7.

**Functional Requirements:**

#### FR-15: Stripe subscription checkout

An **Advisor** can subscribe via Stripe Checkout (test mode). Realizes UJ-7.

**Consequences (testable):**
- Checkout session created server-side; success/cancel URLs configured.
- Webhook handler verifies signature and updates subscription status on **User**.
- Gated action (CSV export) blocked when not subscribed; allowed when active.
- Works with Stripe test cards in demo.

---

### 4.10 Background Jobs (Course Requirement)

**Description:** Solid Queue recurring job for overdue task maintenance. Realizes UJ-6.

**Functional Requirements:**

#### FR-16: Mark overdue tasks

The system marks pending **Tasks** as overdue when past due date. Realizes UJ-6.

**Consequences (testable):**
- Job runs on schedule (daily) via Solid Queue.
- Only pending tasks with `due_date < today` updated.
- Job idempotent; test covers task state change.
- Job execution logged or verifiable in dev console.

---

### 4.11 Deployment & Operations

**Description:** Production deploy via existing Kamal/Docker scaffold. Realizes course deployment requirement.

**Functional Requirements:**

#### FR-17: Production deployment

The application runs on a publicly reachable URL. Realizes course deploy requirement.

**Consequences (testable):**
- Docker image builds in CI or locally.
- Kamal deploy succeeds to target host `[ASSUMPTION: user-provided VPS or Kamal config]`.
- Health check `/up` returns 200.
- README documents deploy URL and demo credentials.

---

### 4.12 Quality & Testing

**Description:** Automated test coverage for course rubric.

**Functional Requirements:**

#### FR-18: Automated test suite

The project maintains a passing automated test suite. Realizes course testing requirement.

**Consequences (testable):**
- Model tests for validations and associations (existing 40+).
- Controller tests for auth, leads CRUD, authorization denials.
- CI pipeline green on PR (RuboCop, Brakeman, bundler-audit, Rails test).
- `[ASSUMPTION: system tests for login + lead create optional but recommended]`

---

## 5. Non-Goals (Explicit)

- Multi-tenant organizations with separate databases
- Native iOS/Android apps
- Email/SMS outbound campaigns
- Calendar sync (Google/Outlook)
- Document/file attachments on leads
- Real-time collaborative editing
- Custom role builder (dynamic permissions UI)
- Leads card view (defer to v2)
- Tag management UI (defer; schema may remain)
- Production Stripe live keys (test mode only for course)

---

## 6. MVP Scope

### 6.1 In Scope (7-week delivery)

| Phase | Deliverables |
|-------|--------------|
| **Foundation** ✅ | Schema, models, seeds, session auth, model tests, PRD |
| **Week 1** | App shell, FR-3 authorization, Dashboard (FR-12), README fixes |
| **Week 2** | Leads CRUD + Lead Detail (FR-5–7) — table view |
| **Week 3** | Tasks + Notes (FR-8–9) |
| **Week 4** | Meetings + Pipeline (FR-10–11) |
| **Week 5** | Search/filters polish + Admin users/roles (FR-13–14) |
| **Week 6** | Stripe (FR-15), overdue job (FR-16), Kamal deploy (FR-17) |
| **Week 7** | Test gaps (FR-18), bug fixes, **final presentation** |

### 6.2 Out of Scope for MVP

| Item | Reason |
|------|--------|
| Leads card view | Table view satisfies course + Visily P0 |
| Tag UI | Tier 2; timeboxed |
| Team management UI | Seeds sufficient for demo |
| Email invitations | Admin sets password manually |
| Billing portal | Stripe Checkout sufficient for course |
| 100% test coverage | Focus on critical paths |

---

## 7. Success Metrics

**Primary**

- **SM-1:** Course checklist 100% — all Week 1 + milestone requirements demonstrable in demo. Validates FR-1–FR-18.
- **SM-2:** Professor can clone repo, run setup commands, log in, and complete UJ-1 through UJ-3 without author assistance. Validates FR-1, FR-4–7, FR-11–12.

**Secondary**

- **SM-3:** CI green on default branch at presentation date. Validates FR-18.
- **SM-4:** App reachable at deployed URL with test Stripe flow completable. Validates FR-15, FR-17.

**Counter-metrics (do not optimize)**

- **SM-C1:** Line count / feature count — do not add scope beyond PRD to impress; completeness beats breadth.

---

## 8. Cross-Cutting NFRs

- **NFR-1 Security:** Passwords hashed (bcrypt); CSRF protection on forms; Brakeman clean; no secrets in repo.
- **NFR-2 Authorization:** Fail closed — unknown permission defaults to deny.
- **NFR-3 Data integrity:** DB constraints + model validations; foreign keys enforced.
- **NFR-4 Testability:** Fixtures for all core models; `sign_in_as` helper for controller tests.
- **NFR-5 Maintainability:** Follow `docs/project-context.md` patterns (InertiaController, Task naming, stage FKs).
- **NFR-6 UX consistency:** Tailwind utility classes; match Visily layout for primary flows.

---

## 9. Information Architecture

Top-level surfaces (web only):

```
/login                    (public)
/                         Dashboard
/leads                    Leads list (table)
/leads/new                Create lead
/leads/:id                Lead detail
/leads/:id/edit           Edit lead
/tasks                    Tasks list
/meetings                 Meetings list
/opportunities            Pipeline board
/admin/users              Users (admin)
/admin/users/:id          User edit (admin)
/admin/roles              Role management (admin)
/settings/subscription    Stripe checkout entry [ASSUMPTION]
```

Sidebar nav mirrors Visily Dashboard design.

---

## 10. Open Questions

1. **Deploy target:** Which host for Kamal (Fly, Hetzner, existing VPS)? — *Owner: Cheyenne; blocker for Week 7.*
2. **Advisor seed users:** Add second advisor + assistant to seeds for role demo? — *Recommended yes.*
3. **Export gate:** CSV export vs another feature for Stripe demo? — *Default: CSV export.*
4. **Presentation format:** Live demo vs recorded — *Confirm with instructor.*

---

## 11. Assumptions Index

- README "FollowUpTask" → implemented as **Task** — §3 Glossary
- Pagination 25 leads per page — FR-5
- Admin sets temp password on user create (no email) — UJ-5
- Dashboard load < 2s on seed data — FR-12
- Dynamic role editing deferred — FR-14
- Stripe test mode only — FR-15
- Kamal host TBD — FR-17
- System tests optional but recommended — FR-18
- 7 weeks remaining from July 2026 — §6.1

---

## 12. Next Workflow Steps

| Step | Skill | Purpose |
|------|-------|---------|
| 1 | `bmad-create-ux-design` | Optional — Visily exists; may skip or lightweight |
| 2 | `bmad-architecture` | Technical architecture doc from this PRD |
| 3 | `bmad-create-epics-and-stories` | Break FRs into implementable stories |
| 4 | `bmad-sprint-planning` | Order stories for remaining 7 weeks |
| 5 | `bmad-dev-story` | Begin implementation cycle |

Invoke **`bmad-help`** anytime for routing.
