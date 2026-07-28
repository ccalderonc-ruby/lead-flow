# LeadFlow CRM

LeadFlow CRM is a web application developed as an academic project using **Ruby on Rails** and **React (via Inertia.js)**. The system allows users to manage leads, follow-up tasks, meetings, notes, and sales opportunities within a single platform.

The main goal of the project is to help advisors and sales teams organize their sales process and client follow-ups more efficiently.

## Project description

Many financial advisors, insurance agents, and consultants manage their leads using spreadsheets, personal notes, or messaging applications, which can lead to:

- Lost information
- Forgotten follow-ups
- Difficulty tracking opportunities
- Poor sales organization

LeadFlow CRM centralizes this information through a web-based system with user authentication, role-based authorization, and lead management features.

## Project goals

- Implement user authentication
- Implement role-based authorization
- Use a relational database (PostgreSQL)
- Implement functional CRUD operations
- Apply validations
- Create automated tests
- Build a full-stack architecture using Rails and React

## User roles

| Role | Permissions |
|------|-------------|
| **Admin** | Manages users and all system data |
| **Advisor** | Manages assigned leads, tasks, meetings, and opportunities |
| **Assistant** | Can view information and add notes or tasks |

## Main models

| Model | Description |
|-------|-------------|
| `User` | Authenticated system user |
| `Role` | Defines permissions (Admin, Advisor, Assistant) |
| `Lead` | Prospective or active client |
| `Opportunity` | Sales opportunity linked to a lead |
| `Task` | Scheduled follow-up action on a lead (table: `tasks`) |
| `Meeting` | Meeting with a lead |
| `Note` | Note or comment on a lead |

> **Naming note:** The course README originally used `FollowUpTask`; the implementation uses **`Task`** consistently in code, migrations, and tests.

## Database relationships

- A `Role` has many `Users`
- A `User` has many `Leads` (assigned)
- A `Lead` has many `Opportunities`
- A `Lead` has many `Tasks`
- A `Lead` has many `Meetings`
- A `Lead` has many `Notes`

See [docs/DATA_MODEL.md](docs/DATA_MODEL.md) for full fields and associations.

## Use cases

Course requirements distinguish **CRUD** operations from **non-CRUD** system behaviors (authentication, authorization, search, jobs, payments, etc.).

### CRUD use cases

| # | Use case | Primary models |
|---|----------|----------------|
| 1 | Create, read, update, and delete **Leads** | `Lead` |
| 2 | Create, read, update, and delete **Tasks** | `Task` |
| 3 | Create, read, update, and delete **Meetings** | `Meeting` |
| 4 | Create, read, update, and delete **Opportunities** | `Opportunity` |
| 5 | Create, read, update, and delete **Notes** | `Note` |
| 6 | Admin: manage **Users** and view **Roles** | `User`, `Role` |

### Non-CRUD use cases

| # | Use case | Description | Status |
|---|----------|-------------|--------|
| 1 | **Session login / logout** | Cookie-based auth; protected routes redirect to `/login` | ✅ Implemented |
| 2 | **Role-based authorization** | Pundit policies scope data by Admin / Advisor / Assistant | ✅ Implemented |
| 3 | **Dashboard summary metrics** | Role-scoped widgets: open leads, overdue tasks, upcoming meetings, pipeline value | ✅ Implemented |
| 4 | **Lead search and filtering** | Search by name, email, or company; filter by stage | 🔜 Planned (Epic 2) |
| 5 | **Pipeline stage transitions** | Move opportunities across stages; dashboard totals update | 🔜 Planned (Epic 4) |
| 6 | **Mark overdue tasks job** | Solid Queue daily job sets pending past-due tasks to `overdue` | 🔜 Planned (Week 6) |
| 7 | **Stripe subscription checkout** | Test-mode Checkout for "LeadFlow Pro"; webhook gates CSV export | 🔜 Planned (Week 6) |

## Main features

- User login and logout
- Role-based authorization (Pundit)
- App shell with role-aware navigation
- Dashboard with summary metrics
- Lead, task, meeting, opportunity, and note management (CRUD UI in progress)
- Sales pipeline tracking
- Search and filters
- Admin user and role management

## Validations

Examples implemented or planned:

