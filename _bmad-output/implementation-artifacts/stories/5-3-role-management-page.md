---
baseline_commit: 89c4b0707e8d2205ac64ec27a47ae5c7b93d7cf4
---

# Story 5.3: Role management page

Status: done

<!-- Ultimate context engine analysis completed - comprehensive developer guide created -->

## Story

As an **Admin**,
I want to view role definitions and permissions,
So that I understand access levels for the demo.

**Epic:** 5 — Administer the Team  
**Week:** 5  
**Fulfills:** FR-14, UX-DR10  
**Depends on:** Epic 1 role policies ✅, Story 5.2 admin users ✅ (sprint `done`; may still be uncommitted on `feature/5-2-admin-user-management`)  
**Unblocks:** Demo clarity for UJ-4/UJ-5; Story 5.4 filters (independent)

---

## Acceptance Criteria

1. **Given** I am Admin and visit `/admin/roles`  
   **When** the page loads  
   **Then** I see the three seeded roles **admin**, **advisor**, and **assistant**  
   **And** a **read-only** permission matrix summarizing access (Leads, Opportunities, Tasks, Meetings, Notes, Users at minimum)

2. **Given** the Roles page  
   **When** I inspect controls  
   **Then** there is **no** create/edit/delete of roles  
   **And** there is **no** dynamic permission editing (roles stay seeded; no Permission model)

3. **Given** I am Advisor or Assistant  
   **When** I request `/admin/roles`  
   **Then** I am denied (same admin gate as Users — keep `authorize User`)

4. **Given** docs / course demo  
   **When** implementing  
   **Then** matrix labels match **enforced Pundit behavior** (not a wishful matrix)  
   **And** `docs/IMPLEMENTATION.md` gets **Step 20**

---

## Tasks / Subtasks

- [x] **Controller props** (AC: 1–3)
  - [x] `Admin::RolesController#index`: keep `authorize User`; pass JSON-serializable `roles` + `matrix` (or equivalent) — no raw AR
  - [x] Load role names from `Role.order(:name)` (must include admin/advisor/assistant after seeds)
  - [x] Do **not** add RolePolicy unless you have a clear reason — current admin gate is correct

- [x] **Read-only UI** (AC: 1–2)
  - [x] Replace `PlaceholderPage` in `app/javascript/pages/admin/roles/index.tsx`
  - [x] Use `AuthenticatedPage` + `<Head title="Roles">`
  - [x] Visual pattern: match admin users index (bordered white table / clear hierarchy) — display only
  - [x] Explicit copy that permissions are fixed / seeded (one short sentence)

- [x] **Matrix content** (AC: 1, 4)
  - [x] Encode static summary cells from the **Canonical matrix** in Dev Notes (derived from policies + DATA_MODEL)
  - [x] Prefer server-provided strings (or boolean + label map) so the page cannot drift from a single source in the controller/helper
  - [x] Optional: tiny `Admin::RolePermissions` constant/helper — keep surgical; do not invent DB-backed permissions

- [x] **Tests** (AC: 1–3)
  - [x] Controller/integration: admin success + props include three roles; advisor/assistant denied (extend `admin_access_test` / `app_navigation_test` or add `admin/roles_controller_test`)
  - [x] Assert matrix keys/roles present (lightweight — not a full policy re-test)

- [x] **Docs + sprint**
  - [x] IMPLEMENTATION Step 20; update “NOT implemented” table
  - [x] Story → review; sprint `5-3-role-management-page` → review

### Review Findings

- [x] [Review][Patch] Admin Users label overstates permissions [`app/services/admin/role_permissions.rb:17`] — `CRUD` omits self-disable/self-destroy guards; use e.g. `Manage (self protected)`.
- [x] [Review][Patch] Advisor Leads label understates create [`app/services/admin/role_permissions.rb:20`] — advisors can create leads; prefer e.g. `Create; manage assigned`.
- [x] [Review][Patch] Unknown roles become blank matrix rows [`app/services/admin/role_permissions.rb:39`] — only emit rows for known MATRIX keys (seeded admin/advisor/assistant).
- [x] [Review][Patch] Empty roles has no empty state [`app/javascript/pages/admin/roles/index.tsx`] — show a short message when `roles` is empty.
- [x] [Review][Defer] Static MATRIX can drift from policies — deferred, accepted Story 5.3 design (manual labels)
- [x] [Review][Defer] Deeper matrix/prop parsing test coverage — deferred, residual

---

## Dev Notes

### MUST follow

