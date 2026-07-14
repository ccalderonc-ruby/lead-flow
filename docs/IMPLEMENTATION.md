# LeadFlow — Local Implementation Guide

This document describes all code implemented locally on the `cursor/implement-models` branch. Use it to explain the work to a professor, teammate, or reviewer.

**Design reference:** [DATA_MODEL.md](./DATA_MODEL.md)  
**Branch:** `cursor/implement-models` (local work; not all changes are pushed yet)

---

## Overview

Work was done in three steps:

| Step | Goal | Status |
|------|------|--------|
| **1** | Database schema, Active Record models, seed data | Done (committed) |
| **2** | Automated model tests + test fixtures | Done (local, uncommitted) |
| **3** | Session-based login/logout with Inertia + React | Done (local, uncommitted) |

**Test suite:** 46 tests, 129 assertions, all passing.

---

## Step 1 — Database, Models, and Seeds

### What we did

Translated the Tier 1 + Tier 2 data model from `docs/DATA_MODEL.md` into a working PostgreSQL schema with Rails migrations, Active Record models, associations, validations, and development seed data.

### 1.1 Enable password hashing

**File:** `Gemfile`

Uncommented the `bcrypt` gem so `User` can use `has_secure_password` (stores a hashed `password_digest`, never plain text).

### 1.2 Database migrations (15 tables)

**Directory:** `db/migrate/`

Migrations were generated in dependency order and run with `bin/rails db:migrate`. The final schema is in `db/schema.rb` (version `20260624023634`).

| Migration | Table | Purpose |
|-----------|-------|---------|
| `create_countries` | `countries` | ISO country list for dropdowns and reporting |
| `create_roles` | `roles` | admin / advisor / assistant |
| `create_lead_stages` | `lead_stages` | Lead pipeline columns (Prospect, Qualified, …) |
| `create_opportunity_stages` | `opportunity_stages` | Deal pipeline columns (Prospect, Won, Lost, …) |
| `create_teams` | `teams` | Sales teams |
| `create_companies` | `companies` | Company records with dedup via `normalized_name` |
| `create_users` | `users` | Authenticated users (`password_digest`, role, team, country) |
| `create_leads` | `leads` | Core CRM entity |
| `create_opportunities` | `opportunities` | Sales deals linked to leads |
| `create_tasks` | `tasks` | Follow-up tasks |
| `create_meetings` | `meetings` | Scheduled meetings |
| `create_notes` | `notes` | Notes on leads |
| `create_tags` | `tags` | Labels for leads and notes |
| `create_lead_tags` | `lead_tags` | Join: leads ↔ tags |
| `create_note_tags` | `note_tags` | Join: notes ↔ tags |

**Important fix during migration:**  
Rails’ `t.references :stage` defaults to a table named `stages`, which does not exist. We use separate stage tables, so foreign keys were pointed explicitly:

```ruby
# leads migration
t.references :stage, null: false, foreign_key: { to_table: :lead_stages }

# opportunities migration
t.references :stage, null: false, foreign_key: { to_table: :opportunity_stages }
```

Without this, PostgreSQL raised: `relation "stages" does not exist`.

### 1.3 Active Record models

**Directory:** `app/models/`

Each model defines `belongs_to` / `has_many` associations, plus validations where the data model requires them.

| Model | Key associations | Key validations / behavior |
|-------|------------------|----------------------------|
| `Country` | has many companies, leads, users | name + iso_code present, unique; iso_code length = 2 |
| `Role` | has many users | name present, unique |
| `Team` | has many users, leads | name present, unique |
| `Company` | belongs_to country; has many leads | name present; **normalizes name** for dedup (see below) |
| `User` | belongs_to role, team, country | name + email present, unique email; `has_secure_password` |
| `LeadStage` | has many leads | name + position present, unique |
| `OpportunityStage` | has many opportunities | name + position present, unique |
| `Lead` | belongs_to stage (LeadStage), user, company, country; optional team | name, country, company required |
| `Opportunity` | belongs_to stage (OpportunityStage), lead, user | value > 0 when present |
| `Task` | belongs_to lead, user | due_date required |
| `Meeting` | belongs_to lead, user | (no validations yet) |
| `Note` | belongs_to lead, user; has tags through note_tags | content required |
| `Tag` | has many leads/notes through join tables | name present, unique |
| `LeadTag` | belongs_to lead, tag | join table only |
| `NoteTag` | belongs_to note, tag | join table only |

