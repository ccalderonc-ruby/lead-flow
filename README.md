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
| `FollowUpTask` | Scheduled follow-up action |
| `Meeting` | Meeting with a lead |
| `Note` | Note or comment on a lead |

## Database relationships

- A `Role` has many `Users`
- A `User` has many `Leads` (assigned)
- A `Lead` has many `Opportunities`
- A `Lead` has many `FollowUpTasks`
- A `Lead` has many `Meetings`
- A `Lead` has many `Notes`

See [docs/DATA_MODEL.md](docs/DATA_MODEL.md) for full fields and associations.

## Main features

- User login
- Role management
- Lead management
- Sales pipeline tracking
- Follow-up task creation
- Meeting registration
- Sales opportunity tracking
- Notes and comments
- Search and filters
- Sales dashboard

## Validations

Examples of validations to implement:

- Unique email per user
- Required lead name
- Required task due date
- Positive opportunity values
- Required note content

## Automated tests

The project will include automated tests for:

- Models
- Validations
- Authentication
- Role permissions
- CRUD operations
- Business logic

## Technologies used

| Layer | Stack |
|-------|-------|
| Backend | Ruby on Rails 8.1, Puma |
| Frontend | React 19, TypeScript, Inertia.js, Tailwind CSS |
| Assets | Vite |
| Database | PostgreSQL |
| Background jobs | Solid Queue |
| Deploy | Docker, Kamal |

## Installation

### Prerequisites

- Ruby (see `.ruby-version`)
- Node.js and npm
- PostgreSQL

### Setup

```bash
git clone https://github.com/your-username/leadflow-crm.git
cd leadflow-crm

bundle install
npm install

bin/rails db:create
bin/rails db:migrate
bin/rails db:seed
```

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

### Tests

```bash
bin/rails test
npm run check   # TypeScript type check
```

## Main use cases

1. User login
2. Role management
3. Lead management
4. Follow-up task creation
5. Meeting registration
6. Sales opportunity management
7. Note registration
8. Lead filtering

## Data model

See [docs/DATA_MODEL.md](docs/DATA_MODEL.md) for the full entity relationship diagram, associations, validations, role permissions, and scaffold commands.
