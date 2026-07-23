---
baseline_commit: 89c4b0707e8d2205ac64ec27a47ae5c7b93d7cf4
---

# Story 5.1: Demo seed users for role testing

Status: done

<!-- Ultimate context engine analysis completed - comprehensive developer guide created -->

## Story

As a **developer**,
I want advisor and assistant seed users,
So that role-based flows are demoable without manual setup.

**Epic:** 5 — Administer the Team  
**Week:** 5  
**Fulfills:** UJ-4, UJ-5 setup  
**Depends on:** Epic 1 roles/auth ✅, Epic 2 leads ✅  
**Unblocks:** 5.2 Admin user management (demoable roles before CRUD UI)

---

## Acceptance Criteria

1. **Given** I run `bin/rails db:seed` in development  
   **When** seeding completes  
   **Then** users exist for **admin**, **advisor**, and **assistant**  
   **And** each can sign in with password `password`

2. **Given** seeds have run  
   **When** I inspect the advisor user  
   **Then** that advisor has **at least one** assigned lead (`leads.user_id` = advisor)

3. **Given** I sign in as the assistant seed user  
   **When** I open `/leads` (and can open a lead show)  
   **Then** I can view leads (org-scoped read)  
   **And** I cannot create/edit leads (existing `LeadPolicy` — do not invent new permissions in this story)

4. **Given** Epic 4 retro / project docs  
   **When** implementing  
   **Then** treat this as **verify + gap-fill**, not a greenfield seed rewrite  
   **And** document credentials stay aligned across README, `docs/project-context.md`, and `docs/IMPLEMENTATION.md`

---

## Tasks / Subtasks

- [x] **Audit existing seeds** (AC: 1–3)
  - [x] Confirm `db/seeds.rb` creates `admin@leadflow.local`, `advisor@leadflow.local`, `assistant@leadflow.local` with `password` / `status: "active"` / correct `Role`
  - [x] Confirm roles `admin|advisor|assistant` and sample lead assignment path
  - [x] Confirm `LeadPolicy` already grants assistant index/show + Scope.all; create/update false for assistant

- [x] **Gap-fill only** (AC: 1–2)
  - [x] Fix idempotency: `seed_dashboard_sample_data` currently `return if Lead.exists?` — if leads exist but **none** belong to advisor, AC2 fails. Ensure advisor has ≥1 lead after seed (e.g. ensure-path when advisor has zero leads, without wiping existing data)
  - [x] Keep `find_or_create_by!(email:)` for users; do not reset passwords on every re-seed unless deliberately documenting that behavior
  - [x] Do **not** change test fixture emails (`*@example.com`) — fixtures ≠ seeds

- [x] **Docs** (AC: 4)
  - [x] README login table already present — verify accuracy
  - [x] `docs/project-context.md` Dev login table — verify
  - [x] `docs/IMPLEMENTATION.md` — add **Step 18** (Story 5.1): verify command + expected users + “gap-fill only” note; update “NOT implemented” table

- [x] **Tests** (AC: 1–3)
  - [x] Add a focused seeds/integration check (prefer `test/` that loads seeds in isolation or exercises a small `Seeds` helper) proving: three users exist, password authenticates, advisor `leads.exists?`
  - [x] Optional: policy assertion assistant `LeadPolicy#create?` false / `show?` true for any lead — only if cheap; do not expand into Epic 5.2 admin UI tests

- [x] **Sprint**
  - [x] Story → review when done; `5-1-demo-seed-users-for-role-testing` → review; mark Epic 4 action “Create Story 5.1…” done when story file exists (this create-story step)

### Review Findings

- [x] [Review][Patch] Reset demo user password + sync attrs on re-seed [`app/services/demo_seeds.rb:22`] — decided: re-seed restores advertised login (`password`) and syncs name/role/team/country/status; document in IMPLEMENTATION Step 18.
- [x] [Review][Patch] Ensure-lead reclaim only updates `user_id` [`app/services/demo_seeds.rb:133`] — when `demo.advisor.lead@leadflow.local` already exists, also set team/stage/company/country/name to match demo inputs.
- [x] [Review][Defer] `Lead.exists?` skips full dashboard sample [`app/services/demo_seeds.rb:34`] — deferred, pre-existing
- [x] [Review][Defer] Seed path not transactional — deferred, pre-existing
- [x] [Review][Defer] Ensure path mutates TechNova Inc country [`app/services/demo_seeds.rb:122`] — deferred, pre-existing
- [x] [Review][Defer] No partial-seed recovery for missing tasks/meetings/opps — deferred, pre-existing

---

## Dev Notes

### MUST follow

1. **Verify first.** Epic 4 retro: seeds largely exist. Reinventing `db/seeds.rb` from scratch is an anti-pattern.
2. **Development-only sample users** stay behind `if Rails.env.development?` (current pattern). Reference data (countries, roles, stages, team) may remain env-agnostic.
3. **Password:** plain `"password"` via `has_secure_password` on create — matches README.
4. **Emails (canonical):**
   - `admin@leadflow.local`
   - `advisor@leadflow.local`
   - `assistant@leadflow.local`
