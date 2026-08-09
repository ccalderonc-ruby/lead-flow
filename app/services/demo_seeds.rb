# frozen_string_literal: true

# Development demo users + sample CRM rows for local role testing (Story 5.1)
# and presentation catalog enrichment (demo day).
# Called from db/seeds.rb / bin/rails demo:enrich — keep surgical; do not conflate with test fixtures (*@example.com).
class DemoSeeds
  DEMO_PASSWORD = "password"

  DEMO_USERS = [
    { email: "admin@leadflow.local", name: "Jordan Hale", role: "billing_admin", country_iso: "US" },
    { email: "advisor@leadflow.local", name: "Elena Vargas", role: "advisor", country_iso: "CR" },
    { email: "assistant@leadflow.local", name: "Carlos Mendez", role: "assistant", country_iso: "US" }
  ].freeze

  ADVISOR_ENSURE_LEAD_EMAIL = "demo.advisor.lead@leadflow.local"

  class << self
    def ensure_demo_users!(team:)
      DEMO_USERS.each do |attrs|
        role = Role.find_by!(name: attrs[:role])
        country = Country.find_by!(iso_code: attrs[:country_iso])

        user = User.find_or_initialize_by(email: attrs[:email])
        user.name = attrs[:name]
        user.password = DEMO_PASSWORD
        user.role = role
        user.team = team
        user.country = country
        user.status = "active"
        # Billing admin holds org billing; other demo users get Pro access for CSV export demos.
        user.subscription_status = attrs[:role] == "billing_admin" ? "active" : "inactive"
        user.pro_access = attrs[:role] != "billing_admin"
        user.save!
      end

      ensure_demo_advisor_assistant_assignment!
    end

    def ensure_demo_advisor_assistant_assignment!
      advisor = User.find_by(email: "advisor@leadflow.local")
      assistant = User.find_by(email: "assistant@leadflow.local")
      return unless advisor&.advisor? && assistant&.assistant?

      AdvisorAssistant.find_or_create_by!(advisor: advisor, assistant: assistant)
    end

    def seed_dashboard_sample_data(team:, us:, cr:, advisor:, admin:)
      if Lead.exists?
        ensure_advisor_assigned_lead!(team: team, us: us, advisor: advisor)
      else
        prospect = LeadStage.find_by!(name: "Prospect")
        qualified = LeadStage.find_by!(name: "Qualified")
        proposal = OpportunityStage.find_by!(name: "Proposal")

        technova = Company.find_or_initialize_by_name("TechNova Inc")
        technova.country = us
        technova.save!

        acme = Company.find_or_initialize_by_name("Acme Corp")
        acme.country = cr
        acme.save!

        sarah = Lead.create!(
          name: "Sarah Jenkins",
          email: "sarah.jenkins@example.com",
          stage: qualified,
          user: advisor,
          team: team,
          company: technova,
          country: us,
          estimated_value: 45_000
        )

        Lead.create!(
          name: "Marcus Wright",
          email: "marcus.wright@example.com",
          stage: prospect,
          user: advisor,
          team: team,
          company: acme,
          country: cr
        )

        Lead.create!(
          name: "Enterprise Global",
          email: "enterprise@example.com",
          stage: prospect,
          user: admin,
          team: team,
          company: acme,
          country: us
        )

        Task.create!(
          title: "Follow up on proposal",
          description: "Send updated pricing deck",
          due_date: Date.current - 2.days,
          status: "pending",
          priority: "medium",
          lead: sarah,
          user: advisor
        )

        Meeting.create!(
          title: "Proposal review",
          scheduled_on: Date.current + 3.days,
          start_time: Time.zone.parse("14:00"),
          duration_minutes: 45,
          status: "scheduled",
          virtual_meeting: true,
          virtual_link: "https://meet.example.com/proposal-review",
          lead: sarah,
          user: advisor
        )

        Opportunity.create!(
          title: "CRM Migration",
          value: 32_000,
          probability: 60,
          close_date: Date.current + 120.days,
          priority: "high",
          stage: proposal,
          lead: sarah,
          user: advisor
        )
      end

      enrich_presentation_catalog!(team: team, us: us, cr: cr, advisor: advisor, admin: admin)
    end

    # Idempotent rich catalog for demos. Safe to re-run; uses unique lead emails.
    def enrich_presentation_catalog!(team:, us:, cr:, advisor:, admin:)
      assistant = User.find_by(email: "assistant@leadflow.local")
      stages = LeadStage.all.index_by(&:name)
      opp_stages = OpportunityStage.all.index_by(&:name)

      # Map preferred names → whatever exists in this DB (seeds vs fixtures).
      lead_stage = ->(preferred) {
        stages[preferred] ||
          stages["Qualified"] ||
          stages["Prospect"] ||
          stages.values.first
      }
      opp_stage = ->(preferred) {
        opp_stages[preferred] ||
          opp_stages["Proposal"] ||
          opp_stages["Prospects"] ||
          opp_stages["Prospect"] ||
          opp_stages.values.first
      }

      companies = {
        "Harbor Wealth" => us,
        "Pinnacle Insurance" => us,
        "Verde Capital CR" => cr,
        "Summit Advisory Group" => us,
        "Lumina Benefits" => us,
        "Costa Rica Pensions" => cr,
        "Northwind Family Office" => us,
        "Atlas Brokerage" => us
      }.map do |name, country|
        company = Company.find_or_initialize_by_name(name)
        company.country = country
        company.save!
        [ name, company ]
      end.to_h

      catalog = [
        {
          name: "Priya Shah",
          email: "priya.shah@demo.leadflow.local",
          company: "Harbor Wealth",
          country: us,
          stage: "Qualified",
          title: "Managing Partner",
          phone: "+1-415-555-0142",
          value: 85_000,
          owner: advisor,
          tasks: [
            { title: "Send IPS draft", due: -1, status: "overdue", priority: "high" },
            { title: "Confirm risk questionnaire", due: 2, status: "pending", priority: "medium" }
          ],
          notes: [
            { user: advisor, content: "Strong fit for LeadFlow Pro — wants pipeline visibility for two juniors." },
            { user: assistant, content: "Left voicemail; callback window Tue/Thu mornings." }
          ],
          meetings: [
            { title: "Discovery call", on: 2, time: "10:00", virtual: true }
          ],
          opportunities: [
            { title: "Harbor Wealth rollout", stage: "Proposal", value: 48_000, priority: "high" }
          ]
        },
        {
          name: "James Okonkwo",
          email: "james.okonkwo@demo.leadflow.local",
          company: "Pinnacle Insurance",
          country: us,
          stage: "Qualified",
          title: "VP Sales",
          phone: "+1-312-555-0198",
          value: 120_000,
          owner: advisor,
          tasks: [
            { title: "Prepare contract redlines", due: 1, status: "in_progress", priority: "high" },
            { title: "Security questionnaire", due: 5, status: "pending", priority: "medium" }
          ],
          notes: [
            { user: advisor, content: "Legal is reviewing data residency; push for close this month." }
          ],
          meetings: [
            { title: "Contract walkthrough", on: 4, time: "15:30", virtual: true }
          ],
          opportunities: [
            { title: "Pinnacle annual seats", stage: "Negotiation", value: 96_000, priority: "high" }
          ]
        },
        {
          name: "Sofia Rojas",
          email: "sofia.rojas@demo.leadflow.local",
          company: "Verde Capital CR",
          country: cr,
          stage: "Prospect",
          title: "Advisor",
          phone: "+506-2222-0101",
          value: 28_000,
          owner: advisor,
          tasks: [
            { title: "Share one-pager (ES)", due: 3, status: "pending", priority: "low" }
          ],
          notes: [
            { user: assistant, content: "Prefers Spanish materials; interested in meetings module." }
          ],
          meetings: [
            { title: "Intro Zoom", on: 6, time: "11:00", virtual: true }
          ],
          opportunities: [
            { title: "Verde starter pack", stage: "Prospects", value: 18_000, priority: "medium" }
          ]
        },
        {
          name: "Daniel Cho",
          email: "daniel.cho@demo.leadflow.local",
          company: "Summit Advisory Group",
          country: us,
          stage: "Qualified",
          title: "COO",
          phone: "+1-646-555-0177",
          value: 64_000,
          owner: advisor,
          tasks: [
            { title: "Demo pipeline board", due: 0, status: "pending", priority: "high" },
            { title: "Collect user list", due: 7, status: "pending", priority: "medium" }
          ],
          notes: [
            { user: advisor, content: "Currently on spreadsheets; 6 advisors on the team." }
          ],
          meetings: [
            { title: "Live product demo", on: 1, time: "13:00", virtual: true }
          ],
          opportunities: [
            { title: "Summit team license", stage: "Proposal", value: 54_000, priority: "medium" }
          ]
        },
        {
          name: "Amelia Brooks",
          email: "amelia.brooks@demo.leadflow.local",
          company: "Lumina Benefits",
          country: us,
          stage: "Prospect",
          title: "Director of Ops",
          phone: "+1-206-555-0133",
          value: 40_000,
          owner: advisor,
          tasks: [
            { title: "Quarterly check-in email", due: 10, status: "pending", priority: "low" }
          ],
          notes: [
            { user: advisor, content: "Budget frozen until Q4 — keep warm with case studies." }
          ],
          meetings: [],
          opportunities: [
            { title: "Lumina nurture", stage: "Prospects", value: 35_000, priority: "low" }
          ]
        },
        {
          name: "Mateo Jiménez",
          email: "mateo.jimenez@demo.leadflow.local",
          company: "Costa Rica Pensions",
          country: cr,
          stage: "Qualified",
          title: "Head of Client Success",
          phone: "+506-4000-2211",
          value: 52_000,
          owner: advisor,
          tasks: [
            { title: "Overdue: send ROI sheet", due: -3, status: "overdue", priority: "high" }
          ],
          notes: [
            { user: assistant, content: "Asked about assistant permissions — good story for Carlos demo." },
            { user: advisor, content: "Wants CSV export for board packet." }
          ],
          meetings: [
            { title: "On-site follow-up", on: 5, time: "09:30", virtual: false, location: "San José HQ" }
          ],
          opportunities: [
            { title: "CRP Pro subscription", stage: "Proposal", value: 42_000, priority: "high" }
          ]
        },
        {
          name: "Helen Park",
          email: "helen.park@demo.leadflow.local",
          company: "Northwind Family Office",
          country: us,
          stage: "Prospect",
          title: "Principal",
          phone: "+1-617-555-0160",
          value: 75_000,
          owner: advisor,
          tasks: [
            { title: "Book intro with Elena", due: 2, status: "pending", priority: "medium", assignee: assistant }
          ],
          notes: [
            { user: assistant, content: "Inbound from conference — high interest in opportunities board." }
          ],
          meetings: [
            { title: "Conference follow-up", on: 3, time: "16:00", virtual: true }
          ],
          opportunities: [
            { title: "Northwind evaluation", stage: "Prospects", value: 60_000, priority: "medium" }
          ]
        },
        {
          name: "Robert Lang",
          email: "robert.lang@demo.leadflow.local",
          company: "Atlas Brokerage",
          country: us,
          stage: "Closed",
          title: "Owner",
          phone: "+1-512-555-0188",
          value: 22_000,
          owner: advisor,
          tasks: [
            { title: "Archive closed-lost summary", due: -5, status: "completed", priority: "low" }
          ],
          notes: [
            { user: advisor, content: "Chose competitor on price — revisit in 6 months." }
          ],
          meetings: [],
          opportunities: [
            { title: "Atlas lost deal", stage: "Lost", value: 22_000, priority: "low" }
          ]
        },
        {
          name: "Nina Alvarez",
          email: "nina.alvarez@demo.leadflow.local",
          company: "Atlas Brokerage",
          country: us,
          stage: "Prospect",
          title: "Operations Lead",
          phone: "+1-512-555-0189",
          value: 15_000,
          owner: admin,
          tasks: [
            { title: "Admin review of account", due: 4, status: "pending", priority: "low" }
          ],
          notes: [
            { user: admin, content: "Admin-owned lead — use to show Admin sees all leads." }
          ],
          meetings: [],
          opportunities: [
            { title: "Atlas ops seat", stage: "Prospects", value: 12_000, priority: "low" }
          ]
        }
      ]

      catalog.each do |row|
        upsert_catalog_lead!(
          row: row,
          team: team,
          companies: companies,
          lead_stage: lead_stage,
          opp_stage: opp_stage,
          advisor: advisor,
          assistant: assistant
        )
      end
    end

    # Idempotent AC2 guard: when sample CRM was skipped because leads already exist,
    # still guarantee the advisor has at least one assigned lead (no wipe).
    def ensure_advisor_assigned_lead!(team:, us:, advisor:)
      return if advisor.leads.exists?

      qualified = LeadStage.find_by!(name: "Qualified")
      company = Company.find_or_initialize_by_name("TechNova Inc")
      company.country = us
      company.save!

      lead = Lead.find_or_initialize_by(email: ADVISOR_ENSURE_LEAD_EMAIL)
      lead.name = "Demo Advisor Lead"
      lead.stage = qualified
      lead.user = advisor
      lead.team = team
      lead.company = company
      lead.country = us
      lead.save!
    end

    private

    def upsert_catalog_lead!(row:, team:, companies:, lead_stage:, opp_stage:, advisor:, assistant:)
      lead = Lead.find_or_initialize_by(email: row[:email])
      lead.name = row[:name]
      lead.professional_title = row[:title]
      lead.phone = row[:phone]
      lead.stage = lead_stage.call(row[:stage])
      lead.user = row[:owner]
      lead.team = team
      lead.company = companies.fetch(row[:company])
      lead.country = row[:country]
      lead.estimated_value = row[:value]
      lead.lead_source = "Demo catalog"
      lead.last_activity_at = Time.current
      lead.save!

      Array(row[:tasks]).each do |task_row|
        assignee = task_row[:assignee] || row[:owner]
        task = Task.find_or_initialize_by(lead: lead, title: task_row[:title])
        task.description = task_row[:description]
        task.due_date = Date.current + task_row[:due].days
        task.status = task_row[:status]
        task.priority = task_row[:priority]
        task.user = assignee || advisor
        task.save!
      end

      Array(row[:notes]).each do |note_row|
        next if note_row[:user].blank?

        Note.find_or_create_by!(lead: lead, user: note_row[:user], content: note_row[:content])
      end

      Array(row[:meetings]).each do |meeting_row|
        meeting = Meeting.find_or_initialize_by(lead: lead, title: meeting_row[:title])
        meeting.scheduled_on = Date.current + meeting_row[:on].days
        meeting.start_time = Time.zone.parse(meeting_row[:time])
        meeting.duration_minutes = 45
        meeting.status = "scheduled"
        meeting.user = row[:owner]
        if meeting_row[:virtual]
          meeting.virtual_meeting = true
          meeting.virtual_link = "https://meet.example.com/#{lead.email.split('@').first}"
          meeting.location = nil
        else
          meeting.virtual_meeting = false
          meeting.virtual_link = nil
          meeting.location = meeting_row[:location] || "Office"
        end
        meeting.save!
      end

      Array(row[:opportunities]).each do |opp_row|
        opportunity = Opportunity.find_or_initialize_by(lead: lead, title: opp_row[:title])
        stage = opp_stage.call(opp_row[:stage])
        opportunity.stage = stage
        opportunity.value = opp_row[:value]
        opportunity.probability = stage.default_probability
        opportunity.close_date = Date.current + 90.days
        opportunity.priority = opp_row[:priority]
        opportunity.user = row[:owner]
        opportunity.save!
      end
    end
  end
end
