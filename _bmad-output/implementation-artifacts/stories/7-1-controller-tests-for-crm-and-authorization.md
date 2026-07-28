---
baseline_commit: ab54064fb3f37a86f066389f3717d506c207721d
---

# Story 7.1: Controller tests for CRM and authorization

Status: done

<!-- Ultimate context engine analysis completed - comprehensive developer guide created -->

## Story

As a **developer**,
I want controller tests for leads CRUD and role denials,
So that CI validates critical paths (FR-18).

**Epic:** 7 — Launch Ready  
**Week:** 7  
**Fulfills:** FR-18, NFR-4  
**Depends on:** Epic 6 on `dev` (PR #35 — `ab54064`) ✅  
**Unblocks:** Story 7.2 system test; 7.3 presentation polish

---

## Acceptance Criteria

1. **Given** the test suite  
   **When** `bin/rails test` runs  
   **Then** tests cover **leads** index / create / update, **task** create, **admin user** create

2. **Given** authorization  
   **When** advisor or assistant attempts forbidden actions  
   **Then** at least one denial test per role (advisor, assistant)  
   **And** denials match app behavior: **redirect + flash** via `user_not_authorized`

3. **Given** docs  
   **When** done  
   **Then** `docs/IMPLEMENTATION.md` has **Step 26** for Story 7.1

4. **Given** process  
   **When** shipping  
   **Then** branch `feature/7-1-controller-tests-for-crm-and-authorization` from `origin/dev`; PR into **`dev`**

---

## Tasks / Subtasks

- [x] **Audit existing coverage** (AC: 1–2)
  - [x] Leads index/create/update covered
  - [x] Task create covered
  - [x] Admin user create + assistant denial covered
  - [x] Advisor/assistant denial tests present (redirect + alert)

- [x] **Fill gaps only** (AC: 1–2)
  - [x] Added `advisor cannot create users` POST denial
  - [x] Did not change denial UX to 403

- [x] **Verify** (AC: 1)
  - [x] `bin/rails test` green (270+ runs)

- [x] **Docs + sprint**
  - [x] IMPLEMENTATION Step 26
  - [x] epic-7 in-progress; 6-4 → done; story → review

### Review Findings

- [x] [Review][Patch] Assert flash on `assistant cannot create users` (mirror advisor create denial) [`test/controllers/admin/users_controller_test.rb:138`]
- [x] [Review][Patch] Assert flash on `advisor cannot list users` [`test/controllers/admin/users_controller_test.rb:18`]
- [x] [Review][Patch] Step 26 admin-users row: credit create denials to `admin/users_controller_test.rb` only; index denials to `admin_access_test.rb` [`docs/IMPLEMENTATION.md:890`]
- [x] [Review][Patch] Relabel unfinished work `26+` → `27+` [`docs/IMPLEMENTATION.md:907`]
- [x] [Review][Patch] Move Story 7.1 controller-tests row out of “Not done” / fix table columns in project-context [`docs/project-context.md:75`]
- [x] [Review][Patch] Step 26 wording: “leads index/create/update” not “CRUD” (no destroy) [`docs/IMPLEMENTATION.md:883`]
- [x] [Review][Defer] Strengthen flash asserts on every CRM denial test (e.g. assistant cannot create/update lead) — deferred, AC2 already satisfied via admin_access + new advisor create test
- [x] [Review][Defer] `redirect_back` vs hardcoded `root_path` assert — deferred, matches fallback when no Referer

---

## Dev Agent Record

### Agent Model Used

Composer (create-story + dev-story)

### Completion Notes List

- AC mostly satisfied by existing Epics 2–6 controller tests
- Gap-fill: advisor POST create-user denial
- Full suite green; denials remain redirect + flash

### File List

- `test/controllers/admin/users_controller_test.rb`
- `docs/IMPLEMENTATION.md`
- `docs/project-context.md`
- `_bmad-output/implementation-artifacts/sprint-status.yaml`
- `_bmad-output/implementation-artifacts/stories/7-1-controller-tests-for-crm-and-authorization.md`
- `_bmad-output/implementation-artifacts/deferred-work.md`

### Change Log

- 2026-07-27: Created Story 7.1; gap-fill + Step 26; status → review
- 2026-07-28: Code review patches applied; status → done
