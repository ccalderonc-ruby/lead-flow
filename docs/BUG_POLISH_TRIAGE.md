# Bug / polish triage

Use this when deciding whether to fix a finding now, before the next epic, or park it.

Goal: avoid a silent pile of “maybe later” items that only get touched at the end of the course.

## Buckets

### 1. Patch now

Fix in the current story / PR when the finding is:

- Wrong vs an acceptance criterion
- Data wipe / incorrect mutation (e.g. partial update clearing fields)
- Auth / authorization hole
- Seed or CI breakage
- Demo-blocking UI that fails the happy path with mouse + normal login

**Owner:** implementer before marking the story `review` / merging.

### 2. Before next epic (prep gate)

Do before starting the next epic’s first story when the finding is:

- Unmerged epic work still only on a feature branch (visibility / baseline risk)
- Missing process artifacts the Project Lead needs (this triage doc, merge to `dev`)
- Anything that blocks the **next** epic’s demo (e.g. admin/role flows for Epic 5)

**Owner:** Project Lead + Amelia; track in sprint `action_items` as `open` until done.

### 3. Park with label

Defer only if **labeled** in story Review Findings **and** `_bmad-output/implementation-artifacts/deferred-work.md`:

- Accessibility polish (Escape / focus trap / restore focus) when mouse demo works
- Performance at demo scale (pagination, per-row policy) unless slow in practice
- Test style (brittle `response.body` substrings)
- Helper duplication / extract refactors
- Copy / humanize / empty-state polish

**Rule:** if you personally hit it in a walkthrough, promote to **Patch now** or **Before next epic** — do not leave it unlabeled.

### 4. Do not

- Accumulate unlabeled “bugs” for end-of-course cleanup
- Treat “Week 7 / Epic 7 polish” as a dumping ground without a deferred-work bullet
- Confuse a11y debt with functional breakage (see below)

## Quick classifier

| Question | If yes → |
|----------|----------|
| Does it violate an AC or corrupt data? | Patch now |
| Does it block the next epic’s demo or leave work invisible on `dev`? | Before next epic |
| Is it polish / a11y / scale / cleanup and labeled? | Park with label |
| Unlabeled “we should maybe…”? | Either patch now or write a deferred-work bullet — never neither |

## Terms

- **a11y debt:** accessibility gaps (e.g. dialogs without Escape / focus management). Often fine for mouse demos; still real debt — park with label, don’t pretend it’s fixed.
- **Deferred work file:** `_bmad-output/implementation-artifacts/deferred-work.md` (force-add when updating tracked copies).

## Related

- Code review workflow: route findings to `patch` / `defer` / `decision_needed` using these buckets
- Story Review Findings: every defer must be checked off as `[Review][Defer]` with a deferred-work entry
