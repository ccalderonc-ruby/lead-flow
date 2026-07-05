---
stepsCompleted:
  - step-01-validate-prerequisites
  - step-02-design-epics
  - step-03-create-stories
  - step-04-final-validation
status: final
created: 2026-07-05
updated: 2026-07-05
inputDocuments:
  - _bmad-output/planning-artifacts/prds/prd-leadflow-crm-2026-07-05/prd.md
  - _bmad-output/planning-artifacts/prds/prd-leadflow-crm-2026-07-05/addendum.md
  - docs/project-context.md
  - docs/DATA_MODEL.md
  - docs/IMPLEMENTATION.md
---

# LeadFlow CRM - Epic Breakdown

## Overview

This document decomposes the LeadFlow CRM PRD (FR-1 through FR-18) into **7 epics** and **28 stories**, aligned with the **7-week delivery plan**. Brownfield foundation (schema, models, session auth) is captured as completed stories in Epic 1.

**Branch:** `cursor/data-model-v2`

---

## Requirements Inventory

### Functional Requirements

```
FR-1: User sign-in with email/password (session cookie)
FR-2: User sign-out clears session
FR-3: Role-based authorization (admin / advisor / assistant)
FR-4: App layout with role-aware sidebar navigation
FR-5: List, search, and filter leads (table view)
FR-6: Create and edit leads with validations
FR-7: View lead detail with related records
FR-8: Manage tasks (create, complete, list, overdue filter)
FR-9: Manage notes (timeline on lead detail)
FR-10: Schedule and manage meetings
FR-11: Track opportunities on visual pipeline
FR-12: Dashboard with role-scoped summary metrics
FR-13: Admin user management (CRUD, disable)
FR-14: Admin role visibility (read-only permission matrix)
FR-15: Stripe test-mode subscription checkout
FR-16: Background job marks overdue tasks
FR-17: Production deployment via Kamal/Docker
FR-18: Automated test suite (models, controllers, CI green)
```

### NonFunctional Requirements

```
NFR-1: Security — bcrypt passwords, CSRF, Brakeman clean, no secrets in repo
NFR-2: Authorization fail-closed — unknown permission denies access
NFR-3: Data integrity — DB constraints + model validations
NFR-4: Testability — fixtures + sign_in_as helper
NFR-5: Maintainability — follow docs/project-context.md patterns
NFR-6: UX consistency — Tailwind; match Visily layouts for primary flows
```

### Additional Requirements

```
- Brownfield: 15-table schema, models, seeds already implemented (see docs/IMPLEMENTATION.md)
- All UI controllers inherit InertiaController; shared auth + flash props
- Lead.stage → lead_stages; Opportunity.stage → opportunity_stages (never generic stages table)
- Model named Task (not FollowUpTask); table tasks
- Company dedup via Company.find_or_initialize_by_name
- Dev login: admin@leadflow.local / password after db:seed
- bin/dev — browse port 3000 only (Vite 3036 is assets)
- CI: RuboCop, Brakeman, bundler-audit, Rails test on PostgreSQL
- Kamal + Docker scaffold exists; deploy target TBD
- Course deliverables: Stripe, Solid Queue job, deploy, final presentation
```

### UX Design Requirements

```
UX-DR1: Sidebar layout matching Visily Dashboard (logo, nav, user menu, sign out)
UX-DR2: Leads List table view — columns: name, company, stage, advisor, last activity, value
UX-DR3: New/Edit Lead Form — company/country/stage selectors, validation errors inline
UX-DR4: Lead Detail — sections/tabs for tasks, meetings, notes, opportunities
UX-DR5: Tasks List + New Task Modal (from list and lead detail)
UX-DR6: Notes Timeline — chronological, author + timestamp
UX-DR7: Meetings List + Schedule Meeting Modal
UX-DR8: Opportunities Pipeline — columns by OpportunityStage + detail drawer
UX-DR9: Users List (Admin) + User Detail/Edit form
UX-DR10: Role Management page — read-only permission matrix
UX-DR11: Login page — centered card (already implemented; polish only)
```

### FR Coverage Map

