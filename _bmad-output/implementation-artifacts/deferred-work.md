# Deferred Work

## Deferred from: code review of 5-1-demo-seed-users-for-role-testing.md (2026-07-21)

- `Lead.exists?` skips full dashboard sample (tasks/meetings/opportunities) when any lead already exists — only advisor-lead ensure runs; accepted gap-fill pattern for Story 5.1.
- Seed path is not transactional — mid-failure can leave partial sample CRM and permanently skip the rest on re-seed.
- `ensure_advisor_assigned_lead!` mutates shared “TechNova Inc” company country to US when ensuring the advisor lead (same pattern as full sample seed).
- No recovery when some sample records exist but related task/meeting/opportunity rows are missing.

## Deferred from: code review of 5-2-admin-user-management.md (2026-07-21)

- No DB check constraint / enum on `users.status` — model validates `active|disabled` only; direct SQL can still insert arbitrary values.
- `users.email` unique index is case-sensitive while the app normalizes email on validation — same class of issue as leads (which use `lower(email)` unique index).

## Deferred from: code review of 5-3-role-management-page.md (2026-07-22)

- Static `Admin::RolePermissions::MATRIX` strings can drift from Pundit policies over time — accepted for Story 5.3 read-only MVP (no DB-backed permissions).
- Deeper Inertia prop parsing / full-cell matrix assertions beyond substring checks — residual coverage.

## Deferred from: code review of 5-4-advanced-lead-filters.md (2026-07-25)

- No frontend/Inertia unit tests for lead filter query preservation — residual; repo relies on controller/integration tests.
- Full stages + assignable users serialized on every leads index request — acceptable at course scale.

## Deferred from: code review of 6-1-mark-overdue-tasks-job.md (2026-07-25)

- Daily Solid Queue schedule has no explicit timezone while overdue uses `Date.current` — set `config.time_zone` + scheduler TZ when tightening production behavior.
- Nil `Task.status` is allowed by enum but excluded from job (`pending` only) and from overdue scope SQL (`NULL` not `completed`) — normalize or include if legacy nil rows appear.
