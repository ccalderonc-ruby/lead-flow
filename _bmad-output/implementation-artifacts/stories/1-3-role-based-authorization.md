# Story 1.3: Role-based authorization

Status: ready-for-dev

<!-- Ultimate context engine analysis completed — comprehensive developer guide for Story 1.3 -->

## Story

As a **User**,
I want the system to enforce my role permissions on every action,
So that advisors, assistants, and admins only access what they should.

**Epic:** 1 — Access the CRM  
**Week:** 1  
**Fulfills:** FR-3, NFR-2  
**Depends on:** Stories 1.1 ✅, 1.2 ✅ (schema + session auth)

---

## Acceptance Criteria

1. **Given** authorization policies exist for Lead, Task, Note, Meeting, Opportunity, and User  
   **When** an Advisor attempts to access a future `/admin/users` route (stub controller or route guard is acceptable for this story)  
   **Then** they receive HTTP 403 or redirect with flash alert (fail closed)

2. **Given** an Advisor is authenticated  
   **When** they attempt to update a Lead not assigned to them (`lead.user_id != current_user.id`)  
   **Then** the action is denied

3. **Given** an Assistant is authenticated  
   **When** they create a Note on any Lead (via a minimal test-only or placeholder endpoint, or model-level policy test)  
   **Then** the action is permitted

4. **Given** an Assistant is authenticated  
   **When** they attempt to destroy a Lead  
   **Then** the action is denied

5. **Given** an Admin is authenticated  
   **When** they perform CRUD on any Lead  
   **Then** the action is permitted

6. **And** controller or policy tests cover at least one denial path per role (admin, advisor, assistant)

---

## Tasks / Subtasks

- [ ] **Add Pundit** (AC: all)
  - [ ] Add `gem "pundit"` to Gemfile, `bundle install`
  - [ ] Run `bin/rails generate pundit:install`
  - [ ] Include `Pundit::Authorization` in `ApplicationController`
  - [ ] Add `pundit_user` method returning `current_user`
  - [ ] `rescue_from Pundit::NotAuthorizedError` → redirect with alert (Inertia-friendly)

- [ ] **User role helpers** (AC: all)
  - [ ] Add to `User`: `admin?`, `advisor?`, `assistant?` (compare `role.name`)
  - [ ] Optional: `Role` constants or enum-like methods for `"admin"`, `"advisor"`, `"assistant"`

- [ ] **ApplicationPolicy base** (AC: all)
  - [ ] `ApplicationPolicy` with `user`, `record`, default deny
  - [ ] Admin bypass: `def admin?; user&.admin?; end` and `def index?; admin?; end` pattern where appropriate

- [ ] **Resource policies** (AC: 2–5)
  - [ ] `LeadPolicy` — admin all; advisor assigned only; assistant read-only (index/show), no create/update/destroy
  - [ ] `NotePolicy` — admin/advisor on assigned leads; assistant create + read on any lead
  - [ ] `TaskPolicy` — admin all; advisor on assigned leads; assistant create + read
  - [ ] `MeetingPolicy` — admin all; advisor on assigned leads; assistant read only
  - [ ] `OpportunityPolicy` — admin all; advisor on assigned leads; assistant read only
  - [ ] `UserPolicy` — admin only for manage actions; others denied

- [ ] **Controller integration hook** (AC: 1, 2)
  - [ ] Add `authorize` / `policy_scope` pattern to `InertiaController` or a concern `Authorization` (do not confuse with existing `Authentication` concern)
  - [ ] Create minimal `Admin::BaseController < InertiaController` with `before_action { authorize :admin, :access? }` or per-controller `authorize` — stub `/admin/users` route pointing to placeholder action for advisor denial test

- [ ] **Test fixtures** (AC: 6)
  - [ ] Add `assistant` to `test/fixtures/roles.yml` and `test/fixtures/users.yml` if missing
  - [ ] Ensure `leads.yml` has lead assigned to `advisor` and one unassigned/other advisor for scoping tests

- [ ] **Tests** (AC: 6)
  - [ ] `test/policies/lead_policy_test.rb` — advisor denied on other's lead; assistant cannot destroy
  - [ ] `test/policies/note_policy_test.rb` — assistant can create
  - [ ] `test/controllers/admin_access_test.rb` — advisor denied on admin route
  - [ ] All existing 46 tests still pass