**Company normalization** (`app/models/company.rb`) — business logic for deduplication:

- Strips punctuation and legal suffixes (Inc, LLC, Corp, etc.)
- Lowercases and squashes whitespace
- Stores result in `normalized_name` (unique index)
- Class method `Company.find_or_initialize_by_name("Acme Corp.")` finds `"acme"` or builds a new record

Example verified in the Rails console:

```ruby
Company.normalize_name("TechNova Solutions, LLC")  # => "technova solutions"
```

### 1.4 Seed data

**File:** `db/seeds.rb`

Run with `bin/rails db:seed`. Idempotent (`find_or_create_by!`).

Seeds create:

- 5 countries (US, CA, CR, MX, GB)
- 3 roles (admin, advisor, assistant)
- 5 lead stages + 6 opportunity stages
- 1 team (“Enterprise Sales”)
- **Development only:** dev users (password `password` for all)
  - Admin: `admin@leadflow.local`
  - Advisor: `advisor@leadflow.local`
  - Assistant: `assistant@leadflow.local`

### 1.5 How to verify Step 1

```bash
bin/rails db:migrate
bin/rails db:seed
bin/rails console
```

```ruby
User.find_by(email: "admin@leadflow.local").authenticate("password")  # => user object
LeadStage.count    # => 5
Country.pluck(:iso_code)  # => ["US", "CA", "CR", "MX", "GB"]
```

---

## Step 2 — Model Tests and Fixtures

### What we did

Added automated tests for every model and fixed test fixtures so they load without violating uniqueness constraints.

### 2.1 Test fixtures

**Directory:** `test/fixtures/`

Rails loads these into the **test database** before each test (`fixtures :all` in `test/test_helper.rb`). They are **not** used when running the app in development.

Replaced auto-generated `MyString` placeholders with realistic, unique data:

- `countries.yml` — US, Costa Rica
- `roles.yml` — admin, advisor
- `users.yml` — admin + advisor with BCrypt password `"password"`
- `companies.yml`, `leads.yml`, `tasks.yml`, etc. — linked consistently

**Fixture access in tests:** `users(:admin)` loads the `admin` key from `users.yml`.

### 2.2 Model tests

**Directory:** `test/models/`

| Test file | What it covers |
|-----------|----------------|
| `country_test.rb` | presence, iso_code length (2), uniqueness |
| `company_test.rb` | normalization, `find_or_initialize_by_name`, uniqueness |
| `lead_test.rb` | required fields, associations |
| `user_test.rb` | presence, unique email, password auth |
| `task_test.rb` | due_date required |
| `note_test.rb` | content required, tag association |
| `opportunity_test.rb` | value must be > 0; nil allowed |
| `role_test.rb`, `team_test.rb`, `tag_test.rb` | uniqueness |
| `lead_stage_test.rb`, `opportunity_stage_test.rb` | unique name + position |
| `meeting_test.rb`, `lead_tag_test.rb`, `note_tag_test.rb` | fixture + association smoke tests |

**40 model tests** total.

### 2.3 How to run Step 2 tests

```bash
bin/rails test test/models/
# or full suite:
bin/rails test
```

These run in the terminal — not in the browser and not in `bin/rails console`.

---

## Step 3 — Authentication (Login / Logout)

### What we did

Implemented session-based authentication: unauthenticated users are redirected to a login page; successful login sets a server-side session cookie; logout clears it. The login UI is a React page rendered via Inertia.js.

### 3.1 Architecture

```
Browser                    Rails                         React (Inertia)
   |                         |                                |
   |-- GET /login ---------->| SessionsController#new         |
   |<-- Inertia page --------| render "sessions/new" -------->| Login form
   |                         |                                |
   |-- POST /session ------->| SessionsController#create      |
   |   email + password      | find user, verify password     |
   |                         | session[:user_id] = user.id     |
   |<-- redirect to / -------|                                |
   |                         |                                |
   |-- GET / --------------->| InertiaExampleController       |
   |   (cookie sent)         | current_user from session      |
   |<-- home page -----------| shared auth props ------------->| Shows user + Sign out
```

