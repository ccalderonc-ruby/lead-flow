# LeadFlow CRM

LeadFlow CRM is a web application developed as an academic project using Ruby on Rails and React. The system allows users to manage leads, follow-up tasks, meetings, notes, and sales opportunities within a single platform.

The main goal of the project is to help advisors and sales teams organize their sales process and client follow-ups more efficiently.

---

# 📌 Project Description

Many financial advisors, insurance agents, and consultants manage their leads using spreadsheets, personal notes, or messaging applications, which can lead to:

- Lost information
- Forgotten follow-ups
- Difficulty tracking opportunities
- Poor sales organization

LeadFlow CRM centralizes this information through a web-based system with user authentication, role-based authorization, and lead management features.

---

# 🎯 Project Goals

- Implement user authentication
- Implement role-based authorization
- Use a relational database
- Implement functional CRUD operations
- Apply validations
- Create automated tests
- Build a full-stack architecture using Rails and React

---

# 👥 User Roles

| Role | Permissions |
|---|---|
| Admin | Manages users and all system data |
| Advisor | Manages assigned leads, tasks, meetings, and opportunities |
| Assistant | Can view information and add notes or tasks |

---

# 🗄️ Main Models

The project includes the following models:

- User
- Role
- Lead
- Opportunity
- FollowUpTask
- Meeting
- Note

---

# 📊 Database Relationships

- A Role can have many Users
- A User can have many Leads
- A Lead can have many Opportunities
- A Lead can have many FollowUpTasks
- A Lead can have many Meetings
- A Lead can have many Notes

---

# ⚙️ Main Features

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

---

# ✅ Validations

Examples of implemented validations:

- Unique email per user
- Required lead name
- Required task due date
- Positive opportunity values
- Required note content

---

# 🧪 Automated Tests

The project will include automated tests for:

- Models
- Validations
- Authentication
- Role permissions
- CRUD operations
- Business logic

---

# 🛠️ Technologies Used

## Backend
- Ruby on Rails

## Frontend
- React

## Database
- Relational database

---

# 🚀 Installation

## Clone repository

```bash
git clone https://github.com/your-username/leadflow-crm.git
```

---

## Backend Setup

```bash
cd backend
bundle install
rails db:create
rails db:migrate
rails server
```

---

## Frontend Setup

```bash
cd frontend
npm install
npm start
```

---

# 📚 Main Use Cases

1. User login
2. Role management
3. Lead management
4. Follow-up task creation
5. Meeting registration
6. Sales opportunity management
7. Note registration
8. Lead filtering

---

# 📄 Project Status

🚧 In development

---

# 👩‍💻 Author

Developed by Cheyenne Calderon.

---

# 📌 Notes

This project was developed as part of a Ruby on Rails and React course.
