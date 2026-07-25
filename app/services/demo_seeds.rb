# frozen_string_literal: true

# Development demo users + sample CRM rows for local role testing (Story 5.1).
# Called from db/seeds.rb — keep surgical; do not conflate with test fixtures (*@example.com).
class DemoSeeds
  DEMO_PASSWORD = "password"

  DEMO_USERS = [
    { email: "admin@leadflow.local", name: "Admin User", role: "admin", country_iso: "US" },
    { email: "advisor@leadflow.local", name: "Alex Advisor", role: "advisor", country_iso: "CR" },
    { email: "assistant@leadflow.local", name: "Casey Assistant", role: "assistant", country_iso: "US" }
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
        user.save!
      end
    end

    def seed_dashboard_sample_data(team:, us:, cr:, advisor:, admin:)
      if Lead.exists?
        ensure_advisor_assigned_lead!(team: team, us: us, advisor: advisor)
        return
      end

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
  end
end