1. **Read-only MVP.** PRD: `[ASSUMPTION: dynamic permission editing deferred — roles are seeded]`.
2. Inherit `InertiaController`; admin namespace already wired.
3. Authz: `authorize User` (admin-only via `UserPolicy#index?`) — same as current RolesController and Users index collection gate.
4. Nav already has Roles link for admins (`navigation.ts` + `AppLayout`) — do not rebuild nav.
5. No FormFields / `useForm` / `useDialogA11y` unless you add a dialog (you should not).
6. Triage: `docs/BUG_POLISH_TRIAGE.md`.
7. Do **not** implement 5.4 lead filters “while here.”

### Canonical matrix (source of truth for this page)

Align UI labels with **policies in code**. DATA_MODEL table is the course-facing summary; note where code is slightly richer:

| Area | Admin | Advisor | Assistant |
|------|-------|---------|-----------|
| Leads | All (CRUD + all scope) | Assigned only | Read only (all scope) |
| Opportunities | All | On assigned leads | Read only |
| Tasks | All | On assigned leads | Create + update + read (all scope); destroy only admin/assigned advisor |
| Meetings | All | On assigned leads | Read only |
| Notes | All | On assigned leads | Create + update + read; destroy only admin/assigned advisor |
| Users / Admin | CRUD (self-disable/demote guarded) | — | — |

**Labeling tip:** For assistant Tasks/Notes, DATA_MODEL says “Create + read” but `TaskPolicy`/`NotePolicy` also allow `update?`. Prefer accurate labels like **“Create, update, read”** or a compact **“Write (no delete)”** rather than understating.

Do not claim assistant can create meetings/opportunities/leads — policies deny that.

### Current state (read before editing)

| Piece | Path | Notes |
|-------|------|--------|
| Page | `app/javascript/pages/admin/roles/index.tsx` | Matrix UI |
| Controller | `app/controllers/admin/roles_controller.rb` | props |
| Helper | `app/services/admin/role_permissions.rb` | static MATRIX |
| Routes | `config/routes.rb` | `resources :roles, only: :index` |

### Anti-patterns (DO NOT)

- Role CRUD, permission toggles, checkboxes that POST
- New `permissions` table / CanCan / Rolify
- `RolePolicy` that accidentally opens roles to advisors
- Duplicating full policy logic in React (hard-code matrix from server)
- Changing Lead/Task/etc. policies “to match the matrix” — matrix follows policies
- Touching Stripe/jobs/5.4 filters

### Git / branch

- Baseline: `89c4b07` (`origin/dev`)
- Branch: `feature/5-3-role-management-page`
- PR base: **`dev`**

### References

- [epics.md Story 5.3](../../planning-artifacts/epics.md)
- [PRD FR-14](../../planning-artifacts/prds/prd-leadflow-crm-2026-07-05/prd.md)
- [DATA_MODEL Role permissions](../../../docs/DATA_MODEL.md)
- [BUG_POLISH_TRIAGE](../../../docs/BUG_POLISH_TRIAGE.md)

### Verification

```bash
bin/rails test
npm run check
```

---

## Dev Agent Record

### Agent Model Used

Composer (dev-story)

### Debug Log References

### Completion Notes List

- Replaced Roles placeholder with read-only seeded-roles list + permission matrix table.
- `Admin::RolePermissions` holds static labels matching Pundit (assistant Tasks/Notes: “Create, update, read”).
- Review patches: accurate Users/Leads labels; only seeded roles in matrix; empty-state copy.
- `Admin::RolesController` still uses `authorize User`; passes `roles`, `matrix`, `read_only`.
- Tests: roles controller + RolePermissions unit; full suite 229 green; `npm run check` clean.
- Docs: IMPLEMENTATION Step 20; project-context Not-done updated.

### File List

- `app/services/admin/role_permissions.rb`
- `app/controllers/admin/roles_controller.rb`
- `app/javascript/pages/admin/roles/index.tsx`
- `test/controllers/admin/roles_controller_test.rb`
- `test/services/admin/role_permissions_test.rb`
- `docs/IMPLEMENTATION.md`
- `docs/project-context.md`
- `_bmad-output/implementation-artifacts/stories/5-3-role-management-page.md`
- `_bmad-output/implementation-artifacts/sprint-status.yaml`

### Change Log

- 2026-07-22: Created comprehensive Story 5.3 context (read-only roles + permission matrix); status → ready-for-dev
- 2026-07-22: Implemented read-only roles matrix + tests + Step 20; status → review
- 2026-07-22: Code review patches applied (label accuracy, seeded-only rows, empty state); status → done
