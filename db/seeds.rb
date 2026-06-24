# frozen_string_literal: true

[
  { iso_code: "US", name: "United States", region: "North America" },
  { iso_code: "CA", name: "Canada", region: "North America" },
  { iso_code: "CR", name: "Costa Rica", region: "Central America" },
  { iso_code: "MX", name: "Mexico", region: "North America" },
  { iso_code: "GB", name: "United Kingdom", region: "Europe" },
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
  { name: "Closed", position: 5, color: "#6b7280" },
].each do |attrs|
  LeadStage.find_or_create_by!(name: attrs[:name]) { |stage| stage.assign_attributes(attrs) }
end

[
  { name: "Prospect", position: 1, default_probability: 20 },
  { name: "Qualification", position: 2, default_probability: 45 },
  { name: "Proposal", position: 3, default_probability: 60 },
  { name: "Negotiation", position: 4, default_probability: 80 },
  { name: "Won", position: 5, default_probability: 100 },
  { name: "Lost", position: 6, default_probability: 0 },
].each do |attrs|
  OpportunityStage.find_or_create_by!(name: attrs[:name]) { |stage| stage.assign_attributes(attrs) }
end

Team.find_or_create_by!(name: "Enterprise Sales") do |team|
  team.description = "Default sales team for local development"
end

if Rails.env.development?
  us = Country.find_by!(iso_code: "US")
  admin_role = Role.find_by!(name: "admin")
  team = Team.find_by!(name: "Enterprise Sales")

  User.find_or_create_by!(email: "admin@leadflow.local") do |user|
    user.name = "Admin User"
    user.password = "password"
    user.role = admin_role
    user.team = team
    user.country = us
    user.status = "active"
  end
end
