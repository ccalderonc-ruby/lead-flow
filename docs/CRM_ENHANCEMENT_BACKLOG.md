# CRM Enhancement Backlog

Saved: 2026-07-28 · Execution plan: [`ENHANCEMENT_EXECUTION_PLAN.md`](./ENHANCEMENT_EXECUTION_PLAN.md) (start here)  
Status: **prioritized draft** — estimates assume one focused developer familiar with this Rails + Inertia codebase.  
Cursor todos: `bl-1` … `bl-10`, `bl-k1` … `bl-k3`, `bl-u1` … `bl-u6` (session tracker mirrors this list).

---

## How to read estimates

| Label | Rough calendar time | Meaning |
|-------|---------------------|---------|
| **S** | ~0.5–1 day | Mostly UI + controller/policy extension on existing patterns |
| **M** | ~1.5–3 days | New screens + policies + tests |
| **L** | ~3–5 days | Schema/permissions model change + ripple across scopes |
| **XL** | ~1–1.5 weeks | Cross-cutting auth model + dashboards + migrations |

Estimates include tests and a PR into `dev`. They do **not** include a live Kamal deploy.

---

## Suggested priority order

Build **permission foundations** before dashboards that depend on “whose data.” Quick product wins (edit task/meeting, create opportunity) can ship earlier if you want visible progress first.

