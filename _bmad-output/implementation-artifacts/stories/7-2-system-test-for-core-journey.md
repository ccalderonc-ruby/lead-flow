---
baseline_commit: 24e74c924ae4055d283b3bd748bcf9960b5564a9
---

# Story 7.2: System test for core journey

Status: review

<!-- Ultimate context engine analysis completed - comprehensive developer guide created -->

## Story

As a **developer**,
I want a system test for login → create lead,
So that the end-to-end stack is verified.

**Epic:** 7 — Launch Ready  
**Week:** 7  
**Fulfills:** FR-18 (optional but recommended)  
**Depends on:** Story 7.1 merged (`24e74c9`) ✅  
**Unblocks:** Story 7.3 presentation polish

---

## Acceptance Criteria

1. **Given** a Capybara system test  
   **When** it logs in, navigates to new lead, and submits the form  
   **Then** the lead appears on the index **or** detail page

2. **Given** docs  
   **When** done  
   **Then** `docs/IMPLEMENTATION.md` has **Step 27** for Story 7.2

3. **Given** process  
   **When** shipping  
   **Then** branch `feature/7-2-system-test-for-core-journey` from `origin/dev`; PR into **`dev`**

---

## Tasks / Subtasks

- [x] **System test** (AC: 1)
  - [x] Add `test/system/login_create_lead_test.rb`
  - [x] Login via UI (`/login`, fixture advisor, password `password`) — do **not** use `sign_in_as`
  - [x] Visit `/leads/new`, fill required fields, submit
  - [x] Assert lead on detail (preferred: create redirects to show) or index
  - [x] Harden `ApplicationSystemTestCase` if needed (`Capybara.server_host = "localhost"` for Vite host redirect)

- [x] **Verify** (AC: 1)
  - [x] `RAILS_ENV=test bin/vite build --force` then `bin/rails test test/system/login_create_lead_test.rb`
  - [x] Full `bin/rails test` still green

- [x] **Docs + sprint**
  - [x] IMPLEMENTATION Step 27
  - [x] Story → review; sprint `7-2` → review

---

## Dev Notes

### MUST follow

1. Driver: Selenium headless Chrome (already in `ApplicationSystemTestCase`).
2. Use **fixtures** (`advisor@example.com` / `password`), not seed `.local` emails.
3. Advisor path: no assignee select (`force_assignee`).
4. Build Vite for test before running system tests (CI already does).
5. Wait on Inertia with `assert_text` / path assertions — not integration-style `assert_redirected_to` alone.
6. Unique email for the new lead (avoid fixture collisions).

### Selectors (current UI)

- Login: `fill_in "email"`, `fill_in "password"`, `click_button "Sign in"`
- Lead form ids: `name`, `email`, `company_name`, `company_country_id`, `country_id`, `stage_id`
- Submit: `Create lead`
- Success: flash `Lead created.` + show page name
- React controlled selects: use native value setter + `change` event (see `select_react` in the system test)

### References

- [epics.md Story 7.2](../../planning-artifacts/epics.md)
- [application_system_test_case.rb](../../../test/application_system_test_case.rb)
- [LeadForm.tsx](../../../app/javascript/components/leads/LeadForm.tsx)
- [CI system-test job](../../../.github/workflows/ci.yml)

---

## Dev Agent Record

### Agent Model Used

Composer (create-story + implement)

### Debug Log

- Capybara `select` left React-controlled `<select>` values empty → HTML5 `required` blocked submit (no POST). Fixed with `select_react` helper (native value setter + `change`).

### Completion Notes

- System test green; full suite 271 runs, 0 failures.
- IMPLEMENTATION Step 27 added; project-context updated.

### Change Log

- 2026-07-28: Created Story 7.2; baseline PR #36
- 2026-07-28: Implemented system test + Step 27; status → review
