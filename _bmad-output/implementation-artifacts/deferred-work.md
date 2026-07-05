# Deferred Work

## Deferred from: code review of 1-5-dashboard-with-summary-metrics (2026-07-05)

- No automated perf assertion for 2s dashboard load AC — dev hardware check sufficient for MVP
- `seed_dashboard_sample_data` defined at top level in seeds.rb — standard Rails seed pattern

## Deferred from: code review of 1-4-app-layout-and-role-aware-navigation (2026-07-05)

- Mobile nav overlay does not auto-close on nav link click — UX polish for later
- CRM index controllers have no Pundit authorize yet — Epic 2 CRUD scope

## Deferred from: code review of 1-3-role-based-authorization (2026-07-05)

- Wire `authorize` in all CRUD controllers as Epic 2+ lands — policies exist but only `/admin/users` calls `authorize` today
- Add `after_action :verify_authorized` once resource controllers exist in ApplicationController
