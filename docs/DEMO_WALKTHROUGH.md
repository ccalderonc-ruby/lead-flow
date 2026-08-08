# LeadFlow — Full demo walkthrough

**Prep (2 min before you start)**
```bash
bin/rails demo:enrich   # if lists look empty
bin/dev                 # http://localhost:3000
```
Password for all users: `password`

| Who | Email | Use for |
|-----|-------|---------|
| **Elena** (Advisor) | `advisor@leadflow.local` | Main story (~70% of demo) |
| **Jordan** (Admin) | `admin@leadflow.local` | Users / roles |
| **Carlos** (Assistant) | `assistant@leadflow.local` | Permissions contrast |

**Good leads to open (after enrich):** Priya Shah, Mateo Jiménez, Daniel Cho

---

## Pick your length

| Time | Do this |
|------|---------|
| **~5 min** | Acts 1–3 only (login → lead note → pipeline) |
| **~10 min** | Acts 1–5 (+ tasks/meetings + roles contrast) |
| **~15–20 min** | Full script below (everything available) |

---

## Act 1 — Login & dashboard (UJ-1) · ~1–2 min

**As Elena** → open `http://localhost:3000` → lands on `/login`

1. Enter wrong password once → show inline error (auth works).
2. Sign in correctly → **Dashboard**.

**Say while pointing at widgets**
- Open leads, overdue tasks, upcoming meetings, pipeline value  
- “Role-scoped metrics — Elena sees her workload.”  
- Sidebar: Dashboard, Leads, Tasks, Meetings, Opportunities (+ Subscription)

**One tech line:** Session cookie auth; protected routes redirect to login.

---

## Act 2 — Leads (UJ-2) · ~2–3 min

1. **Leads** → use search and/or stage filter (e.g. **Qualified**).
2. Open **Priya Shah** or **Mateo Jiménez**.
3. Walk the detail: company, stage, assignee, related tasks / meetings / notes / opportunities.
4. **Add note** → submit → note appears on the timeline (same page).

**Optional if time**
- **Edit lead** → change stage or phone → save → back on detail.  
- **New lead** (nav or CTA) → fill required fields → lands on new detail.

**Say:** CRUD + search/filters; company dedup / unique email under the hood if asked.

---

## Act 3 — Opportunities pipeline (UJ-3) · ~2 min

1. **Opportunities** → kanban columns by stage.
2. Open a card (e.g. Harbor Wealth / CRP Pro).
3. Drawer: change stage to **Proposal** (or move along), adjust value / close date → save.
4. Show flash + board update; optional: back to Dashboard for pipeline $.

**Say:** Opportunities are deals on a lead; stages are separate from lead stages.

---

## Act 4 — Tasks & meetings · ~2–3 min

### Tasks
1. **Tasks** → filters **All / Mine / Overdue**.
2. Point at an overdue row (Mateo / Priya).
3. **Complete** a pending/overdue task from the list or lead detail.
4. Optional: **New task** from lead detail or tasks page.

**Say if asked:** Daily **Solid Queue** job marks past-due pending tasks as `overdue`.

### Meetings
1. **Meetings** → show upcoming list.
2. From lead detail or meetings: **Schedule meeting** (title, date, time, virtual link or location).

---

## Act 5 — Roles & Pundit · ~2–3 min

### Assistant (Carlos)
1. Sign out → login `assistant@leadflow.local`.
2. Open a lead → show they can **add note / task**.
3. Try **Edit lead** (or navigate to edit) → blocked / not authorized.

**Say:** Authorization is **Pundit** on the server — not only hiding buttons.

### Admin (Jordan)
1. Sign out → login `admin@leadflow.local`.
2. **Admin → Users** → list; optional open **New user** (don’t have to save).
3. **Admin → Roles** → show permission matrix / role list.
4. Optional: Leads list shows **all** leads (including admin-owned Nina Alvarez).

---

## Act 6 — SaaS extras · ~2–3 min (skip if short on time)

### Still as Elena (or switch back)
1. **Subscription** (ACCOUNT) → show status; if Stripe keys + `stripe listen` are running, start Checkout (test card). Without Stripe: explain “test Checkout + webhook sets `subscription_status`.”
2. **Leads → Export CSV** → downloads when subscribed (Elena is seeded subscribed after `demo:enrich`).

**Say:** Webhook is source of truth for payment; CSV gated by policy `export?`.

### Background job (talk, don’t need to run live)
- `MarkOverdueTasksJob` via Solid Queue on a daily schedule.

### Deploy (talk only)
- Docker + Kamal scaffold ready; public URL TBD — demo is local.

---

## Act 7 — Close · ~30–60 sec

**Stack one-liner**
> Rails 8 + React via Inertia, PostgreSQL, session auth, Pundit roles, Solid Queue, Stripe, tests and CI.

**Quality (if asked)**
- Model + controller tests, system test login → create lead, GitHub Actions CI.

**AI (if asked)**
> AI sped up implementation; I own the architecture, data model, and role rules — any screen maps to controller → policy → table.

---

## Order at a glance (full ~15–20 min)

```text
1. Elena login + Dashboard
2. Leads search/filter → detail → Add note  (+ edit/create if time)
3. Opportunities board → drawer update
4. Tasks (overdue + complete) + Meetings schedule
5. Carlos: note OK, edit lead denied
6. Jordan: Users + Roles (+ all leads)
7. Elena: Subscription talk/CSV export
8. Close: stack + tests + (optional) AI
```

---

## If something breaks

| Issue | Fix |
|-------|-----|
| Empty lists | `bin/rails demo:enrich` |
| Vite/CSS missing | Confirm `bin/dev` (Rails **3000**, not 3036 alone) |
| CSV blocked | Re-run enrich (sets advisor `subscription_status=active`) or Subscription page |
| Stripe Checkout fails | Skip live pay; explain webhook flow |
| Wrong user still logged in | Sign out from sidebar |

---

## What you are *not* demoing (yet)

Live public URL · Zoom/Meet APIs · invite emails · full task/meeting edit after create · create opportunity from board · dedicated Notes section · advisor↔assistant assignment model  

(Those are on `docs/CRM_ENHANCEMENT_BACKLOG.md`.)
