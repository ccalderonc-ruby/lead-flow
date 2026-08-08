# Enhancement execution plan — start here

**Goal this week:** ship **B2 → B3 → B4** (task edit, meeting edit, create opportunity).  
**Source of truth:** [`CRM_ENHANCEMENT_BACKLOG.md`](./CRM_ENHANCEMENT_BACKLOG.md)  
**Branch base:** always `origin/dev` · one feature branch per item · PR into **`dev`**

---

## Step 0 — Clean the desk (do this first · ~30–60 min)

You currently have **uncommitted local work** on `dev` (demo enrich + docs). Land that before feature work so branches stay clean.

- [ ] Review diff: `demo_seeds.rb`, `demo.rake`, demo docs, backlog docs
- [ ] Commit on a small branch (or directly if you prefer) e.g. `chore/demo-data-and-backlog-docs`
- [ ] PR + merge into `dev`
- [ ] `git checkout dev && git pull origin dev`
- [ ] Confirm app runs: `bin/rails demo:enrich` → `bin/dev` → login as Elena

---

## Week 1 — Feature track (recommended)

### Day 1–2 · B2 — Task edit + revert completed

- [x] Branch: `feature/b2-task-edit-and-revert` from `origin/dev`
- [x] Read current: `TasksController#update`, `TaskPolicy`, `TaskFormModal`, tasks index + lead show complete button
- [x] Widen `update` to allow title, description, due_date, status (not only `completed`)
- [x] Allow revert: `completed` → `pending` / `in_progress` **only** for task owner + Admin (policy)
- [x] UI: Edit task modal (reuse `TaskFormModal` / `FormFields`)
- [ ] Tests: controller + policy (owner can revert, assistant/other cannot)
- [ ] `bin/rails test` green → PR into `dev` → merge

**Done when:** you can open a task, change fields, complete it, and (as owner/admin) un-complete it.

---

### Day 2–3 · B3 — Meeting edit

- [ ] Branch: `feature/b3-meeting-edit` from updated `origin/dev`
- [ ] Copy B2 patterns: `MeetingsController#update`, `MeetingPolicy`, edit modal
- [ ] Editable: title, date, time, location / virtual link, status
- [ ] Same permission idea as tasks (owner + admin for sensitive changes)
- [ ] Tests + PR + merge

**Done when:** scheduled meetings can be updated after create.

---

### Day 3–5 · B4 — Create opportunity

- [ ] Branch: `feature/b4-create-opportunity` from updated `origin/dev`
- [ ] `OpportunitiesController#create` + policy
- [ ] Shared form used from **Opportunities board** and **Lead detail**
- [ ] Same validations / workflow both entry points
- [ ] Tests + PR + merge

**Done when:** you can create a deal from the board and from a lead without duplicating logic.

---

### Day 5–7 · Buffer (pick one if ahead)

Only if B2–B4 are merged:

- [ ] **B5** Notes section, **or**
- [ ] **U1** empty/loading/feedback polish, **or**
- [ ] **U2** forms/filters clarity  
- [ ] Re-run demo walkthrough (`docs/DEMO_WALKTHROUGH.md`)
- [ ] Fix any regressions

**Do not start in week 1:** B7, B1, B6, B8, B9, U3–U6 (unless week 1 finishes early and you explicitly choose one small UX slice).

---

## After week 1 — ordered backlog (don’t start yet)

Work top-down when ready:

| Order | ID | Item |
|------:|----|------|
| 1 | B5 | Dedicated Notes section |
| 2 | B6 | Subscription → Admin (decide org vs per-advisor first) |
| 3 | B7 | Advisor ↔ Assistant assignment (big; plan a full week) |
| 4 | B1 | Dashboards (after B7) |
| 5 | U1 → U2 → U3 | UX polish → Visily pass (need design images) |
| 6 | U4 → U5 → U6 | a11y → mobile → onboarding |
| 7 | B8 | Zoom + Google Meet |
| 8 | B9 | Email invites + email prospects |
| 9 | K2 → K3 → K1 | Kevin leftovers |

---

## How to work each item (repeatable recipe)

1. Pull latest `dev`
2. Create `feature/<id>-<short-name>`
3. Implement smallest vertical slice (controller → policy → UI → test)
4. `bin/rails test` (and `npm run check` if you touched TS heavily)
5. PR into `dev` → merge before starting the next item
6. Check the box above

---

## Start **right now** (next 3 actions)

1. **Commit/merge Step 0** (demo data + backlog docs)  
2. Say **“start B2”** (or start yourself: branch + widen task update)  
3. Keep this file open and check boxes as you go  

When you want agent help on implementation, message: **`dev this: B2 task edit`** (or “implement B2”).
