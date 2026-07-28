---
baseline_commit: pending-merge-of-6-3
---

# Story 6.4: Production deployment

Status: ready-for-dev

<!-- Ultimate context engine analysis completed - comprehensive developer guide created -->

## Story

As a **student**,
I want the app deployed to a public URL,
So that I meet the course deployment requirement (FR-17).

**Epic:** 6 — Ship as a SaaS  
**Week:** 6  
**Fulfills:** FR-17  
**Depends on:** Story 6.3 merged to `dev` (CSV export) — **do not start the feature branch until 6.3 is merged**  
**Unblocks:** Epic 6 retrospective (optional); Story 7.3 presentation polish (deploy URL)

---

## Acceptance Criteria

1. **Given** Dockerfile and Kamal config  
   **When** deploy succeeds (to a real host Cheyenne provides **or** an agreed documented alternative)  
   **Then** `GET /up` returns **200** on the production URL

2. **Given** docs  
   **When** done  
   **Then** README documents the **deploy URL** (or explicit TBD + how to finish), setup/Kamal notes, and **demo credentials**  
   **And** `docs/IMPLEMENTATION.md` has **Step 25** for Story 6.4

3. **Given** Epic 5 process  
   **When** shipping  
   **Then** branch `feature/6-4-production-deployment` from **`origin/dev` after 6.3 merges**; one PR into `dev`

---

## Critical decision (do not invent infrastructure)

**Host is TBD** today (`config/deploy.yml` still has placeholder `192.168.0.1`; PRD open question: Kamal host).

Before coding a real deploy, Cheyenne must choose one:

| Option | Meaning |
|--------|---------|
| **A. Real VPS / Fly / Render / etc.** | Provide SSH host or platform target → fill `deploy.yml`, registry, Postgres, secrets → run Kamal → prove `/up` |
| **B. Docs + verified scaffold** | No server yet: prove `docker build` locally, document README options + blockers, mark live URL TBD honestly for the course |

**Do not invent or provision a VPS** the user did not request.

---

## Tasks / Subtasks

- [ ] **Prerequisite**
  - [ ] Commit + PR + merge Story 6.3 into `dev`
  - [ ] Set `baseline_commit` to that merge SHA on `origin/dev`
  - [ ] Branch `feature/6-4-production-deployment` from `origin/dev`
  - [ ] Confirm host decision **A** or **B** with Cheyenne

- [ ] **If Option A — live deploy** (AC: 1–2)
  - [ ] Update `config/deploy.yml`: real `servers.web`, image registry (not `localhost:5555`), proxy/SSL as appropriate
  - [ ] Wire Postgres (Kamal accessory **or** managed `DATABASE_URL` + `LEAD_FLOW_DATABASE_PASSWORD`) — app is **not** SQLite
  - [ ] Kamal secrets: `RAILS_MASTER_KEY` (already), plus Stripe test keys (`STRIPE_*`) and DB password as needed — **never commit raw secrets**
  - [ ] Enable matching Rails production SSL/hosts (`assume_ssl` / `force_ssl` / `config.hosts`) if using HTTPS proxy
  - [ ] Keep `SOLID_QUEUE_IN_PUMA: true` so overdue job can run; ensure multi-DB `db:prepare` succeeds
  - [ ] Deploy; verify `https://<host>/up` → 200; smoke login
  - [ ] Optional but recommended for SM-4: Stripe webhook endpoint → `https://<host>/webhooks/stripe`

- [ ] **If Option B — scaffold + docs** (AC: 1 partial / 2)
  - [ ] Document that live URL is blocked on host TBD
  - [ ] Verify `docker build` (or document exact command + result) for the existing Dockerfile
  - [ ] README: deploy options (Fly / Hetzner / existing VPS), what to fill in `deploy.yml`, env/secrets checklist
  - [ ] Do **not** claim a fake public URL

- [ ] **Docs (both options)** (AC: 2)
  - [ ] README: stack already mentions Kamal — add **Deploy** section (URL or TBD, setup steps, demo personas)
  - [ ] IMPLEMENTATION Step 25; project-context deploy row
  - [ ] Update course deliverables line (CSV done; deploy status honest)

- [ ] **Sprint**
  - [ ] Story → review when green (or when Option B docs verified)

---

## Dev Notes

### MUST follow

1. **Merge 6.3 first** — Epic 5 retro: one branch per story; merge to `dev` before basing the next.
2. **Elevated care on secrets** — never commit `master.key`, Stripe keys, DB passwords. Use `.kamal/secrets` ENV indirection.
3. App DB is **PostgreSQL** multi-DB (primary/cache/queue/cable). Volume in deploy.yml is for Active Storage, not primary DB.
4. Stripe keys needed on prod for UJ-7 demo; test-mode only (no live keys).
5. `/up` already routed to `rails/health#show` — do not reinvent health checks.
6. Do **not** expand into Epic 7 presentation polish (7.3) beyond URL + credentials in README.
7. Frozen string literal on new Ruby; keep Kamal YAML readable.

### Current scaffold (read before editing)

| File | State |
|------|--------|
| `Dockerfile` | Multi-stage production; Thruster `:80`; `db:prepare` |
| `config/deploy.yml` | Placeholder host `192.168.0.1`; registry `localhost:5555`; SSL commented; `SOLID_QUEUE_IN_PUMA` |
| `.kamal/secrets` | `RAILS_MASTER_KEY` only |
| `config/environments/production.rb` | `force_ssl` / `assume_ssl` commented |
| CI | No Docker/Kamal job |

### Previous story intelligence

- 6.1–6.3: branch `feature/6-N-…`, PR into `dev`, code review before done
- 6.2 deferred Kamal Stripe wiring to deploy story — do it here if Option A
- 6.3 must be on `dev` before this branch

### Git / branch

- **Before branch:** merge 6.3 PR into `dev`  
- Branch: `feature/6-4-production-deployment`  
- PR base: **`dev`**

### References

- [epics.md Story 6.4](../../planning-artifacts/epics.md)
- [PRD FR-17](../../planning-artifacts/prds/prd-leadflow-crm-2026-07-05/prd.md)
- [config/deploy.yml](../../../config/deploy.yml)
- [Dockerfile](../../../Dockerfile)
- [Epic 5 retro](../epic-5-retro-2026-07-25.md)

### Verification

```bash
# Option A
curl -fsS https://<production-host>/up
# Option B
docker build -t lead_flow:6.4 .
```

### Out of scope / defer

- Inventing/buying a VPS without Cheyenne’s OK
- Live-mode Stripe
- Full presentation walkthrough docs (7.3)
- docker-compose rewrite unless explicitly chosen

---

## Open questions (blocking for Option A)

1. **Which host?** Fly / Hetzner / existing VPS / other — need IP/DNS + SSH (or platform token).
2. **Postgres where?** Same VPS accessory vs managed Neon/Supabase/etc.
3. **Container registry?** GHCR / Docker Hub / other.

---

## Dev Agent Record

### Agent Model Used

Composer (create-story)

### Debug Log References

### Completion Notes List

### File List

### Change Log

- 2026-07-27: Created Story 6.4 context; status → ready-for-dev; blocked on 6.3 merge + host decision
