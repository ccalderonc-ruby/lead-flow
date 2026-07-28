---
baseline_commit: a8f3f0e1a2de6a0fe04abbdc7710c125d01a6c51
---

# Story 7.3: Presentation and documentation polish

Status: review

<!-- Ultimate context engine analysis completed - comprehensive developer guide created -->

## Story

As a **student**,
I want final docs and demo script ready,
So that I can present confidently in Week 7.

**Epic:** 7 — Launch Ready  
**Week:** 7  
**Fulfills:** FR-18, course presentation requirement  
**Depends on:** Story 7.2 merged (`a8f3f0e`) ✅  
**Unblocks:** Epic 7 retrospective (optional); course presentation

---

## Acceptance Criteria

1. **Given** `docs/IMPLEMENTATION.md` and `README.md`  
   **When** updated for final state  
   **Then** they document **deploy URL** (honest TBD if no host), **all demo personas**, and **UJ-1 through UJ-3** walkthrough

2. **Given** CI  
   **When** this branch is pushed  
   **Then** CI stays green (docs-only / no regressions)

3. **Given** process  
   **When** shipping  
   **Then** branch `feature/7-3-presentation-and-documentation-polish` from `origin/dev`; PR into **`dev`**

---

## Tasks / Subtasks

- [x] **README polish** (AC: 1)
  - [x] Final project status (Epics 1–7 complete for course scope; live URL TBD)
  - [x] Demo personas table (Admin / Advisor / Assistant)
  - [x] Deploy URL callout (TBD + `/up` expectation)
  - [x] UJ-1 → UJ-3 demo walkthrough (click path for live demo)

- [x] **IMPLEMENTATION polish** (AC: 1)
  - [x] Step 28 for Story 7.3
  - [x] Refresh presentation narrative for full stack (not Week-1-only)
  - [x] Refresh “Sharing with a professor” (branch/PR into `dev`, credentials, port)

- [x] **project-context**
  - [x] Mark presentation polish done; leave live Kamal host optional

- [x] **Sprint**
  - [x] Mark `7-2` done (merged); `7-3` → review when docs done
  - [x] Epic 7 stays in-progress until 7.3 merges

---

## Dev Notes

### MUST follow

1. Do **not** invent a fake public deploy URL — keep **TBD** (Story 6.4 Option B).
2. Demo emails are seed `.local` addresses (`password` for all).
3. Walkthrough must match the **current UI** (Inertia routes, Opportunity drawer stages include **Proposal** in seeds).
4. Docs-only story — no app code changes unless a broken doc reference needs a tiny fix.
5. Integration branch is **`dev`**.

### UJ summary (from PRD)

| Journey | Demo focus |
|---------|------------|
| UJ-1 | Login as Advisor → Dashboard metrics + sidebar |
| UJ-2 | Leads search/filter → detail → add Note |
| UJ-3 | Opportunities board → drawer → stage **Proposal** + value |

### References

- [epics.md Story 7.3](../../planning-artifacts/epics.md)
- [PRD UJ-1–UJ-3](../../planning-artifacts/prds/prd-leadflow-crm-2026-07-05/prd.md)
- [README.md](../../../README.md)
- [IMPLEMENTATION.md](../../../docs/IMPLEMENTATION.md)

---

## Dev Agent Record

### Agent Model Used

Composer (create-story + implement)

### Completion Notes

- README: Presentation demo section with personas + UJ-1–UJ-3; roadmap/status marked complete for course scope.
- IMPLEMENTATION Step 28; refreshed narrative + professor sharing.
- Full suite 271 green (docs-only).

### File List

- `README.md`
- `docs/IMPLEMENTATION.md`
- `docs/project-context.md`
- `_bmad-output/implementation-artifacts/sprint-status.yaml`
- `_bmad-output/implementation-artifacts/stories/7-3-presentation-and-documentation-polish.md`

### Change Log

- 2026-07-28: Created Story 7.3; baseline PR #37 (`a8f3f0e`)
- 2026-07-28: Implemented presentation docs; status → review
