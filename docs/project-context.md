---
project_name: LeadFlow CRM
user_name: Cheyenne Calderon
date: '2026-07-05'
sections_completed:
  - technology_stack
  - implementation_state
  - language_rules
  - framework_rules
  - testing_rules
  - quality_rules
  - workflow_rules
  - anti_patterns
status: complete
rule_count: 42
optimized_for_llm: true
---

# Project Context for AI Agents

_This file contains critical rules, current project state, and patterns that AI agents must follow when implementing code in LeadFlow CRM. Read this before any implementation work._

---

## Project Summary

**LeadFlow CRM** is an academic MicroSaaS project (Ruby on Rails + React course). A lightweight CRM for advisors/sales teams: leads, tasks, meetings, notes, opportunities, role-based access.

**Active branch:** `cursor/data-model-v2` (synced to `origin/cursor/data-model-v2`)

**Reference docs:** `README.md`, `docs/DATA_MODEL.md`, `docs/IMPLEMENTATION.md`

**UI design:** Visily export (15 screens) — Dashboard, Leads, Tasks, Meetings, Notes, Pipeline, Users, Roles. Login screen not in export; build a simple one (already started).

**Course still required (not built):** full CRUD UI, role authorization enforcement, Stripe payments, background jobs, production deploy, final presentation.

---

## Current Implementation State

### Done

| Area | Status | Notes |
|------|--------|-------|
| Rails scaffold | ✅ | Rails 8.1, Inertia, Vite, React 19, TypeScript, Tailwind 4 |
| Database | ✅ | 15 tables, schema version `20260624023634` |
| Models | ✅ | 15 domain models + associations + validations |
| Seeds | ✅ | Countries, roles, stages, admin user |
| Model tests | ✅ | 40 model tests with fixtures |
| Session auth | ✅ | Login/logout, `Authentication` concern, Inertia login page |
| Role authorization | ✅ | Pundit policies + admin routes |
| App shell | ✅ | Sidebar layout, role-aware nav (Story 1.4) |
| Dashboard metrics | ✅ | Open leads, overdue tasks, meetings, pipeline value (Story 1.5) |
| Leads index | ✅ | Role-scoped table + search + pagination (Story 2.1) |
| Create lead | ✅ | New lead form + company dedup + unique email (Story 2.2) |
| Edit lead | ✅ | Edit form + per-row authorize + shared LeadForm (Story 2.3) |
| Lead detail | ✅ | Show page + related previews; create/update redirect to detail (Story 2.4); New Task + Complete (3.2); Notes timeline + Add note (3.3); Schedule meeting (4.1) |
| Tasks list | ✅ | Role-scoped table + All/Mine/Overdue (3.1); create/complete modal + CTA (3.2) |
| Opportunities pipeline | ✅ | Kanban by OpportunityStage (Story 4.2); detail drawer update (Story 4.3) |
| CI | ✅ | Brakeman, bundler-audit, RuboCop, Rails test + system test jobs |
| Docs | ✅ | DATA_MODEL (Tier 1+2), IMPLEMENTATION guide |

**Dev login** (after `bin/rails db:seed`) — all use password `password`:

| Role | Email |
|------|-------|
| Admin | admin@leadflow.local |
| Advisor | advisor@leadflow.local |
| Assistant | assistant@leadflow.local |

### Not done

| Area | Priority |
|------|----------|
| Controller CRUD + integration tests (remaining) | High |
| Stripe integration | Required by course | Checkout + webhook ✅; gated CSV export ✅ |
| Production deploy (Kamal/Docker scaffold exists) | Required by course |
| BMad planning artifacts (PRD, epics, sprint plan) | Optional but recommended |

---

## Technology Stack & Versions

| Layer | Technology | Version / notes |
|-------|------------|-----------------|
| Backend | Ruby on Rails | ~> 8.1.3 |
| Ruby | See `.ruby-version` | 3.3.x |
| DB | PostgreSQL | `pg` ~> 1.1 |
| Auth | bcrypt + session cookie | `has_secure_password`, `session[:user_id]` |
| Frontend | React | ^19.2.6 |
| SPA bridge | Inertia.js | `@inertiajs/react` ^3.1.1, `inertia_rails` ~> 3.21 |
| Bundler | Vite | ^8.0.13, `vite_rails` ~> 3.11 |
| CSS | Tailwind CSS | ^4.3.0 via `@tailwindcss/vite` |
| Language | TypeScript | ^6.0.3 — run `npm run check` in CI locally |
| Jobs | Solid Queue | `MarkOverdueTasksJob` + recurring daily schedule |
| Deploy | Kamal + Docker | Scaffold present, not deployed |
| Tests | Minitest + Capybara | Model + controller tests; system test scaffold |

---

## Critical Implementation Rules

### Language-Specific Rules (Ruby)

- Use `# frozen_string_literal: true` on new Ruby files (matches existing controllers/models).
- Follow RuboCop Rails Omakase — CI runs `bin/rubocop -f github`.
- **Stage foreign keys:** `Lead` belongs_to `:stage` → `lead_stages`; `Opportunity` belongs_to `:stage` → `opportunity_stages`. Always use `foreign_key: { to_table: :lead_stages }` (or `:opportunity_stages`) in migrations — never bare `:stage` without `to_table`.
- Model is **`Task`**, not `FollowUpTask` — table is `tasks`.
- **Company dedup:** use `Company.find_or_initialize_by_name(name)` and `Company.normalize_name` — do not create duplicate companies from typos.
- **Lead email uniqueness:** emails are required, normalized (strip + downcase), and unique. Use `Lead.find_or_initialize_by_email(email, **attrs)` when creating leads — never insert a second lead with the same email.
- Email lookup: strip + downcase before find (see `SessionsController#normalized_email`).
- Prefer `update_column` only for non-validated timestamps (e.g. `last_login_at` on login).