| FR | Epic | Story |
|----|------|-------|
| FR-1 | Epic 1 | 1.2 ✅ |
| FR-2 | Epic 1 | 1.2 ✅ |
| FR-3 | Epic 1 | 1.3 |
| FR-4 | Epic 1 | 1.4 |
| FR-12 | Epic 1 | 1.5 |
| FR-5 | Epic 2 | 2.1; Epic 5 | 5.4 |
| FR-6 | Epic 2 | 2.2, 2.3 |
| FR-7 | Epic 2 | 2.4 |
| FR-8 | Epic 3 | 3.1, 3.2 |
| FR-9 | Epic 3 | 3.3 |
| FR-10 | Epic 4 | 4.1 |
| FR-11 | Epic 4 | 4.2, 4.3 |
| FR-13 | Epic 5 | 5.2 |
| FR-14 | Epic 5 | 5.3 |
| FR-15 | Epic 6 | 6.2, 6.3 |
| FR-16 | Epic 6 | 6.1 |
| FR-17 | Epic 6 | 6.4 |
| FR-18 | Epic 7 | 7.1, 7.2 |

---

## Epic List

### Epic 1: Access the CRM
Users can sign in, see role-appropriate navigation, and view a dashboard summary.
**FRs covered:** FR-1, FR-2, FR-3, FR-4, FR-12 | **Week:** 1

### Epic 2: Manage Leads
Advisors and admins can list, create, edit, and view leads with full detail.
**FRs covered:** FR-5, FR-6, FR-7 | **Week:** 2

### Epic 3: Track Follow-Ups
Users can manage tasks and notes on leads to stay on top of follow-ups.
**FRs covered:** FR-8, FR-9 | **Week:** 3

### Epic 4: Run the Sales Pipeline
Advisors schedule meetings and move opportunities through a visual pipeline.
**FRs covered:** FR-10, FR-11 | **Week:** 4

### Epic 5: Administer the Team
Admins manage users and roles; all users get polished search/filter on leads.
**FRs covered:** FR-13, FR-14, FR-5 (filters) | **Week:** 5

### Epic 6: Ship as a SaaS
Course production requirements: background jobs, Stripe, deployment.
**FRs covered:** FR-15, FR-16, FR-17 | **Week:** 6

### Epic 7: Launch Ready
Test coverage, polish, and presentation preparation.
**FRs covered:** FR-18 | **Week:** 7

---

## Epic 1: Access the CRM

Advisors, assistants, and admins can authenticate and land in a working app shell with dashboard metrics.

### Story 1.1: Database schema and domain models ✅ DONE

As a **developer**,
I want the PostgreSQL schema and Active Record models in place,
So that all CRM features have a validated data foundation.

**Status:** Complete on `cursor/data-model-v2`

**Acceptance Criteria:**

**Given** the Tier 1+2 data model in `docs/DATA_MODEL.md`
**When** migrations and models are run
**Then** 15 tables exist with associations and validations
**And** 40 model tests pass

**Fulfills:** Foundation for all FRs | **Refs:** docs/IMPLEMENTATION.md Step 1

---

### Story 1.2: Session login and logout ✅ DONE

As a **User**,
I want to sign in and sign out with email and password,
So that my session is secure and persistent across pages.

**Status:** Complete

**Acceptance Criteria:**

**Given** I am logged out
**When** I submit valid credentials at `/login`
**Then** I am redirected to the home page with an active session
**And** invalid credentials show an error without creating a session

**Given** I am signed in
**When** I click Sign out
**Then** my session is cleared and I am redirected to login

**Fulfills:** FR-1, FR-2 | **Refs:** 6 session controller tests

---

### Story 1.3: Role-based authorization

As a **User**,
I want the system to enforce my role permissions on every action,
So that advisors, assistants, and admins only access what they should.

**Acceptance Criteria:**

**Given** Pundit (or equivalent) policies exist for Lead, Task, Note, Meeting, Opportunity, User
**When** an Advisor attempts to access `/admin/users`
**Then** they receive 403 or redirect with alert

**Given** an Advisor is authenticated
**When** they attempt to edit a Lead not assigned to them
**Then** the action is denied

**Given** an Assistant is authenticated
**When** they create a Note on any Lead
**Then** the note is saved successfully

**Given** an Assistant attempts to delete a Lead
**Then** the action is denied

**And** at least one controller test per role verifies a denial path

**Fulfills:** FR-3, NFR-2 | **UX:** —

---

### Story 1.4: App layout and role-aware navigation

As a **User**,
I want a consistent sidebar and header on every page,
So that I can navigate the CRM without confusion.

**Acceptance Criteria:**

