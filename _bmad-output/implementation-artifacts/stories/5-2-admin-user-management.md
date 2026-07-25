---
baseline_commit: 89c4b0707e8d2205ac64ec27a47ae5c7b93d7cf4
---

# Story 5.2: Admin user management

Status: done

<!-- Ultimate context engine analysis completed - comprehensive developer guide created -->

## Story

As an **Admin**,
I want to create and edit users with roles,
So that I can onboard the team (UJ-5).

**Epic:** 5 — Administer the Team  
**Week:** 5  
**Fulfills:** FR-13, UX-DR9  
**Depends on:** Epic 1 auth/admin shell ✅, Story 5.1 demo seeds ✅ (sprint `done`; merge/PR may still be open)  
**Unblocks:** 5.3 role matrix page (read-only; roles already seeded)

---

## Acceptance Criteria

1. **Given** I am Admin on `/admin/users`  
   **When** I create a user with name, email, role, password (min 8 chars)  
   **Then** the user can log in with the assigned role  
   **And** required `team_id` / `country_id` are set (schema NOT NULL — include in form or default to seeded Enterprise Sales + a country)

2. **Given** I edit a user  
   **When** I change role or set status to `disabled`  
   **Then** changes persist  
   **And** a disabled user cannot log in (session create rejects them)

3. **Given** I am the logged-in admin  
   **When** I attempt to delete or disable myself  
   **Then** the action is prevented (server-side; UI hide alone is insufficient)

4. **Given** FR-13  
   **When** implementing  
   **Then** Admin can **list, create, edit, and disable** users  
   **And** hard delete is **out of scope** for the UI (prefer disable). Existing `UserPolicy#destroy?` may stay for future use but do not add destroy routes/buttons unless deletion is safe (see Dev Notes — `leads.user_id` is NOT NULL).

---

## Tasks / Subtasks

- [x] **Model + auth boundary** (AC: 1–3)
  - [x] `User`: validate `status` ∈ `active|disabled` (default `active`); password length ≥ 8 on create / when password present on update (`allow_nil: true` for blank edit password)
  - [x] `SessionsController#create`: reject disabled (and treat blank/`nil` as active for fixtures); same generic invalid-credentials error
  - [x] `UserPolicy`: prevent self-disable — e.g. `update?` false when admin would set own status to disabled, **or** explicit check in controller before save; keep `destroy?` blocking self

- [x] **Admin Users CRUD (Inertia)** (AC: 1–2, 4)
  - [x] Routes: expand `admin/users` beyond `index` → `new create edit update` (no `destroy` unless you solve FK safety)
  - [x] `Admin::UsersController`: `authorize` / `policy_scope(User)`; serialize JSON props (never raw AR); Inertia validation errors; flash + redirect
  - [x] Index: replace `PlaceholderPage` with table (name, email, role, status, actions) + New User CTA when `can_create`
  - [x] Form: FormFields (`TextField` / `SelectField`); create requires password; edit password optional; role + status + team + country selects
  - [x] Self row: hide/disable “Disable” / destructive controls; still enforce server-side

- [x] **Tests** (AC: 1–3)
  - [x] Model: status inclusion; password min length
  - [x] Sessions: disabled user cannot sign in
  - [x] Policy: self-disable / self-destroy denied
  - [x] Controller: admin CRUD happy path; advisor/assistant denied; self-disable rejected; create with short password errors

- [x] **Docs + sprint**
  - [x] `docs/IMPLEMENTATION.md` Step 19 (Story 5.2)
  - [x] Story → review; sprint `5-2-admin-user-management` → review

### Review Findings

- [x] [Review][Patch] Guard last active admin + block self role-demotion [`app/controllers/admin/users_controller.rb`] — decided: reject updates that leave zero active admins; reject current user changing their own role away from admin.
- [x] [Review][Patch] Disabled users keep live sessions [`app/controllers/concerns/authentication.rb`] — `authenticate_user!` / `current_user` never check `active?`; disable only blocks new logins.
- [x] [Review][Patch] Disable path ignores `UserPolicy#disable?` [`app/controllers/admin/users_controller.rb:60`] — when status → `disabled`, authorize via `disable?` (not only the self-disable flash check).
- [x] [Review][Patch] Unstable user pagination [`app/controllers/admin/users_controller.rb:15`] — `order(:name)` only; add `:id` tiebreaker.
- [x] [Review][Patch] Dead `can_disable` on index rows [`app/controllers/admin/users_controller.rb:123`] — index exposes it but has no disable action (disable is via edit status); remove from index serialize.
- [x] [Review][Defer] No DB check constraint on `users.status` — deferred, pre-existing schema
- [x] [Review][Defer] Case-sensitive unique index on `users.email` — deferred, pre-existing (app now normalizes)

