# Deferred Work

## Deferred from: code review of 1-3-role-based-authorization (2026-07-05)

- Wire `authorize` in all CRUD controllers as Epic 2+ lands — policies exist but only `/admin/users` calls `authorize` today
- Add `after_action :verify_authorized` once resource controllers exist in ApplicationController