**Given** I am authenticated
**When** I visit any Inertia CRM page
**Then** I see a sidebar with Dashboard, Leads, Tasks, Meetings, Opportunities
**And** Admin users additionally see Users and Roles links
**And** Advisor/Assistant do not see admin links

**Given** the layout component exists
**When** rendered on any page
**Then** it shows my name, role, and Sign out control
**And** matches Visily Dashboard chrome (UX-DR1)

**Fulfills:** FR-4 | **UX:** UX-DR1

---

### Story 1.5: Dashboard with summary metrics

As a **User**,
I want a dashboard showing my key counts and pipeline value,
So that I know what needs attention when I start my day (UJ-1).

**Acceptance Criteria:**

**Given** I am authenticated as Advisor
**When** I visit `/`
**Then** I see widgets: open leads (assigned), overdue tasks, upcoming meetings (7 days), pipeline value
**And** counts reflect only my assigned/scoped records

**Given** I am authenticated as Admin
**When** I visit `/`
**Then** widgets show organization-wide totals

**Given** seed data is loaded
**When** the dashboard loads
**Then** it renders in under 2 seconds on dev hardware

**And** root route `/` renders Dashboard (inertia_example removed)

**Fulfills:** FR-12 | **UX:** UX-DR1

---

### Story 1.6: README course compliance

As a **student**,
I want the README to satisfy the Week 1 assignment checklist,
So that my repository passes professor review.

**Acceptance Criteria:**

**Given** the course specification checklist
**When** README is reviewed
**Then** it lists 6+ non-CRUD use cases separately from CRUD scope
**And** mentions final presentation, Stripe, and background jobs in roadmap
**And** model name Task (not FollowUpTask) is consistent with code

**Fulfills:** Course requirement | **Week 1**

---

## Epic 2: Manage Leads

Advisors manage their assigned leads; admins manage all leads.

### Story 2.1: Leads index with search

As an **Advisor**,
I want to see and search my assigned leads in a table,
So that I can find prospects quickly (UJ-2).

**Acceptance Criteria:**

**Given** I am an Advisor with assigned leads
**When** I visit `/leads`
**Then** I see a table with name, company, stage, advisor, last activity, estimated value
**And** only my assigned leads appear

**Given** I am an Admin
**When** I visit `/leads`
**Then** I see all leads

**Given** I type in the search box
**When** I search by name, email, or company
**Then** the list filters matching records

**And** pagination shows 25 leads per page

**Fulfills:** FR-5 | **UX:** UX-DR2

---

### Story 2.2: Create lead

As an **Advisor**,
I want to create a new lead with company and stage,
So that I can add prospects to my pipeline (UJ-2).

**Acceptance Criteria:**

**Given** I am on `/leads/new`
**When** I submit valid data (name, company, country, stage, assigned user)
**Then** the lead is created and I am redirected to Lead Detail with flash notice

**Given** I enter a company name with typos/punctuation
**When** the form saves
**Then** Company.find_or_initialize_by_name deduplicates the company

**Given** required fields are missing
**When** I submit
**Then** Inertia validation errors display on the form

**Fulfills:** FR-6 | **UX:** UX-DR3

---

### Story 2.3: Edit lead

As an **Advisor**,
I want to update lead information,
So that records stay accurate as deals progress.

**Acceptance Criteria:**

**Given** I am authorized for a lead
**When** I visit `/leads/:id/edit` and save changes
**Then** the lead updates and I see confirmation

**Given** I am an Advisor not assigned to the lead
**When** I attempt to edit
**Then** access is denied per Story 1.3 policies

**Fulfills:** FR-6 | **UX:** UX-DR3

---

### Story 2.4: Lead detail page

As a **User**,
I want to view a lead with all related activity,
So that I have full context before a call (UJ-2).

**Acceptance Criteria:**

**Given** I am authorized
**When** I visit `/leads/:id`
**Then** I see lead fields, company, stage, country, assigned advisor
**And** sections for tasks, meetings, notes, opportunities (counts or previews)

**Given** an unauthorized Advisor
**When** they visit another advisor's lead URL
**Then** they receive 403/404

**Fulfills:** FR-7 | **UX:** UX-DR4

---

## Epic 3: Track Follow-Ups

Users create tasks and notes to drive follow-up discipline.

### Story 3.1: Tasks list with filters

As an **Advisor**,
I want a tasks list filtered by mine, overdue, or all,
So that I prioritize follow-ups (UJ-6).

**Acceptance Criteria:**

