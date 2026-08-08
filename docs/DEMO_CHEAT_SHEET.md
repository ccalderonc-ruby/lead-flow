# LeadFlow — Demo cheat sheet

**Open:** `http://localhost:3000` · **Primary login:** `advisor@leadflow.local` / `password`

| Role | Email | Show |
|------|-------|------|
| Advisor (Elena Vargas) | `advisor@leadflow.local` | Main demo |
| Admin (Jordan Hale) | `admin@leadflow.local` | Users / roles |
| Assistant (Carlos Mendez) | `assistant@leadflow.local` | Notes/tasks; lead edit denied |

**Refresh demo data:** `bin/rails demo:enrich` (adds leads/tasks/notes/meetings/pipeline; safe to re-run)

**Full click script (5 / 10 / 15–20 min):** [DEMO_WALKTHROUGH.md](./DEMO_WALKTHROUGH.md)

---

## 30-second pitch

CRM for advisors: Rails brain + React face, joined by **Inertia**. Postgres data. Sessions + **Pundit** roles. Plus job, Stripe, gated CSV. Demo: dashboard → lead note → pipeline.

---

## Stack (say this list)

| Layer | Tech |
|-------|------|
| Backend | Ruby, **Rails 8.1**, Puma |
| DB | **PostgreSQL** + Active Record |
| Auth | bcrypt + **session cookie** |
| Permissions | **Pundit** |
| Frontend | **React 19**, TypeScript, **Tailwind** |
| Glue | **Inertia.js** (not a separate REST API) |
| Assets | **Vite** |
| Jobs | **Solid Queue** (overdue tasks) |
| Payments | **Stripe** Checkout + webhook |
| Deploy | **Docker + Kamal** (URL TBD) |
| Quality | Minitest, Capybara system test, GitHub CI |

---

## Architecture (one sentence)

**Browser → Inertia → Rails controller/policy/model → PostgreSQL → props back to a React page.**

- Backend: `app/controllers`, `app/models`, `app/policies`
- Frontend: `app/javascript/pages` + `components`
- Routes: `config/routes.rb`

---

## Click path (UJ-1 → UJ-3)

1. **Login** → Dashboard (open leads, overdue tasks, meetings, pipeline $)
2. **Leads** → open row → **Add note**
3. **Opportunities** → open card → stage **Proposal** + value → save

**Extras:** Subscription · CSV export · Admin users · Assistant denial

---

## Why these choices

| Choice | Why |
|--------|-----|
| Rails + React + Inertia | Rails owns data/auth/rules; React owns rich UI; one app |
| PostgreSQL | Relational CRM data (leads → tasks/notes/deals) |
| Pundit | Role rules testable; not only hiding buttons |
| Solid Queue | Rails 8 jobs in DB; daily overdue mark |
| Stripe webhook | Server truth for “paid,” not the browser |
| Kamal/Docker | Real deploy path; host optional for class demo |

---

## Two words that impress

1. **Authentication** = who you are (login/session)  
2. **Authorization** = what you can do (Pundit)

UI can hide a button; **policy still blocks** the request.

---

## If asked about AI

*AI sped up implementation. I own the architecture, data model, role rules, and can map any screen → controller → policy → table.*

---

## Closing line

> Rails 8 + React via Inertia, Postgres, session auth, Pundit roles, Solid Queue, Stripe, tests/CI — advisor journey: dashboard, notes, pipeline.
