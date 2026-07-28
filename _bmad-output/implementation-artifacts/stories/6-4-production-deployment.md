---
baseline_commit: b051fee75552c69f8c513bfdb7ac3f22245c0fc8
---

# Story 6.4: Production deployment

Status: review

<!-- Ultimate context engine analysis completed - comprehensive developer guide created -->

## Story

As a **student**,
I want the app deployed to a public URL,
So that I meet the course deployment requirement (FR-17).

**Epic:** 6 — Ship as a SaaS  
**Week:** 6  
**Fulfills:** FR-17  
**Depends on:** Story 6.3 merged to `dev` (PR #34 — `b051fee`) ✅  
**Unblocks:** Epic 6 retrospective (optional); Story 7.3 presentation polish (deploy URL)

**Host decision:** **Option B** — docs + verified scaffold command; live URL TBD (no VPS invented).

---

## Acceptance Criteria

1. **Given** Dockerfile and Kamal config  
   **When** deploy succeeds (to a real host Cheyenne provides **or** an agreed documented alternative)  
   **Then** `GET /up` returns **200** on the production URL  
   **Option B note:** Live `/up` deferred until a host exists; README documents the health-check expectation and `docker build` verify command. Docker CLI was **not** available in the agent environment — run `docker build -t lead_flow:6.4 .` locally to confirm.

2. **Given** docs  
   **When** done  
   **Then** README documents the **deploy URL** (explicit TBD + how to finish), setup/Kamal notes, and **demo credentials**  
   **And** `docs/IMPLEMENTATION.md` has **Step 25** for Story 6.4

3. **Given** Epic 5 process  
   **When** shipping  
   **Then** branch `feature/6-4-production-deployment` from **`origin/dev` after 6.3**; one PR into `dev`

---

## Tasks / Subtasks

- [x] **Prerequisite**
  - [x] Commit + PR + merge Story 6.3 into `dev` (PR #34 → `b051fee`)
  - [x] Set `baseline_commit` to that merge SHA
  - [x] Branch `feature/6-4-production-deployment` from `origin/dev`
  - [x] Confirm host decision **B** with Cheyenne

- [x] **Option A — live deploy** — skipped (chose B)

- [x] **Option B — scaffold + docs** (AC: 1 partial / 2)
  - [x] Document live URL blocked on host TBD
  - [x] Document `docker build -t lead_flow:6.4 .` (Docker CLI unavailable in agent env — local verify required)
  - [x] README: deploy options, `deploy.yml` fill list, env/secrets checklist
  - [x] Do not claim a fake public URL

- [x] **Docs** (AC: 2)
  - [x] README Deploy section
  - [x] IMPLEMENTATION Step 25; project-context deploy row
  - [x] Course deliverables line updated honestly
  - [x] Light comments on `config/deploy.yml` placeholders

- [x] **Sprint**
  - [x] Story → review when Option B docs verified

---

## Dev Notes

### Decision

Option **B**: no host provisioned. Scaffold remains; README teaches how to finish when a host exists.

### Agent verify note

`docker` / `podman` / `colima` were not installed in the implementation environment (`command not found: docker`). Acceptance for Option B is documentation of the exact build command plus honest TBD URL — operator should run the build locally before presentation.

### References

- [epics.md Story 6.4](../../planning-artifacts/epics.md)
- [README Deploy](../../../README.md)
- [IMPLEMENTATION Step 25](../../../docs/IMPLEMENTATION.md)

### Verification

```bash
docker build -t lead_flow:6.4 .
# After a real deploy:
# curl -fsS https://<host>/up
```

---

## Dev Agent Record

### Agent Model Used

Composer (dev-story Option B)

### Debug Log References

- `docker build` unavailable in agent shell — documented for local verify

### Completion Notes List

- Option B: README Deploy section, Step 25, project-context, deploy.yml comments
- Public URL explicitly TBD; no invented host
- Baseline `b051fee` (merge PR #34)

### File List

- `README.md`
- `docs/IMPLEMENTATION.md`
- `docs/project-context.md`
- `config/deploy.yml`
- `_bmad-output/implementation-artifacts/sprint-status.yaml`
- `_bmad-output/implementation-artifacts/stories/6-4-production-deployment.md`

### Change Log

- 2026-07-27: Created Story 6.4; status → ready-for-dev
- 2026-07-27: Option B implemented (docs + scaffold); status → review
