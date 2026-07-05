# Story 1.6: README course compliance

Status: done

## Story

As a **student**,
I want the README to satisfy the Week 1 assignment checklist,
So that my repository passes professor review.

**Epic:** 1 — Access the CRM  
**Week:** 1  
**Fulfills:** Course requirement  
**Depends on:** Stories 1.1–1.5 ✅

---

## Acceptance Criteria

1. **Given** the course specification checklist  
   **When** README is reviewed  
   **Then** it lists 6+ non-CRUD use cases separately from CRUD scope

2. **And** mentions final presentation, Stripe, and background jobs in roadmap

3. **And** model name Task (not FollowUpTask) is consistent with code

---

## Tasks / Subtasks

- [x] **Use case sections** (AC: 1)
  - [x] Separate CRUD vs non-CRUD tables
  - [x] List 7 non-CRUD use cases with status

- [x] **Roadmap** (AC: 2)
  - [x] Week 6: Solid Queue job + Stripe
  - [x] Week 7: final presentation

- [x] **Model naming** (AC: 3)
  - [x] Replace FollowUpTask with Task in models and relationships
  - [x] Add naming note for professor context

- [x] **README polish**
  - [x] Dev login table, current project status, test commands

---

## Dev Notes

### Non-CRUD use cases (7)

Login, authorization, dashboard metrics, search/filter, pipeline transitions, overdue job, Stripe checkout.

### Do NOT

- Do not implement Stripe or jobs in this story — README only

---

## Dev Agent Record

### Agent Model Used

Composer (dev-story)

### Completion Notes List

- README restructured with explicit CRUD vs non-CRUD sections (6 CRUD + 7 non-CRUD)
- Roadmap table references background jobs, Stripe, and final presentation
- Task naming aligned with codebase; FollowUpTask removed

### Review Findings

- [x] [Review][Patch] DATA_MODEL.md still referenced FollowUpTask [docs/DATA_MODEL.md:226] — applied
- [x] [Review][Defer] Pipeline stage transitions listed as non-CRUD — acceptable; emphasizes kanban UX beyond bare CRUD

### File List

- README.md
- docs/DATA_MODEL.md
- docs/IMPLEMENTATION.md
- _bmad-output/implementation-artifacts/sprint-status.yaml