---

## Dev Notes

### MUST follow

1. Inherit `InertiaController`. Admin namespace already used — keep `Admin::UsersController`.
2. Pundit: `authorize User` / `authorize @user`; lookups via `policy_scope(User)`.
3. FormFields + `@/lib/format` — no ad-hoc inputs. Match Leads list/form patterns.
4. Inertia errors: `redirect_to ..., inertia: { errors: record.errors }` (or field hash). Use `useForm` on the client.
5. Email normalize: strip + downcase (same as sessions).
6. Roles from `Role.order(:name)` — do **not** invent permission editing (that’s 5.3 read-only matrix).
7. Triage: `docs/BUG_POLISH_TRIAGE.md`. New dialogs → `useDialogA11y` only if you add a modal (full pages are fine).
8. **Do not** reset demo seed passwords here — `DemoSeeds` already restores on `db:seed` (5.1 review decision).

### Current state (read before editing)

| Piece | Path | Notes |
|-------|------|--------|
| Placeholder index | `app/javascript/pages/admin/users/index.tsx` | Replaced |
| Controller | `app/controllers/admin/users_controller.rb` | CRUD |
| Routes | `config/routes.rb` | index/new/create/edit/update |
| Policy | `app/policies/user_policy.rb` | + `disable?` |
| Sessions | `app/controllers/sessions_controller.rb` | `user.active?` gate |
| User model | `app/models/user.rb` | status + password length |

### Schema / deletion trap

- `users.team_id`, `users.country_id`, `users.role_id` — NOT NULL.
- `leads.user_id` — NOT NULL despite `User has_many :leads, dependent: :nullify`. **Hard delete of a user with leads will fail or corrupt.** Prefer **disable**; skip destroy UI.

### Anti-patterns (DO NOT)

- Soft-delete gem / Devise — project uses `has_secure_password` + sessions
- Separate `Admin::UserPolicy` unless needed — extend `UserPolicy`
- Building 5.3 permission matrix or 5.4 lead filters “while here”
- Allowing blank password on **create**
- Showing Users nav to non-admins (already gated)

### Previous story intelligence (5.1)

- Demo users: `admin@leadflow.local` / `advisor@` / `assistant@` — password `password` restored on re-seed
- `DemoSeeds` in `app/services/demo_seeds.rb`
- Integration branch: **`dev`**

### Git / branch

- Baseline: `89c4b07` (`origin/dev`)
- Branch: `feature/5-2-admin-user-management` (includes uncommitted 5.1 work in worktree)
- PR base: **`dev`**

### References

- [epics.md Story 5.2](../../planning-artifacts/epics.md)
- [PRD FR-13](../../planning-artifacts/prds/prd-leadflow-crm-2026-07-05/prd.md)
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

- Admin users list/create/edit with FormFields; no destroy routes (disable only).
- `User` validates status + password min 8; email normalize; default status active.
- Sessions reject disabled users; disabled users lose existing sessions via `Authentication#current_user`.
- Self-disable blocked via `UserPolicy#disable?`; self role-demotion blocked; last-active-admin guard on update.
- Docs: IMPLEMENTATION Step 19; project-context Not-done updated.
- Code review patches applied; 224 tests green; `npm run check` clean.

### File List

- `app/models/user.rb`
- `app/policies/user_policy.rb`
- `app/controllers/sessions_controller.rb`
- `app/controllers/admin/users_controller.rb`
- `config/routes.rb`
- `app/javascript/components/admin/UserForm.tsx`
- `app/javascript/pages/admin/users/index.tsx`
- `app/javascript/pages/admin/users/new.tsx`
- `app/javascript/pages/admin/users/edit.tsx`
- `test/models/user_test.rb`
- `test/policies/user_policy_test.rb`
- `test/controllers/sessions_controller_test.rb`
- `test/controllers/admin/users_controller_test.rb`
- `test/services/demo_seeds_test.rb`
- `docs/IMPLEMENTATION.md`
- `docs/project-context.md`
- `_bmad-output/implementation-artifacts/stories/5-2-admin-user-management.md`
- `_bmad-output/implementation-artifacts/sprint-status.yaml`

### Change Log

- 2026-07-21: Created comprehensive Story 5.2 context; status → ready-for-dev
- 2026-07-21: Implemented admin user CRUD + disable auth boundary; status → review
- 2026-07-21: Code review patches applied (session active check, admin guards, pagination); status → done