- Unique email per user
- Required lead name, company, and country
- Required task due date
- Positive opportunity values
- Required note content

## Automated tests

The project includes automated tests for:

- Models and validations
- Session authentication
- Role permissions (Pundit policies)
- Dashboard metrics and navigation
- CRUD operations (as features land)

Run the full suite:

```bash
bin/rails test
npm run check   # TypeScript type check
```

## Technologies used

| Layer | Stack |
|-------|-------|
| Backend | Ruby on Rails 8.1, Puma |
| Frontend | React 19, TypeScript, Inertia.js, Tailwind CSS |
| Assets | Vite |
| Database | PostgreSQL |
| Authorization | Pundit |
| Background jobs | Solid Queue |
| Payments | Stripe (test mode) |
| Deploy | Docker, Kamal (scaffold; public URL TBD) |

## Installation

### Prerequisites

- Ruby (see `.ruby-version`)
- Node.js and npm
- PostgreSQL

### Setup

```bash
git clone https://github.com/ccalderonc-ruby/lead-flow.git
cd lead-flow

bundle install
npm install

bin/rails db:create
bin/rails db:migrate
bin/rails db:seed
```

After seeding, development users are available (password `password` for all):

| Role | Email |
|------|-------|
| Admin | admin@leadflow.local |
| Advisor | advisor@leadflow.local |
| Assistant | assistant@leadflow.local |

### Development

Run Rails and Vite together:

```bash
bin/dev
```

Or in separate terminals:

```bash
bin/rails server
bin/vite dev
```

The app will be available at `http://localhost:3000`.

See [docs/IMPLEMENTATION.md](docs/IMPLEMENTATION.md) for step-by-step verification of each milestone.

## Roadmap

| Week | Focus | Status |
|------|-------|--------|
| 1 | Auth, roles, app shell, dashboard, README | ✅ |
| 2–5 | CRUD UI for leads, tasks, notes, meetings, opportunities; search; admin screens | ✅ |
| 6 | Background jobs (`MarkOverdueTasksJob`), Stripe test checkout + webhook, gated CSV, Kamal scaffold | ✅ |
| 7 | Controller + system tests, **final course presentation** docs | ✅ |

**Course deliverables:** Stripe test checkout + webhook ✅ · gated CSV export ✅ · production deployment (**scaffold ready; live URL TBD**) · presentation demo script ✅ (this README).

### Presentation demo (Week 7)

**Public deploy URL:** TBD — no production host provisioned yet (Story 6.4 Option B). When live, verify with `curl -fsS https://<host>/up`. Until then, demo on `http://localhost:3000` after `bin/setup` / `bin/rails db:seed` / `bin/dev`.

#### Demo personas

Password for all: `password`

| Persona | Role | Email | Use in demo |
|---------|------|-------|-------------|
| Jordan | Admin | `admin@leadflow.local` | Users / roles; all CRM data |
| Elena | Advisor | `advisor@leadflow.local` | **Primary demo** — UJ-1–UJ-3, Stripe/CSV |
| Carlos | Assistant | `assistant@leadflow.local` | Notes/tasks only; show lead edit denial |

#### Walkthrough — UJ-1 through UJ-3 (Advisor)

Use **Elena** (`advisor@leadflow.local` / `password`).

1. **UJ-1 — Sign in and see the day**
   - Open `http://localhost:3000` → redirected to `/login`
   - Sign in → **Dashboard** shows open leads, overdue tasks, upcoming meetings, pipeline value
   - Point out sidebar: Dashboard, Leads, Tasks, Meetings, Opportunities (+ Subscription under ACCOUNT)

2. **UJ-2 — Find a lead and add a note**
   - Open **Leads** → search or filter (e.g. stage **Qualified**)
   - Open a lead row → **Lead detail** (company, stage, assignee, related tasks/meetings/notes/opportunities)
   - **Add note** on the timeline → confirm it appears without leaving the page

3. **UJ-3 — Move a deal on the pipeline**
   - Open **Opportunities** → kanban by stage
   - Open a card → drawer: change stage to **Proposal**, set value (and close date if shown) → save
   - Confirm flash and board/column update; optionally return to Dashboard for pipeline value