5. **No admin UI** in this story — that is 5.2 (`/admin/users`).
6. **Triage:** `docs/BUG_POLISH_TRIAGE.md` — seed/CI breakage = patch now.
7. **No FormFields / useDialogA11y needed** unless you add UI (you should not).

### Current seed behavior (read before editing)

| Piece | Location | Notes |
|-------|----------|--------|
| Roles | `db/seeds.rb` | `admin`, `advisor`, `assistant` via `find_or_create_by!` |
| Users | `DemoSeeds.ensure_demo_users!` via `db/seeds.rb` | Only in `development?`; `find_or_create_by!(email:)` |
| Sample leads/tasks/meetings/opps | `DemoSeeds.seed_dashboard_sample_data` | If leads exist, runs `ensure_advisor_assigned_lead!` instead of full skip |
| Docs | README, project-context, IMPLEMENTATION | Login tables + Step 18 |

### Assistant read-only (already implemented)

```ruby
# LeadPolicy — assistant: show?/index? true; create?/update? false; Scope → all
```

Do not weaken advisor scoping or grant assistant write access.

### Anti-patterns (DO NOT)

- Rewrite seeds to use fixture emails (`admin@example.com`)
- Delete/recreate all leads on every seed
- Add Stripe/jobs/admin controllers “while you’re here”
- Change `User` validations unless seed create fails for a documented reason
- Commit `.env` or real secrets

### Suggested verification

```bash
bin/rails db:seed
# Sign in each role at http://localhost:3000/login (password: password)
# Advisor: /leads shows assigned leads
# Assistant: /leads lists leads; New Lead hidden / create denied
bin/rails test   # include new seed test
npm run check    # only if TS touched (unlikely)
```

### Previous intelligence (Epic 4)

- Merge to `dev` before next epic ✅  
- Triage rule ✅  
- Modal a11y ✅ — irrelevant unless UI added  
- Open action: create 5.1 then 5.2  

### Git / branch

- Baseline: `89c4b07` (`origin/dev` after Epic 4 retro merge)  
- Branch: `feature/5-1-demo-seed-users`  
- PR base: **`dev`**

### Project structure (likely touch)

| Path | Action |
|------|--------|
| `db/seeds.rb` | UPDATE — call `DemoSeeds` |
| `app/services/demo_seeds.rb` | NEW — users + sample CRM + advisor ensure |
| `test/services/demo_seeds_test.rb` | NEW — users, password, empty CRM, ensure path |
| `docs/IMPLEMENTATION.md` | UPDATE — Step 18 |
| `docs/project-context.md` | UPDATE — Epic 5 next items in Not done |
| `README.md` | VERIFY only |

### References

- [epics.md Story 5.1](../../planning-artifacts/epics.md)
- [Epic 4 retro](../epic-4-retro-2026-07-21.md)
- [db/seeds.rb](../../../db/seeds.rb)
- [LeadPolicy](../../../app/policies/lead_policy.rb)
- [User model](../../../app/models/user.rb)
- [BUG_POLISH_TRIAGE](../../../docs/BUG_POLISH_TRIAGE.md)
- [project-context Dev login](../../../docs/project-context.md)

---

## Dev Agent Record

### Agent Model Used

Composer (dev-story)

### Debug Log References

### Completion Notes List

- Extracted `DemoSeeds` from inline seed helpers; `db/seeds.rb` stays thin (reference data + development call).
- Fixed AC2 idempotency: when any lead exists but advisor has none, `ensure_advisor_assigned_lead!` creates/reclaims `demo.advisor.lead@leadflow.local` without wiping data.
- Re-seed restores advertised demo logins (password `password` + name/role/team/country/status).
- Ensure-lead reclaim syncs team/stage/company/country/name (not only `user_id`).
- Docs: IMPLEMENTATION Step 18; README + project-context login tables verified; Not-done table lists 5.2–5.4.
- Tests: `DemoSeedsTest` (7) + existing `LeadPolicy` assistant assertions; suite green after review patches.

### File List

- `app/services/demo_seeds.rb` (new)
- `db/seeds.rb`
- `test/services/demo_seeds_test.rb` (new)
- `docs/IMPLEMENTATION.md`
- `docs/project-context.md`
- `_bmad-output/implementation-artifacts/stories/5-1-demo-seed-users-for-role-testing.md`
- `_bmad-output/implementation-artifacts/sprint-status.yaml`

### Change Log

- 2026-07-21: Created comprehensive Story 5.1 context (verify + gap-fill); status → ready-for-dev
- 2026-07-21: Implemented DemoSeeds gap-fill + tests + Step 18; status → review
- 2026-07-21: Code review patches applied (re-seed restores login; ensure-lead reclaim attrs); status → done
