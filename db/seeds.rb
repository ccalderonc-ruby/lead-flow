# frozen_string_literal: true

[
  { iso_code: "US", name: "United States", region: "North America" },
  { iso_code: "CA", name: "Canada", region: "North America" },
  { iso_code: "CR", name: "Costa Rica", region: "Central America" },
  { iso_code: "MX", name: "Mexico", region: "North America" },
  { iso_code: "GB", name: "United Kingdom", region: "Europe" }
].each do |attrs|
  Country.find_or_create_by!(iso_code: attrs[:iso_code]) { |country| country.assign_attributes(attrs) }
end

%w[admin advisor assistant].each do |name|
  Role.find_or_create_by!(name:)
end

[
  { name: "Prospect", position: 1, color: "#6366f1" },
  { name: "Qualified", position: 2, color: "#22c55e" },
  { name: "Negotiation", position: 3, color: "#a855f7" },
  { name: "Nurturing", position: 4, color: "#f59e0b" },
  { name: "Closed", position: 5, color: "#6b7280" }
].each do |attrs|
  LeadStage.find_or_create_by!(name: attrs[:name]) { |stage| stage.assign_attributes(attrs) }
end

[
  { name: "Prospect", position: 1, default_probability: 20 },
  { name: "Qualification", position: 2, default_probability: 45 },
  { name: "Proposal", position: 3, default_probability: 60 },
  { name: "Negotiation", position: 4, default_probability: 80 },
  { name: "Won", position: 5, default_probability: 100 },
  { name: "Lost", position: 6, default_probability: 0 }
].each do |attrs|
  OpportunityStage.find_or_create_by!(name: attrs[:name]) { |stage| stage.assign_attributes(attrs) }
end

Team.find_or_create_by!(name: "Enterprise Sales") do |team|
  team.description = "Default sales team for local development"
end

def seed_dashboard_sample_data(team:, us:, cr:, advisor:, admin:)
  return if Lead.exists?

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

if Rails.env.development?
  us = Country.find_by!(iso_code: "US")
  cr = Country.find_by!(iso_code: "CR")
  team = Team.find_by!(name: "Enterprise Sales")

  [
    { email: "admin@leadflow.local", name: "Admin User", role: "admin", country: us },
    { email: "advisor@leadflow.local", name: "Alex Advisor", role: "advisor", country: cr },
    { email: "assistant@leadflow.local", name: "Casey Assistant", role: "assistant", country: us }
  ].each do |attrs|
    role = Role.find_by!(name: attrs[:role])
    User.find_or_create_by!(email: attrs[:email]) do |user|
      user.name = attrs[:name]
      user.password = "password"
      user.role = role
      user.team = team
      user.country = attrs[:country]
      user.status = "active"
    end
  end

  seed_dashboard_sample_data(
    team: team,
    us: us,
    cr: cr,
    advisor: User.find_by!(email: "advisor@leadflow.local"),
    admin: User.find_by!(email: "admin@leadflow.local")
  )
end