- [ ] **Docs** (optional, minimal)
  - [ ] Note in `docs/IMPLEMENTATION.md` Step 4 — authorization approach

---

## Dev Notes

### Authorization matrix (source of truth)

From [addendum.md](../../planning-artifacts/prds/prd-leadflow-crm-2026-07-05/addendum.md) and [DATA_MODEL.md](../../../docs/DATA_MODEL.md#role-permissions):

| Action | Admin | Advisor | Assistant |
|--------|-------|---------|-----------|
| Manage users/roles | ✅ | ❌ | ❌ |
| View leads | All | Assigned only | Read all |
| CRUD leads | ✅ | Assigned only | ❌ |
| CRUD opportunities | ✅ | On assigned leads | ❌ |
| Create tasks | ✅ | On assigned leads | ✅ |
| View tasks | ✅ | Scoped | Read |
| CRUD meetings | ✅ | On assigned leads | ❌ |
| Create notes | ✅ | On assigned leads | ✅ |
| View notes | ✅ | On assigned leads | Read |

**Fail closed:** unknown action → deny (NFR-2).

### Lead scoping rule

Advisor access to child records (Note, Task, Meeting, Opportunity) is allowed when `record.lead.user_id == current_user.id`. Admin bypasses. Assistant read/create rules per matrix above.

### Do NOT

- Do not rename `Authentication` concern — create separate `Authorizable` or use Pundit directly in controllers
- Do not skip `InertiaController` inheritance for future CRM controllers
- Do not implement full admin UI in this story — only policy layer + one denial test route
- Do not add JWT — session cookie auth only

### Files to create

```
app/policies/application_policy.rb
app/policies/lead_policy.rb
app/policies/note_policy.rb
app/policies/task_policy.rb
app/policies/meeting_policy.rb
app/policies/opportunity_policy.rb
app/policies/user_policy.rb
app/controllers/admin/base_controller.rb   # minimal stub for AC-1
test/policies/lead_policy_test.rb
test/policies/note_policy_test.rb
test/controllers/admin_access_test.rb
```

### Files to modify

```
Gemfile
Gemfile.lock
app/controllers/application_controller.rb   # Pundit + rescue_from
app/models/user.rb                          # role helper methods
config/routes.rb                            # admin namespace stub route
test/fixtures/roles.yml                     # assistant role if missing
test/fixtures/users.yml                     # assistant user
```

### Pundit + Inertia pattern

```ruby
# application_controller.rb
include Pundit::Authorization

rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

private

def pundit_user
  current_user
end

def user_not_authorized
  redirect_back fallback_location: root_path, alert: "You are not authorized to perform this action."
end
```

Policy tests use `User` fixtures + `Lead` fixtures — no browser needed for most ACs.

### Previous story intelligence (1.2)

- Session via `session[:user_id]` in `Authentication` concern
- `sign_in_as(user)` in `test/test_helper.rb` for controller tests
- `InertiaController` requires auth on all actions by default
- Login at `/login`, logout `DELETE /logout`
- Shared props: `auth.user.role` already sent to React as string — policies use same `role.name` on server

### Testing standards

- Run `bin/rails test` — full suite must pass
- Policy unit tests: `assert_permit user, record, :action` / `refute_permit` (Pundit test helpers or manual)
- Follow existing fixture naming: `users(:admin)`, `users(:advisor)`, `leads(:...)`

### Project context reference

- [docs/project-context.md](../../../docs/project-context.md) — InertiaController, role names, test patterns
- [docs/IMPLEMENTATION.md](../../../docs/IMPLEMENTATION.md) — auth architecture diagram

---

## References

- [Source: _bmad-output/planning-artifacts/epics.md — Story 1.3]
- [Source: _bmad-output/planning-artifacts/prds/prd-leadflow-crm-2026-07-05/prd.md — FR-3]
- [Source: _bmad-output/planning-artifacts/prds/prd-leadflow-crm-2026-07-05/addendum.md — Authorization Matrix]
- [Source: docs/DATA_MODEL.md#role-permissions]
- [Source: app/controllers/concerns/authentication.rb]
- [Source: app/controllers/inertia_controller.rb]
- [Pundit README](https://github.com/varvet/pundit)

---

## Dev Agent Record

### Agent Model Used

_(filled by dev agent on completion)_

### Debug Log References

### Completion Notes List

### File List