**Given** I visit `/tasks`
**When** the page loads
**Then** I see tasks scoped to my role with title, lead, due date, status, assignee

**Given** I select filter "Overdue"
**When** applied
**Then** only pending tasks with due_date < today appear

**Fulfills:** FR-8 | **UX:** UX-DR5

---

### Story 3.2: Create and complete tasks

As an **Assistant**,
I want to create and complete tasks on a lead,
So that the advisor stays on schedule (UJ-4).

**Acceptance Criteria:**

**Given** I open New Task modal from lead detail or tasks list
**When** I submit title, due_date, lead, assignee
**Then** the task is created with pending status

**Given** due_date is blank
**When** I submit
**Then** validation error prevents save

**Given** a pending task
**When** I mark it completed
**Then** status updates to completed

**Fulfills:** FR-8 | **UX:** UX-DR5

---

### Story 3.3: Notes timeline on lead

As an **Advisor**,
I want to add and view notes on a lead chronologically,
So that I retain conversation history (UJ-2).

**Acceptance Criteria:**

**Given** I am on Lead Detail
**When** I add a note with content
**Then** it appears in the timeline with my name and timestamp
**And** lead last_activity_at updates

**Given** content is blank
**When** I submit
**Then** validation error is shown

**Fulfills:** FR-9 | **UX:** UX-DR6

---

## Epic 4: Run the Sales Pipeline

Advisors manage meetings and move deals through the pipeline.

### Story 4.1: Meetings list and scheduling

As an **Advisor**,
I want to schedule and view upcoming meetings,
So that I am prepared for client conversations.

**Acceptance Criteria:**

**Given** I visit `/meetings`
**When** the page loads
**Then** meetings are sorted by upcoming scheduled_on/start_time

**Given** I open Schedule Meeting modal
**When** I submit title, date, time, lead, location or virtual link
**Then** the meeting is created and appears on the list

**And** upcoming meetings appear on Dashboard widget (Story 1.5)

**Fulfills:** FR-10 | **UX:** UX-DR7

---

### Story 4.2: Opportunities pipeline board

As an **Advisor**,
I want a kanban-style pipeline of opportunities by stage,
So that I see deal flow at a glance (UJ-3).

**Acceptance Criteria:**

**Given** I visit `/opportunities`
**When** the page loads
**Then** columns match OpportunityStage records ordered by position
**And** each column lists opportunities for my scoped leads

**Fulfills:** FR-11 | **UX:** UX-DR8

---

### Story 4.3: Opportunity detail drawer

As an **Advisor**,
I want to view and edit opportunity details in a drawer,
So that I can update deal stage and value quickly (UJ-3).

**Acceptance Criteria:**

**Given** I click an opportunity on the pipeline
**When** the drawer opens
**Then** I see title, value, stage, close date, description, linked lead

**Given** I change stage and save
**When** the drawer closes
**Then** pipeline columns and dashboard pipeline value update

**Given** value is set and ≤ 0
**When** I save
**Then** validation error is shown

**Fulfills:** FR-11 | **UX:** UX-DR8

---

## Epic 5: Administer the Team

Admins manage users; lead filters are polished for all roles.

### Story 5.1: Demo seed users for role testing

As a **developer**,
I want advisor and assistant seed users,
So that role-based flows are demoable without manual setup.

**Acceptance Criteria:**

**Given** `bin/rails db:seed`
**When** seeds complete
**Then** users exist: admin, advisor, assistant with password `password`
**And** advisor has at least one assigned lead; assistant can access leads read-only

**Fulfills:** UJ-4, UJ-5 setup | **Week 5**

---

### Story 5.2: Admin user management

As an **Admin**,
I want to create and edit users with roles,
So that I can onboard the team (UJ-5).

**Acceptance Criteria:**

**Given** I am Admin on `/admin/users`
**When** I create a user with name, email, role, password (min 8 chars)
**Then** the user can log in with assigned role

**Given** I edit a user
**When** I change role or disable status
**Then** changes persist; disabled user cannot log in

**Given** I am the logged-in admin
**When** I attempt to delete/disable myself
**Then** the action is prevented

**Fulfills:** FR-13 | **UX:** UX-DR9

---

### Story 5.3: Role management page

As an **Admin**,
I want to view role definitions and permissions,
So that I understand access levels for the demo.

**Acceptance Criteria:**

**Given** I visit `/admin/roles`
**When** the page loads
**Then** I see admin, advisor, assistant with permission matrix (read-only)
**And** no dynamic permission editing (roles are seeded)

