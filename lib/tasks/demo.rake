# frozen_string_literal: true

namespace :demo do
  desc "Ensure demo users + enrich local CRM with presentation leads/tasks/notes/meetings/opportunities"
  task enrich: :environment do
    unless Rails.env.development?
      abort "demo:enrich is only available in development (current: #{Rails.env})"
    end

    us = Country.find_by!(iso_code: "US")
    cr = Country.find_by!(iso_code: "CR")
    team = Team.find_by!(name: "Enterprise Sales")

    DemoSeeds.ensure_demo_users!(team: team)
    advisor = User.find_by!(email: "advisor@leadflow.local")
    admin = User.find_by!(email: "admin@leadflow.local")

    DemoSeeds.seed_dashboard_sample_data(
      team: team,
      us: us,
      cr: cr,
      advisor: advisor,
      admin: admin
    )

    puts "Demo catalog ready."
    puts "  Leads:         #{Lead.count}"
    puts "  Tasks:         #{Task.count}"
    puts "  Notes:         #{Note.count}"
    puts "  Meetings:      #{Meeting.count}"
    puts "  Opportunities: #{Opportunity.count}"
    puts
    puts "Login as Elena: advisor@leadflow.local / password"
  end
end