**Optional extras (time permitting):** Tasks overdue filter; Subscription checkout (Stripe test); CSV export on Leads (subscribed advisor); Admin user create; Assistant denied lead edit.

### Stripe (test mode)

Set these in `.env` (loaded by `dotenv-rails` in development/test) or Rails credentials under `stripe:`:

| Variable | Purpose |
|----------|---------|
| `STRIPE_SECRET_KEY` | Server Checkout Session create |
| `STRIPE_PUBLISHABLE_KEY` | Optional; not required for server-only Checkout redirect |
| `STRIPE_WEBHOOK_SECRET` | Signature verify (`stripe listen` prints `whsec_…`) |
| `STRIPE_PRICE_ID` | LeadFlow Pro price id from Stripe Dashboard |

```bash
stripe listen --forward-to localhost:3000/webhooks/stripe
```

### Deploy (Kamal / Docker) — Story 6.4

**Public URL:** TBD (no production host provisioned yet). Health check path once live: `GET /up` → expect `200`.

The repo includes a production **Dockerfile** and **Kamal** config (`config/deploy.yml`, `.kamal/secrets`). Hosts and registry are still placeholders (`192.168.0.1`, `localhost:5555`).

#### Verify the image builds locally

Requires Docker Desktop, Colima, or another Docker-compatible engine:

```bash
docker build -t lead_flow:6.4 .
```

The image installs **Node.js in the build stage** so Vite can compile assets during `rails assets:precompile`. Runtime image does not need Node.

#### When you have a host

1. Choose a target: existing VPS (SSH), [Fly.io](https://fly.io), [Hetzner](https://www.hetzner.com), or similar.
2. Edit `config/deploy.yml`:
   - `servers.web` → real IP or hostname
   - `registry` → GHCR / Docker Hub / etc. (not `localhost:5555`)
   - Uncomment `proxy` + `ssl` + `host` when terminating TLS with Kamal (also enable `config.assume_ssl` / `config.force_ssl` / `config.hosts` in `config/environments/production.rb`)
3. Provide **PostgreSQL** (Kamal DB accessory or managed DB). Set `DATABASE_URL` / `LEAD_FLOW_DATABASE_PASSWORD` via Kamal secrets — the app is **not** SQLite; the deploy volume is for Active Storage only.
4. Extend `.kamal/secrets` for Stripe test keys (`STRIPE_SECRET_KEY`, `STRIPE_PRICE_ID`, `STRIPE_WEBHOOK_SECRET`) in addition to `RAILS_MASTER_KEY`. Never commit raw secrets.
5. Deploy with Kamal (`bin/kamal setup` / `bin/kamal deploy`), then:

```bash
curl -fsS https://<your-host>/up
```

6. Point Stripe test webhooks at `https://<your-host>/webhooks/stripe` for the subscription demo.

`SOLID_QUEUE_IN_PUMA: true` is already set so background jobs (e.g. overdue tasks) can run inside the web container once the queue DB is prepared.

#### Demo credentials (after `bin/rails db:seed`)

Password for all: `password`

| Role | Email |
|------|-------|
| Admin | `admin@leadflow.local` |
| Advisor | `advisor@leadflow.local` |
| Assistant | `assistant@leadflow.local` |

Fixtures/tests also use `@example.com` variants; seeds use the `.local` addresses above for local and demo logins.

## Data model

See [docs/DATA_MODEL.md](docs/DATA_MODEL.md) for the full entity relationship diagram, associations, validations, role permissions, and scaffold commands.

## Project status

**Course scope complete (Weeks 1–7):** schema and models, session auth + Pundit roles, CRM CRUD (leads, tasks, notes, meetings, opportunities), admin users/roles, Solid Queue overdue job, Stripe subscription + gated CSV, Docker/Kamal deploy scaffold, controller + system tests, and presentation demo docs.

**Still optional:** live public URL when a host is provisioned (`GET /up` → 200). See [Deploy](#deploy-kamal--docker--story-64).

Demo script: [Presentation demo (Week 7)](#presentation-demo-week-7). Step-by-step build log: [docs/IMPLEMENTATION.md](docs/IMPLEMENTATION.md).

## Author

Developed by Cheyenne Calderon.

## Notes

This project was developed as part of a Ruby on Rails and React course.
