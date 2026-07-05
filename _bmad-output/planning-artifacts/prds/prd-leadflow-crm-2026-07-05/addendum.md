# LeadFlow CRM — PRD Addendum

Technical and design depth that supports the PRD but does not belong in the main narrative.

---

## Existing Implementation (Brownfield Baseline)

**Branch:** `cursor/data-model-v2` (synced to GitHub)

| Layer | Status |
|-------|--------|
| Rails 8.1 + Inertia + React 19 + TypeScript + Vite + Tailwind 4 | ✅ Scaffold |
| PostgreSQL schema (15 tables) | ✅ Migrated |
| Active Record models + validations | ✅ |
| Seeds (countries, roles, stages, admin user) | ✅ |
| Session auth (login/logout) | ✅ |
| Model + session tests (46 passing) | ✅ |
| CRM UI pages | ❌ Not started |
| Role authorization enforcement | ❌ Not started |
| Stripe | ❌ |
| Background jobs (domain) | ❌ |
| Production deploy | ❌ |

**Dev credentials:** `admin@leadflow.local` / `password`

**Agent context file:** `docs/project-context.md`

**Implementation log:** `docs/IMPLEMENTATION.md`

---

## Data Model Reference

Full ERD and permissions: `docs/DATA_MODEL.md`

**Tier 1 (course):** Role, User, Lead, Opportunity, Task, Meeting, Note

**Tier 2 (UI fidelity):** LeadStage, OpportunityStage, Team, Tag, join tables, Country, Company

**Critical migration rule:** `Lead.stage` → `lead_stages`; `Opportunity.stage` → `opportunity_stages` (never a generic `stages` table).

**Company dedup:** `Company.normalize_name` + `find_or_initialize_by_name`.

---

## Visily UI Inventory (15 screens)

| Screen | Route (proposed) | Priority |
|--------|------------------|----------|
| Login | `/login` | ✅ Built |
| Dashboard | `/` | P0 |
| Leads List (Table) | `/leads` | P0 |
| Leads List (Card) | `/leads?view=card` | P2 defer |
| New/Edit Lead Form | `/leads/new`, `/leads/:id/edit` | P0 |
| Lead Detail | `/leads/:id` | P0 |
| Tasks List | `/tasks` | P1 |
| New Task Modal | modal on lead/tasks | P1 |
| Meetings List | `/meetings` | P1 |
| Schedule Meeting Modal | modal | P1 |
| Notes Timeline | tab on Lead Detail | P1 |
| Opportunities Pipeline | `/opportunities` | P1 |
| Opportunity Detail Drawer | drawer on pipeline | P1 |
| Users List (Admin) | `/admin/users` | P1 |
| User Detail/Edit | `/admin/users/:id` | P1 |
| Role Management | `/admin/roles` | P1 |

Design file: user Visily export (`visily-to-figma.vis`) — export PNGs to `docs/design/` for dev reference.

---

## Course Requirements Traceability

| Course requirement | PRD coverage |
|--------------------|--------------|
| Authentication | FR-1, FR-2 (partially implemented) |
| Role-based authorization | FR-3 |
| ≥5 models | Glossary + brownfield (7 Tier 1, 15 tables total) |
| ≥6 non-CRUD use cases | UJ-1–UJ-7 |
| Rails + React + PostgreSQL | Stack (addendum) |
| CRUD + validations | FR-4–FR-10 |
| Automated tests | NFR-4, FR-12 |
| Stripe | FR-13 |
| Background jobs | FR-14 |
| Deployment | FR-15 |
| Final presentation | §6.1 milestone |

---

## Authorization Matrix (Implementation Reference)

| Action | Admin | Advisor | Assistant |
|--------|-------|---------|-----------|
| Manage users/roles | ✅ | ❌ | ❌ |
| View all leads | ✅ | Assigned only | Read all |
| CRUD leads | ✅ | Assigned only | ❌ |
| CRUD opportunities | ✅ | On assigned leads | ❌ |
| Create tasks | ✅ | On assigned leads | ✅ |
| View tasks | ✅ | Assigned + lead's | Read |
| CRUD meetings | ✅ | On assigned leads | ❌ |
| Create notes | ✅ | On assigned leads | ✅ |
| View notes | ✅ | On assigned leads | Read |
| Dashboard metrics | All | Own pipeline | Read-only summary |

Implement via Pundit policies or equivalent before exposing admin routes.

---

## 7-Week Delivery Phases

| Week | Focus |
|------|-------|
| 1 | App shell, role auth, Dashboard, README fixes (PRD ✅) |
| 2 | Leads CRUD + Lead Detail (table view) |
| 3 | Tasks + Notes |
| 4 | Meetings + Opportunities pipeline |
| 5 | Search/filters + Admin users/roles + auth tests |
| 6 | Solid Queue job + Stripe test checkout + Kamal deploy |
| 7 | Polish, system tests, final presentation |

---

## Stripe Scope (Minimal Viable)

- One product/plan in Stripe test mode
- Checkout session for "LeadFlow Pro" subscription (demo)
- Webhook handler updates a `subscription_status` flag on User or a lightweight Subscription record
- Gated feature example: export leads CSV behind active subscription
- No full billing portal required for course MVP

---

## Background Job Scope (Minimal Viable)

- `MarkOverdueTasksJob` — daily via Solid Queue recurring config
- Sets `Task` status to overdue when `due_date < today` and status is pending
- Optional: mailer stub (log only) for demo