**Session storage:** Rails cookie session (`session[:user_id]`). No JWT, no separate Session model.

### 3.2 Backend files

#### `app/controllers/concerns/authentication.rb`

Reusable authentication logic included in `ApplicationController`:

| Method | Purpose |
|--------|---------|
| `current_user` | Loads `User` from `session[:user_id]` |
| `authenticated?` | Returns true if `current_user` exists |
| `authenticate_user!` | Redirects to `/login` if not signed in |
| `start_new_session_for(user)` | Resets session, sets user id, updates `last_login_at` |
| `terminate_session` | Clears session on logout |
| `require_authentication` | Class macro: add `before_action :authenticate_user!` |
| `allow_unauthenticated_access` | Class macro: skip auth for specific actions |

#### `app/controllers/application_controller.rb`

```ruby
include Authentication
```

Makes auth helpers available to all controllers.

#### `app/controllers/inertia_controller.rb`

Base class for Inertia pages:

- `require_authentication` — all Inertia pages require login by default
- `inertia_share auth:` — sends `{ user: { id, name, email, role } }` to every React page
- `inertia_share flash:` — sends notice/alert messages to React

#### `app/controllers/sessions_controller.rb`

| Action | Route | Behavior |
|--------|-------|----------|
| `new` | `GET /login` | Shows login form; redirects to `/` if already signed in |
| `create` | `POST /session` | Validates email/password; sets session or returns error |
| `destroy` | `DELETE /logout` | Clears session; redirects to login |

Login and create actions skip authentication (`allow_unauthenticated_access`).

Email is normalized (strip + downcase) before lookup.

#### `config/routes.rb`

```ruby
resource :session, only: %i[new create destroy]
get "login", to: "sessions#new", as: :login
delete "logout", to: "sessions#destroy", as: :logout

root "dashboard#index"   # requires authentication; metrics in Story 1.5
```

### 3.3 Frontend files

#### `app/javascript/pages/sessions/new.tsx`

Login page built with:

- `@inertiajs/react` `useForm` — posts email/password to `POST /session`
- Tailwind CSS — centered card layout
- Displays validation errors from server

#### Dashboard (Story 1.5)

Root `/` renders `dashboard/index.tsx` with role-scoped metric widgets (open leads, overdue tasks, upcoming meetings, pipeline value). The Inertia example page was removed in Story 1.5.

#### `app/javascript/types/index.ts`

TypeScript types for shared props:

```typescript
auth: { user: AuthUser | null }
flash: { notice?: string; alert?: string }
```

### 3.4 Dev ergonomics

#### `bin/dev`

Prints a reminder on startup:

```
LeadFlow app:  http://localhost:3000/login
(Port 3036 is Vite assets only — do not open it in the browser)
```

**Important:** `bin/dev` starts two processes:

| Process | Default port | Role |
|---------|--------------|------|
| Rails (`web`) | 3000 | The app — open this in the browser |
| Vite (`vite`) | 3036 | JS/CSS assets only — do not browse this URL |

### 3.5 Session tests

**File:** `test/controllers/sessions_controller_test.rb`

| Test | Verifies |
|------|----------|
| Login page reachable when signed out | `GET /login` → 200 |
| Sign in with valid credentials | redirects to `/`, session works |
| Sign in with invalid credentials | redirects to login with error |
| Sign out clears session | `/` redirects to login after logout |
| Root requires authentication | `GET /` → redirect to login |
| Signed-in user visiting login | redirected home |

**6 session tests** (46 total in suite).

#### Test helper: `sign_in_as`

**File:** `test/test_helper.rb`

```ruby
def sign_in_as(user, password: "password")
  post session_path, params: { email: user.email, password: password }
end
```

Used **inside test files only** — simulates logging in without using the browser UI. Example:

```ruby
sign_in_as(users(:admin))
get root_path
assert_response :success
```

### 3.6 How to manually test Step 3