### Language-Specific Rules (TypeScript / React)

- Pages live under `app/javascript/pages/` — Inertia resolves `"sessions/new"` → `pages/sessions/new.tsx`.
- Shared props types in `app/javascript/types/index.ts`: `AuthUser`, `SharedProps`, `FlashData`.
- Use `@inertiajs/react` `useForm` for form POST/PUT/DELETE — not raw `fetch`.
- Inertia errors from Rails: `inertia: { errors: { field: ["message"] } }` — display with `errors.field?.join(', ')`.
- Run `npm run check` before pushing — type-checks app and node tsconfigs.

### Framework-Specific Rules (Rails + Inertia)

- **All authenticated UI controllers** inherit from `InertiaController` (not `ApplicationController` directly).
- `InertiaController` already: `require_authentication`, shares `auth.user` and `flash` to every page.
- Public pages (login): inherit `InertiaController` + `allow_unauthenticated_access only: [...]`.
- Render pages: `render inertia: "folder/page", props: { ... }` — props must be JSON-serializable.
- Root after login: `dashboard#index` with summary metric widgets.
- Dev: `bin/dev` starts Rails **:3000** + Vite **:3036** — only browse port 3000.
- Host redirect: `127.0.0.1` → `localhost` in routes (Vite/Inertia cookie consistency).

### Data Model Rules

- **Tier 1 (course README):** Role, User, Lead, Opportunity, Task, Meeting, Note.
- **Tier 2 (UI fidelity):** LeadStage, OpportunityStage, Team, Tag, LeadTag, NoteTag, Country, Company.
- Lead requires: `name`, `email` (unique), `company`, `country`, `stage`, `user` (assigned advisor).
- Task requires: `title`, `due_date`. Note requires: `content`. Opportunity: `value > 0` when present.
- Roles (seeded): `admin`, `advisor`, `assistant` — Pundit policies enforce access for Leads/Tasks (and related child records); see `docs/DATA_MODEL.md` for intended permissions.

### Testing Rules

- Fixtures in `test/fixtures/` — use realistic unique data; access via `users(:admin)`.
- `sign_in_as(user)` in `test/test_helper.rb` for controller/integration tests.
- Model tests: validations, associations, business logic (see `company_test.rb` for normalization pattern).
- Run `bin/rails test` — full suite must pass before PR.
- New controllers: add tests in `test/controllers/`; follow `sessions_controller_test.rb` patterns.

### Code Quality & Style Rules

- Minimal diff — match existing patterns; no unrelated refactors.
- No commits unless user explicitly asks.
- Do not commit `.env`, credentials keys, or `_bmad/` local config.
- Comments only for non-obvious business logic (e.g. stage FK fix, company normalization).

### Development Workflow Rules

- Feature branches: `cursor/<feature-name>` pattern in use.
- Integration branch: `dev` (not `main` for epic PRs).
- GitHub remote: `https://github.com/ccalderonc-ruby/lead-flow.git`.
- CI runs on PRs — keep green before merge.
- Implementation details for humans: update `docs/IMPLEMENTATION.md` when completing major steps.
- **Bug / polish triage:** follow `docs/BUG_POLISH_TRIAGE.md` — patch now vs before next epic vs park-with-label. Never leave unlabeled “fix later” piles.

### Critical Don't-Miss Rules

- **Do not** browse Vite port 3036 — assets only.
- **Do not** rename `Task` back to `FollowUpTask` — breaks schema and tests.
- **Do not** add a generic `stages` table — use `lead_stages` and `opportunity_stages`.
- **Do not** skip `InertiaController` for new pages — you'll lose shared `auth` props.
- **Do not** implement JWT/API-token auth — project uses cookie sessions.
- **Do not** over-build Tier 2 UI (tags, teams) before Tier 1 CRUD works.
- **Role authorization** must be added before exposing admin routes (Users, Roles screens).
- Visily designs are the UI source of truth — 15 screens listed; implement table Leads view before card view.

---

## Suggested Build Order (for agents planning work)

1. Merge/consolidate on `cursor/data-model-v2` ✅ (current)
2. App layout + role-aware navigation
3. Leads CRUD (index → show → new/edit)
4. Tasks + Notes on lead detail
5. Meetings + Opportunities pipeline
6. Dashboard widgets
7. Admin: Users + Role management + authorization
8. Background job (overdue tasks) ✅
9. Stripe (minimal checkout) ✅
10. Kamal deploy + presentation prep

---

## Usage Guidelines

**For AI Agents:**

- Read this file + `docs/DATA_MODEL.md` + `docs/IMPLEMENTATION.md` before implementing.
- Follow ALL rules above; prefer restrictive option when unsure.
- Update `sections_completed` and implementation state when major milestones ship.
- Use `bmad-help` for workflow routing; use `bmad-prd` / epics when formal planning is needed.

**For Humans:**

- Keep this file lean — agent-facing rules and state, not narrative docs.
- Update when stack changes or new patterns emerge.
- Detailed how-to stays in `docs/IMPLEMENTATION.md`.

_Last updated: 2026-07-05_