**Fulfills:** FR-14 | **UX:** UX-DR10

---

### Story 5.4: Advanced lead filters

As an **Admin**,
I want to filter leads by stage and assigned advisor,
So that I can review team workload (UJ-2).

**Acceptance Criteria:**

**Given** I am on `/leads` as Admin
**When** I filter by LeadStage and assigned User
**Then** the table updates accordingly

**Given** I am Advisor
**When** I use stage filter
**Then** filter applies within my assigned leads only

**Fulfills:** FR-5 (filters) | **Week 5 polish**

---

## Epic 6: Ship as a SaaS

Production course requirements: jobs, payments, deploy.

### Story 6.1: Mark overdue tasks job

As the **system**,
I want to mark pending tasks past due as overdue daily,
So that dashboards and filters stay accurate (UJ-6).

**Acceptance Criteria:**

**Given** Solid Queue recurring config
**When** MarkOverdueTasksJob runs
**Then** pending tasks with due_date < today have status overdue

**Given** the job runs twice
**When** no new overdue tasks exist
**Then** already-overdue tasks are not duplicated or errored

**And** a test verifies status transition

**Fulfills:** FR-16

---

### Story 6.2: Stripe checkout and webhook

As an **Advisor**,
I want to subscribe via Stripe test checkout,
So that I can access premium features (UJ-7).

**Acceptance Criteria:**

**Given** Stripe test keys in credentials/env
**When** I initiate checkout from subscription settings
**Then** a Checkout Session is created server-side and I redirect to Stripe

**Given** Stripe sends signed webhook checkout.session.completed
**When** webhook handler processes it
**Then** user subscription_status becomes active

**Fulfills:** FR-15

---

### Story 6.3: Gated CSV export

As a **subscribed Advisor**,
I want to export my leads as CSV,
So that the Stripe integration demonstrates value (UJ-7).

**Acceptance Criteria:**

**Given** I am Advisor without active subscription
**When** I click Export CSV on leads list
**Then** I am prompted to subscribe

**Given** I have active subscription
**When** I export
**Then** CSV downloads with my scoped leads

**Fulfills:** FR-15

---

### Story 6.4: Production deployment

As a **student**,
I want the app deployed to a public URL,
So that I meet the course deployment requirement.

**Acceptance Criteria:**

**Given** Dockerfile and Kamal config
**When** deploy succeeds
**Then** `/up` health check returns 200 on production URL

**And** README documents URL, setup, and demo credentials

**Fulfills:** FR-17

---

## Epic 7: Launch Ready

Quality gates and presentation prep.

### Story 7.1: Controller tests for CRM and authorization

As a **developer**,
I want controller tests for leads CRUD and role denials,
So that CI validates critical paths (FR-18).

**Acceptance Criteria:**

**Given** the test suite
**When** `bin/rails test` runs
**Then** tests cover leads index/create/update, task create, admin user create
**And** at least one 403/redirect test per role (advisor, assistant)
**And** all tests pass

**Fulfills:** FR-18, NFR-4

---

### Story 7.2: System test for core journey

As a **developer**,
I want a system test for login → create lead,
So that the end-to-end stack is verified.

**Acceptance Criteria:**

**Given** Capybara system test
**When** test runs login, navigate to new lead, submit form
**Then** lead appears on index or detail page

**Fulfills:** FR-18 (optional but recommended)

---

### Story 7.3: Presentation and documentation polish

As a **student**,
I want final docs and demo script ready,
So that I can present confidently in Week 7.

**Acceptance Criteria:**

**Given** IMPLEMENTATION.md and README
**When** updated for final state
**Then** they document deploy URL, all demo personas, and UJ-1 through UJ-3 walkthrough

**And** CI is green on presentation branch

**Fulfills:** FR-18, course presentation requirement

---

## Validation Summary

| Check | Result |
|-------|--------|
| All FR-1…FR-18 mapped | ✅ |
| All UX-DR1…UX-DR11 mapped | ✅ |
| Epics deliver user value | ✅ |
| No forward story dependencies | ✅ |
| Brownfield complete stories marked | ✅ Stories 1.1, 1.2 |
| 7-week alignment | ✅ Epics 1–7 |

**Total:** 7 epics, 28 stories (2 complete, 26 remaining)

**Next step:** `bmad-sprint-planning` — assign stories to weeks and set sprint status.