```bash
bin/rails db:seed    # creates admin, advisor, assistant @leadflow.local
bin/dev              # start Rails + Vite
```

Open **`http://localhost:3000/login`** (or whatever port Puma prints).

| Step | Expected result |
|------|-----------------|
| Visit `/` while logged out | Redirect to `/login` |
| Login with `admin@leadflow.local` / `password` | Redirect to home; name shown |
| Click Sign out | Back to login page |

---

## Complete file inventory (local changes)

### Committed (Step 1 — in git as `WIP: local models, seeds, and migrations`)

```
Gemfile                          # bcrypt enabled
db/migrate/                      # 15 migration files
db/schema.rb                     # generated schema
db/seeds.rb                      # seed data
app/models/                      # 15 domain models (+ application_record.rb)
```

### Not yet committed (Steps 2 + 3)

```
# Authentication
app/controllers/concerns/authentication.rb
app/controllers/sessions_controller.rb
app/controllers/application_controller.rb   # modified
app/controllers/inertia_controller.rb       # modified
config/routes.rb                            # modified

# Frontend
app/javascript/pages/sessions/new.tsx
app/javascript/pages/dashboard/index.tsx      # Story 1.5
app/javascript/types/index.ts                   # modified

# Tests
test/test_helper.rb                         # sign_in_as helper
test/controllers/sessions_controller_test.rb
test/fixtures/*.yml                         # 14 fixture files
test/models/*_test.rb                       # 15 model test files

# Dev UX
bin/dev                                     # startup URL reminder
```

---

## Commands cheat sheet

| Task | Command |
|------|---------|
| Install dependencies | `bundle install && npm install` |
| Create + migrate DB | `bin/rails db:create db:migrate` |
| Load seed data | `bin/rails db:seed` |
| Run app (dev) | `bin/dev` → open `http://localhost:3000/login` |
| Run all tests | `bin/rails test` |
| Run model tests only | `bin/rails test test/models/` |
| Run auth tests only | `bin/rails test test/controllers/sessions_controller_test.rb` |
| Rails console | `bin/rails console` |

---

## Step 4 — Role-Based Authorization (Pundit)

### What we did

Added **Pundit** policies so Admin, Advisor, and Assistant permissions are enforced server-side (fail closed).

| Component | Purpose |
|-----------|---------|
| `app/policies/*_policy.rb` | Lead, Note, Task, Meeting, Opportunity, User policies |
| `User#admin?`, `#advisor?`, `#assistant?` | Role helpers |
| `Admin::UsersController` | Stub `/admin/users` route for authorization tests |
| Policy + controller tests | 13 new tests (59 total in suite) |

**Matrix:** See PRD addendum or `docs/DATA_MODEL.md#role-permissions`.

**Verify:**

```bash
bin/rails test test/policies/ test/controllers/admin_access_test.rb
```

---

### Step 5 — App layout and role-aware navigation (Story 1.4)

**Goal:** Consistent CRM shell on every authenticated Inertia page.

| Component | Purpose |
|-----------|---------|
| `AppLayout` | Sidebar (Dashboard, Leads, Tasks, Meetings, Opportunities), admin links for admin role, user footer with sign out |
| Placeholder pages | `/`, `/leads`, `/tasks`, `/meetings`, `/opportunities`, `/admin/users`, `/admin/roles` |
| Login | Unchanged — no app shell |

**Verify:**

```bash
bin/rails test test/controllers/app_navigation_test.rb
npm run check
```

---

### Step 6 — Dashboard with summary metrics (Story 1.5)

**Goal:** Role-scoped dashboard widgets at `/`.

| Widget | Source |
|--------|--------|
| Open leads | Policy-scoped leads excluding Closed stage |
| Overdue tasks | Pending/in-progress past due + status overdue |
| Upcoming meetings | Scheduled within 7 days |
| Pipeline value | Sum of active opportunity values (excludes Won/Lost) |

**Verify:**

```bash
bin/rails test test/services/dashboard_metrics_test.rb test/controllers/dashboard_controller_test.rb
npm run check
bin/rails db:seed   # loads sample CRM data in development
```

---