| Priority | ID | Item | Size | Est. | Depends on |
|----------|----|------|------|------|------------|
| **P0** | B7 | Advisor ↔ Assistant assignment + scoped access | **L–XL** | 4–6 days | — (foundation) |
| **P1** | B2 | Task edit + revert completed | **S–M** | 1–2 days | Soft: clearer owner rules |
| **P1** | B3 | Meeting edit (same model as tasks) | **S–M** | 1–2 days | B2 pattern (reuse) |
| **P1** | B4 | Create opportunity (board + lead detail) | **M** | 1.5–2.5 days | — |
| **P2** | B5 | Dedicated Notes section (synced) | **M** | ✅ shipped | Index + CRUD; lead & opportunity links |
| **P2** | B6 | Subscription → Admin-only | **M** | 1.5–2.5 days | Product decision: org vs per-advisor billing |
| **P3** | B1 | Global + user + admin advisor dashboards | **L** | 3–5 days | B7 for accurate assistant/advisor views |
| **P3** | B8 | Zoom + Google Meet for meetings | **L–XL** | ✅ stub-first | App-level creds; stub generate until VIDEO_CONFERENCE_LIVE |
| **P3** | B9 | Email: user invite + email prospects | **L–XL** | ✅ shipped | Reuses password-reset invite link + app SMTP (`MAIL_FROM`) |
| **P3** | U1 | UX: empty / loading / feedback polish | **S–M** | ✅ shipped | EmptyState + VisitProgress + FlashBanner |
| **P3** | U2 | UX: forms & filters clarity | **S–M** | ✅ shipped | ActiveFilters + LeadForm FormFields + modal validation |
| **P3** | U3 | UX: Visily visual alignment pass | **M–L** | ✅ shipped | Tokens + chrome + page headers (Figma screenshots) |
| **P4** | U4 | UX: accessibility hardening | **M** | 1.5–3 days | New modals must keep `useDialogA11y` |
| **P4** | U5 | UX: responsive / mobile pass | **M** | 2–3 days | — |
| **P4** | U6 | UX: onboarding / first-run guidance | **M** | 1.5–3 days | — |
| **P4** | K2 | Extract lead-show prop types to shared types file | **S** | 0.5 day | — (Kevin PR #20) |
| **P4** | K3 | Extract list tables into shared table components | **S–M** | 0.5–1.5 days | — (Kevin PR #20); helps U2 |
| **P4** | K1 | Counter cache for lead-detail related counts | **S** | 0.5–1 day | Only if lists feel slow (Kevin PR #20) |

**Fast path (demo polish, ~1 week):** B2 → B3 → B4  
**Correct long-term path:** B7 first, then B1 / B6, with B2–B5 in parallel where possible  
**Integrations track:** B8 + B9 after core CRM edit flows are solid  
**UX/UI track:** U1 → U2 first (high impact, low risk); U3–U6 after features stabilize  
**Kevin leftovers (polish):** K2 → K3; K1 only if needed for performance

---

## Current baseline (what exists today)

| Area | Today |
|------|--------|
| Dashboard | Single role-scoped metrics page (`DashboardController`) — not “pick an advisor,” no admin toggle |
| Tasks | Create + complete + **edit/reopen** (B2 on `feature/b2-task-edit-and-revert`) |
| Meetings | Index + create only — **no update route** |
| Opportunities | Index + update drawer — **no create** |
| Notes | Dedicated `/notes` index + create/edit/delete; also on lead detail & opportunity drawer (same records) |
| Subscription | Advisor settings (`/settings/subscription`) + Stripe webhook |
| Assistant access | Broad assistant lead visibility via policies — **no advisor↔assistant assignment table** |
| Video meetings | Manual `virtual_link` / location fields only — **no Zoom or Google Meet API** |
| Email | **None** — no invite mail on user create; no outbound mail to leads/prospects |
| UX / UI | Visily/Figma alignment pass shipped (U3); further a11y / mobile / onboarding still open |

---

## Backlog items

### B1 — Dashboard improvements · `bl-1` · **L · 3–5 days** · P3

**Want**
- Global dashboard vs user-specific dashboard
- User metrics = only that user’s assigned leads/opportunities
- Recalc when ownership changes (should be query-time, not cached stale counts)
- User dashboard private to that user
- Admin: toggle + dropdown to view any advisor’s dashboard

**Notes / design**
- Prefer **live queries** on each request (reassignment “auto-updates” for free)
- Admin “view as advisor” = pass `advisor_id` + authorize `DashboardPolicy`
- Toggle preference: `admin` setting or `session`/user preference column

**Risks:** Confusing “global” definition (org-wide vs admin-only). Clarify before build.

---

### B2 — Task management · `bl-2` · **S–M · 1–2 days** · P1

**Want**
- Full edit after create (title, description, due date, status, etc.)
- Revert **Completed** → pending/in_progress
- Only **task owner** + **Admin** may revert

**Today:** complete-only update path  
**Work:** widen `TasksController#update`, policy methods, edit modal/UI, tests

---

### B3 — Meeting management · `bl-3` · **S–M · 1–2 days** · P1

**Want**
- Same edit capabilities as tasks
- Same permission model (owner + admin for sensitive transitions)

**Today:** create-only  
**Work:** `update` route, policy, edit UI (mirror task modal), tests  
**Faster if B2 lands first** (copy patterns)

---

### B4 — Opportunity create · `bl-4` · **M · 1.5–2.5 days** · P1

**Want**
- Create from **Opportunities** board
- Create from **Lead detail**
- Same object / same workflow both places

**Today:** update drawer only  
**Work:** `OpportunitiesController#create`, shared form component, authorize, tests

---

### B5 — Shared Notes section · `bl-5` · **M · 2–3 days** · P2 · ✅ shipped

**Want**
- Dedicated **Notes** nav/section
- Always linked to a lead
- Create/edit/delete from Notes **or** lead detail → same records everywhere

**Shipped**
- Nav item + `/notes` index (paginated), create/update/destroy via `NotesController`
- Notes link to a **lead** or an **opportunity** (opportunity notes still resolve a lead via `linked_lead`)
- Same records on lead detail timeline and opportunity drawer; shared `NoteFormModal` + policies
- Email-sent notes (`source: email`) are not editable or deletable

---

### B6 — Subscription → Admin · `bl-6` · **M · 1.5–2.5 days** · P2

**Want**
- Subscription managed only in **Admin**
- Advisors cannot open subscription management

**Decide first**
- **Org subscription** (one Stripe customer for the team), or  
- **Admin manages each advisor’s** `subscription_status` / Checkout on their behalf?

**Work:** move UI under `/admin/...`, strip advisor nav/CTA, update `SubscriptionPolicy`, webhook still updates the right `User` (or a new `Organization` model if org-level)

**Risks:** Stripe customer identity changes if you move from per-advisor to org billing — largest unknown in this item.

---

### B7 — Roles & permissions (assignment model) · `bl-7` · **L–XL · 4–6 days** · P0

**Want**
- **Admin:** org subscription, all CRUD, all advisor dashboards, overrides
- **Advisor:** own/assigned records; assign Assistants; control assistant access to their records
- **Assistant:** only data for Advisor(s) they are assigned to (inherited scope)
- **Tasks (follow-on in this PR):** Advisors/Assistants only see tasks for their leads and/or tasks assigned to them; remove the **Mine** filter for those roles (redundant once the default list is already scoped). Admin may keep org-wide + Mine.

**Today:** role flags + Pundit scopes; assistants are not tied to specific advisors; Assistants currently see all org tasks

**Work (typical)**
1. Join table e.g. `advisor_assistants` (advisor_id, assistant_id)
2. Advisor UI to add/remove assistants
3. Rewrite `policy_scope` for Lead/Task/Meeting/Note/Opportunity
4. Tasks index: hide **Mine** for Advisor/Assistant once scopes are assignee/lead-limited
5. Tests for every role path  
6. Seed/demo data for Elena ↔ Carlos

**This is the largest structural change** and unlocks correct dashboards (B1) and truthful assistant demos.

---

### B8 — Zoom + Google Meet for meetings · `bl-8` · **L–XL · 4–8 days** · P3 · ✅ stub-first shipped

**Want**
- Integrate **Zoom** and **Google Meet** with LeadFlow meetings
- When scheduling (or editing) a virtual meeting, create/link a real conference and store the join URL on the meeting
- Prefer one clear UX: pick provider → generate link (or connect account once via OAuth)

**Shipped (v1 stub-first, app-level)**
- `video_provider` + `external_meeting_id` on meetings
- Meeting form: provider select + Generate conference link (Zoom / Google Meet)
- `Meetings::ConferenceLinkGenerator` + stub clients when `VIDEO_CONFERENCE_LIVE` is off (default)
- Manual virtual link still works with provider “None”

**Follow-up:** wire live Zoom Server-to-Server + Google Calendar Meet when prod app credentials exist (`VIDEO_CONFERENCE_LIVE=true`).

**Out of scope still:** per-advisor OAuth, remote sync on edit/cancel

---

### B9 — Email: account invites + email prospects · `bl-9` · **L–XL · 4–7 days** · P3 · ✅ shipped

**Want**
1. **User invite on create** — when Admin creates a user, send an email to set up / activate the account (password reset or invite token link), instead of only handing them a shared demo password  
2. **Email prospects** — send email to a lead/prospect from LeadFlow (at least from lead detail; optionally a simple compose UI)

**Shipped (v1)**
- Invite: optional “Send invite email” on admin user create; random password if blank; reuses password-reset token URL; Resend invite on edit
- Prospect email: compose modal on lead show; sends via app `MAIL_FROM` + SMTP; logs sent copy as a Note; same visibility as notes (`LeadPolicy#email?`)
- Not in v1: Gmail OAuth send-as, dedicated `emails` table, unsubscribe flows

---

## UX / UI enhancements

Umbrella for presentation and usability work (not new CRM entities).  
Reference: Visily export (project-context); park rules in `docs/BUG_POLISH_TRIAGE.md`.  
Add screen-specific notes under each item as you decide them.

### U1 — Empty, loading, and feedback polish · `bl-u1` · **S–M · 1–2 days** · P3 · ✅ shipped

**Want**
- Clear empty states on lists (leads, tasks, meetings, opportunities, notes) with a primary CTA
- Loading / pending UI on slow Inertia visits and form submits (disable + spinner where helpful)
- Consistent flash / inline error presentation across pages

**Shipped**
- Shared `EmptyState`, `FlashBanner`, and `VisitProgress` on CRM lists
- Opportunities board empty + assistants / admin users / subscriptions empty CTAs
- Form `processing` labels already cover submit pending states

---

### U2 — Forms & filters UX · `bl-u2` · **S–M · 1–2 days** · P3 · ✅ shipped

**Want**
- Clearer required-field / validation messaging (Inertia errors)
- Filter/search UX: obvious active filters, easy reset, sticky filter bar where useful
- Align modal forms on shared `FormFields` patterns (already started)

**Shipped**
- Shared `ActiveFilters` on leads, tasks, and opportunities
- Sticky task filter bar; owner clear chip on opportunities even with results
- `LeadForm` migrated to FormFields; shared `FormErrorBanner` + `RequiredFieldsHint` on CRM modals

---

### U3 — Visily visual alignment pass · `bl-u3` · **M–L** · ✅ shipped · P3

**Shipped**
- Brand tokens (orange `#f08c2d`, navy, sidebar `#1a1648`, surface canvas) in `application.css`
- Sidebar chrome: LeadFlow / CRM Premium mark, muted active pill + orange dot, avatar initials
- Shared `PageHeader`, `Button` navy variant, `StageBadge` on leads
- Page headers/CTAs aligned on dashboard, leads, tasks, meetings, opportunities, notes, assistants, admin
- Opportunity board column/card polish; dashboard org/advisor switcher uses navy (CTAs stay orange)
- Out of scope for v1: calendar meetings UI, Forecast/Table views, new Figma-only entities

---

### U4 — Accessibility hardening · `bl-u4` · **M · 1.5–3 days** · P4

**Want**
- Keyboard path for all modals/drawers (Escape, focus trap, return focus) — extend `useDialogA11y` everywhere
- Focus-visible styles; label associations; contrast check on primary UI
- Meaningful page titles / headings per route

**Today:** most CRM dialogs use `useDialogA11y`; remaining gaps are parkable a11y debt per triage doc

---

### U5 — Responsive / mobile pass · `bl-u5` · **M · 2–3 days** · P4

**Want**
- Usable layout on phone/tablet: sidebar collapse, tables that scroll or stack, modals that fit small screens
- Touch-friendly controls on pipeline board and filters

**Today:** desktop-first; not a hard course requirement unless you demo on mobile

---

### U6 — Onboarding / first-run guidance · `bl-u6` · **M · 1.5–3 days** · P4

**Want**
- First login empty-state guidance (“Create your first lead”)
- Optional short checklist or coach marks for Advisor vs Admin
- Soften cold-start before `demo:enrich`-style data exists

**Note:** less critical while seed/demo data is rich; more valuable for real new users (ties to B9 invites)

---

## Kevin follow-ups (PR #20 — Epic 3)

Source: [PR #20 review](https://github.com/ccalderonc-ruby/lead-flow/pull/20) by `kevinjg03`.  
Most comments were handled in `d247ce1` (Task enum, `FormFields`, `lib/format`, drop form `useEffect`s). These three remain as polish.

### K1 — Counter cache for lead-detail counts · `bl-k1` · **S · 0.5–1 day** · P4

**Want**
- Precomputed counts for related records on lead show (tasks / notes / meetings / opportunities) instead of `COUNT(*)` on every load

**Kevin’s framing:** optional — “si se fueran a usar mucho”  
**Today:** `lead.tasks.count` (and similar) in `LeadsController` show props  
**When to do:** only if lead detail feels slow at real data volume  
**Work:** migrations + `counter_cache: true` (or custom counters for filtered counts) + backfill

---

### K2 — Extract lead-show types · `bl-k2` · **S · ~0.5 day** · P4

**Want**
- Move the many inline TypeScript types from `app/javascript/pages/leads/show.tsx` into a shared types/schema module and import them

**Today:** `LeadDetail`, `TaskPreview`, `MeetingPreview`, etc. still declared in the page file  
**Work:** e.g. `app/javascript/types/leads.ts` (or extend `types/index.ts`) + update imports; no behavior change

---

### K3 — Shared table components · `bl-k3` · **S–M · 0.5–1.5 days** · P4

**Want**
- Extract list tables (leads / tasks / meetings, etc.) into reusable components for consistency and cleaner pages

**Today:** each index page owns its own table markup  
**Work:** shared table shell + column slots; migrate 1–2 pages first, then the rest  
**Note:** Notes index already shipped (B5)

---

## Rough totals

| Path | Items | Calendar |
|------|-------|----------|
| Quick wins only | B2 + B3 + B4 | ~4–6 days |
| Full product backlog | B1–B7 | ~2.5–4 weeks |
| Foundation-first full | B7 then rest | ~3–4.5 weeks |
| Integrations | B8 + B9 | ~1.5–3 weeks (API/OAuth heavy) |
| UX / UI track | U1–U6 | ~1.5–3 weeks (can slice) |
| Kevin polish only | K1 + K2 + K3 | ~1.5–3 days |
| Everything | B1–B9 + U1–U6 + K1–K3 | ~7–11 weeks |

---

## Next step (when you’re ready)

1. Confirm **P0 = B7** vs **quick wins first (B2–B4)**  
2. For **B6**, choose org vs per-advisor billing  
3. For **B1**, define what “global dashboard” means (admin org-wide vs everyone’s personal home)  
4. Kevin leftovers (**K2/K3**) are safe anytime; **K1** only if performance matters  
5. For **B8**, choose app-wide vs per-user Zoom/Google OAuth  
6. For **B9**, choose mail provider + invite style; clarify if prospect mail is CRM-API send or Gmail  
7. For **UX**, pick a slice (recommend **U1 + U2** before a full Visily redraw)

Say which track you want and we can turn the top items into BMad stories / sprint entries.  
If you have specific screens/flows for UX (e.g. “pipeline drag feels wrong”), add them under U1–U6 and we’ll refine estimates.
