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
  { name: "Prospects", position: 1, default_probability: 20 },
  { name: "Proposal", position: 2, default_probability: 60 },
  { name: "Negotiation", position: 3, default_probability: 80 },
  { name: "Won", position: 4, default_probability: 100 },
  { name: "Lost", position: 5, default_probability: 0 }
].each do |attrs|
  OpportunityStage.find_or_create_by!(name: attrs[:name]) { |stage| stage.assign_attributes(attrs) }
end

Team.find_or_create_by!(name: "Enterprise Sales") do |team|
  team.description = "Default sales team for local development"
end

if Rails.env.development?
  us = Country.find_by!(iso_code: "US")
  cr = Country.find_by!(iso_code: "CR")
  team = Team.find_by!(name: "Enterprise Sales")

  DemoSeeds.ensure_demo_users!(team: team)
  DemoSeeds.seed_dashboard_sample_data(
    team: team,
    us: us,
    cr: cr,
    advisor: User.find_by!(email: "advisor@leadflow.local"),
    admin: User.find_by!(email: "admin@leadflow.local")
  )
end