### Step 7 — README course compliance (Story 1.6)

**Goal:** README satisfies Week 1 course checklist for professor review.

| Requirement | README section |
|-------------|----------------|
| 6+ non-CRUD use cases | `Use cases → Non-CRUD use cases` (7 listed) |
| CRUD scope separate | `Use cases → CRUD use cases` |
| Stripe, jobs, presentation | `Roadmap` (Weeks 6–7) |
| Task naming | `Main models` + naming note |

**Verify:** Review [README.md](../README.md) against course checklist.

---

### Step 8 — Leads index with search (Story 2.1)

**Goal:** Role-scoped leads table with search and pagination at `/leads`.

| Piece | Behavior |
|-------|----------|
| Scope | Advisor → assigned only; Admin/Assistant → all |
| Search | Case-insensitive match on name, email, company |
| Table | name, company, stage, advisor, last activity, estimated value |
| Pagination | 25 per page |

**Verify:**

```bash
bin/rails test test/controllers/leads_controller_test.rb
npm run check
```

---

### Step 9 — Create lead (Story 2.2)

**Goal:** Admin/Advisor create form at `/leads/new` with company dedup and unique email.

| Piece | Behavior |
|-------|----------|
| Auth | Admin + Advisor create; Assistant denied |
| Company | `Company.find_or_initialize_by_name` (free-text name + company country) |
| Email | Required unique; reject duplicates via `Lead.find_or_initialize_by_email` |
| Assignment | Advisor forced to self; Admin picks assignee |
| Success | Redirect to `/leads` with flash notice |

**Verify:**

```bash
bin/rails test test/controllers/leads_controller_test.rb test/policies/lead_policy_test.rb
npm run check
```

---

### Step 10 — Edit lead (Story 2.3)

**Goal:** Authorized update form at `/leads/:id/edit` reusing the shared lead form.

| Piece | Behavior |
|-------|----------|
| Auth | Admin any; Advisor assigned only; Assistant denied |
| Form | Shared `LeadForm` with create; company dedup + country checkbox |
| Assignment | Advisor forced to self; Admin may reassign |
| Success | Redirect to `/leads/:id` with flash notice |

**Verify:**

```bash
bin/rails test test/controllers/leads_controller_test.rb test/policies/lead_policy_test.rb
npm run check
```

---

### Step 11 — Lead detail (Story 2.4)

**Goal:** Authorized read view at `/leads/:id` with related-record counts and previews.

| Piece | Behavior |
|-------|----------|
| Auth | Admin/Assistant any; Advisor assigned only |
| Fields | Name, email, phone, value, last activity, company, country, stage, advisor |
| Related | Tasks, meetings, notes, opportunities — count + preview rows |
| Index | Lead name links to detail; Edit when `can_update` |
| Saves | Create/update redirect to detail |

**Verify:**

```bash
bin/rails test test/controllers/leads_controller_test.rb test/policies/lead_policy_test.rb
npm run check
```

---

## What is NOT implemented yet

These are planned next steps (not part of current local work):

| Step | Feature |
|------|---------|
| 12 | Epic 1 retrospective (optional) |
| 13 | Tasks list + create/complete (Stories 3.1–3.2) |

---

## Suggested narrative for a presentation

> “Starting from the approved data model design, I implemented the full PostgreSQL schema with 15 tables and Rails migrations, including a fix for separate lead and opportunity stage foreign keys.
>
> I built Active Record models with associations and validations, plus Company name normalization for deduplication. Seed data lets us log in locally as an admin user.
>
> I added 40 automated model tests with realistic fixtures to verify validations and associations.
>
> For authentication, I implemented session-based login and logout using a Rails concern, a SessionsController, and an Inertia React login page. Protected routes redirect unauthenticated users to `/login`, and the current user is shared with all React pages. Six integration tests cover the auth flow, and the full suite of 46 tests passes.”

---

## Sharing with a professor

1. Commit all local changes.
2. Push branch: `git push -u origin cursor/implement-models`
3. Open a GitHub PR with a link to this document.
4. Include login credentials: `admin@leadflow.local` / `password`
5. Remind them to use the **Rails port** (3000), not Vite (3036).
