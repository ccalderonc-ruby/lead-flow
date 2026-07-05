# Story 1.4: App layout and role-aware navigation

Status: done

<!-- Ultimate context engine analysis completed — comprehensive developer guide for Story 1.4 -->

## Story

As a **User**,
I want a consistent sidebar and header on every page,
So that I can navigate the CRM without confusion.

**Epic:** 1 — Access the CRM  
**Week:** 1  
**Fulfills:** FR-4, UX-DR1  
**Depends on:** Stories 1.2 ✅, 1.3 ✅ (session auth + Pundit)

---

## Acceptance Criteria

1. **Given** I am authenticated  
   **When** I visit any Inertia CRM page  
   **Then** I see a sidebar with Dashboard, Leads, Tasks, Meetings, Opportunities

2. **Given** I am authenticated as Admin  
   **When** I view the sidebar  
   **Then** I additionally see Users and Roles links

3. **Given** I am authenticated as Advisor or Assistant  
   **When** I view the sidebar  
   **Then** I do not see admin links

4. **Given** the layout component exists  
   **When** rendered on any authenticated page  
   **Then** it shows my name, role, and Sign out control  
   **And** matches Visily Dashboard chrome (UX-DR1)

5. **And** login page (`/login`) renders without the app shell (centered card only)

---

## Tasks / Subtasks

- [x] **AppLayout component** (AC: 1, 4)
  - [x] Create `app/javascript/components/layouts/AppLayout.tsx` — sidebar, main content, flash
  - [x] Visily-style chrome: logo, nav links, user footer with name/role/sign out
  - [x] Active nav state from Inertia `usePage().url`
  - [x] Responsive: sidebar on `lg+`, mobile menu toggle

- [x] **Navigation config** (AC: 1–3)
  - [x] `app/javascript/lib/navigation.ts` — main nav + admin-only nav
  - [x] Filter admin links when `auth.user.role !== 'admin'`

- [x] **Layout wiring** (AC: 1, 5)
  - [x] `AuthenticatedPage` wrapper renders `AppLayout` on authenticated pages (replaces `.layout` pattern — fixes post-login mount)
  - [x] Login page excluded from shell

- [x] **Placeholder CRM pages + routes** (AC: 1)
  - [x] Controllers: Dashboard, Leads, Tasks, Meetings, Opportunities (index only)
  - [x] Inertia pages under `app/javascript/pages/` with layout
  - [x] Root `/` → dashboard placeholder (Story 1.5 adds metrics)
  - [x] Admin: Users + Roles index pages (replace `head :ok` stub)

- [x] **Tests** (AC: 1–3)
  - [x] Controller tests: authenticated access to each nav route
  - [x] Admin roles index: admin allowed; advisor + assistant denied (Pundit)
  - [x] Fixed duplicate Inertia entrypoint + Turbo conflict (`data-turbo="false"`)

- [x] **Docs**
  - [x] Update `docs/IMPLEMENTATION.md` Step 5 — app shell

---

## Dev Notes

### UX reference (UX-DR1)

From [addendum.md](../../planning-artifacts/prds/prd-leadflow-crm-2026-07-05/addendum.md):

| Screen | Route |
|--------|-------|
| Dashboard | `/` |
| Leads | `/leads` |
| Tasks | `/tasks` |
| Meetings | `/meetings` |
| Opportunities | `/opportunities` |
| Users (Admin) | `/admin/users` |
| Roles (Admin) | `/admin/roles` |

**Chrome:** Dark sidebar (`slate-900`), LeadFlow logo, nav links, user block at bottom with sign out. Main content area white with padding. Match login page palette (indigo accents).

### Shared props (already exist)

`InertiaController` shares `auth.user` `{ id, name, email, role }` and `flash`. Use `usePage<SharedProps>()` in layout.

### Do NOT

- Do not implement dashboard metrics (Story 1.5)
- Do not implement CRUD on placeholder pages (Epic 2+)
- Do not remove `inertia_example` route yet — keep for dev reference until 1.5
- Do not skip `InertiaController` for new pages

### Previous story learnings

- Admin routes use `authorize User` (UserPolicy#index? → admin only)
- Sign out: `router.delete('/logout')` from Inertia
- TypeScript path alias: `@/` → `app/javascript/`

### References

- [Source: docs/project-context.md](../../../docs/project-context.md) — Inertia pages, layout rules
- [Source: _bmad-output/planning-artifacts/epics.md](../../planning-artifacts/epics.md#story-14-app-layout-and-role-aware-navigation)
- [Source: app/controllers/inertia_controller.rb](../../../app/controllers/inertia_controller.rb)

---

## Dev Agent Record

### Agent Model Used

Composer (dev-story)

### Debug Log References

- Full suite: 69 tests, 165 assertions, 0 failures
- `npm run check` passes

### Completion Notes List

- `AppLayout` with Visily-style dark sidebar, role-aware admin section, mobile menu
- `AuthenticatedPage` wrapper (not `.layout`) — reliable shell after login redirect
- Root route now serves dashboard placeholder; CRM nav routes wired
- Removed duplicate `inertia.jsx` entrypoint; disabled Turbo on body for Inertia compatibility
- `SessionsController`: `inertia_location` for Inertia login/logout; 303 redirect for integration tests
- Admin Users index now renders Inertia page (was `head :ok`)
- Dev seeds: admin, advisor, assistant users; `vite.json` skipProxy false for single-port dev
- System/browser tests deferred — headless Chrome does not hydrate Inertia reliably in CI yet; controller tests cover routes

### Review Findings

- [x] [Review][Patch] Remove stale `inertia_example/index.jsx` duplicate [app/javascript/pages/inertia_example/index.jsx] — applied
- [x] [Review][Patch] Remove self-testing `navigation_config_test.rb` (mirrored TS logic in Ruby, not production) [test/lib/navigation_config_test.rb] — applied
- [x] [Review][Patch] Add assistant denied admin roles test (AC3) [test/controllers/app_navigation_test.rb] — applied
- [x] [Review][Defer] Mobile nav overlay does not auto-close on nav link click [app/javascript/components/layouts/AppLayout.tsx] — deferred, UX polish for later
- [x] [Review][Defer] CRM index controllers have no Pundit authorize yet [app/controllers/leads_controller.rb] — deferred, Epic 2 CRUD scope

### File List

- app/javascript/components/layouts/AppLayout.tsx
- app/javascript/components/layouts/AuthenticatedPage.tsx
- app/javascript/components/PlaceholderPage.tsx
- app/javascript/lib/navigation.ts
- app/javascript/pages/dashboard/index.tsx
- app/javascript/pages/leads/index.tsx
- app/javascript/pages/tasks/index.tsx
- app/javascript/pages/meetings/index.tsx
- app/javascript/pages/opportunities/index.tsx
- app/javascript/pages/admin/users/index.tsx
- app/javascript/pages/admin/roles/index.tsx
- app/javascript/pages/inertia_example/index.tsx
- app/controllers/dashboard_controller.rb
- app/controllers/leads_controller.rb
- app/controllers/tasks_controller.rb
- app/controllers/meetings_controller.rb
- app/controllers/opportunities_controller.rb
- app/controllers/admin/roles_controller.rb
- app/controllers/admin/users_controller.rb
- app/controllers/sessions_controller.rb
- app/views/layouts/application.html.erb
- config/routes.rb
- config/vite.json
- db/seeds.rb
- test/controllers/app_navigation_test.rb
- docs/IMPLEMENTATION.md
- docs/project-context.md
- .github/workflows/ci.yml
