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
| Payments | Stripe (test mode, planned) |
| Deploy | Docker, Kamal |

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

| Week | Focus |
|------|-------|
| 1 | Auth, roles, app shell, dashboard, README ✅ |
| 2–5 | CRUD UI for leads, tasks, notes, meetings, opportunities; search; admin screens |
| 6 | **Background jobs** (`MarkOverdueTasksJob` via Solid Queue), **Stripe** test checkout + webhook, Kamal deploy |
| 7 | Test gaps, polish, **final course presentation** |

**Course deliverables still planned:** gated CSV export (subscription), production deployment, and final presentation demo. Stripe test checkout + webhook are implemented (see `.env.example`).

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

## Data model

See [docs/DATA_MODEL.md](docs/DATA_MODEL.md) for the full entity relationship diagram, associations, validations, role permissions, and scaffold commands.

## Project status

**Week 1 complete:** database schema, models, seeds, session auth, Pundit authorization, app layout, and dashboard metrics.

**In progress:** CRM CRUD pages (Epics 2–5).

## Author

Developed by Cheyenne Calderon.

## Notes

This project was developed as part of a Ruby on Rails and React course.
