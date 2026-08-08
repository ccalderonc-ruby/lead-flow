# frozen_string_literal: true

require "test_helper"

class DemoSeedsTest < ActiveSupport::TestCase
  setup do
    @team = teams(:enterprise)
    @us = countries(:us)
    @cr = countries(:cr)
  end

  test "ensure_demo_users creates three roles with password password" do
    DemoSeeds::DEMO_USERS.each do |attrs|
      User.where(email: attrs[:email]).delete_all
    end

    assert_difference -> { User.where(email: DemoSeeds::DEMO_USERS.map { |u| u[:email] }).count }, 3 do
      DemoSeeds.ensure_demo_users!(team: @team)
    end

    DemoSeeds::DEMO_USERS.each do |attrs|
      user = User.find_by!(email: attrs[:email])
      assert_equal attrs[:name], user.name
      assert_equal attrs[:role], user.role.name
      assert_equal "active", user.status
      assert user.authenticate(DemoSeeds::DEMO_PASSWORD)
    end
  end

  test "ensure_demo_users is idempotent on email" do
    DemoSeeds.ensure_demo_users!(team: @team)

    assert_no_difference "User.count" do
      DemoSeeds.ensure_demo_users!(team: @team)
    end
  end

  test "ensure_demo_users restores password and attrs on re-seed" do
    DemoSeeds.ensure_demo_users!(team: @team)
    advisor = User.find_by!(email: "advisor@leadflow.local")
    advisor.update!(
      name: "Stale Name",
      password: "not-the-demo-password",
      status: "disabled",
      role: roles(:assistant),
      team: teams(:enterprise),
      country: @us
    )

    DemoSeeds.ensure_demo_users!(team: @team)
    advisor.reload

    assert_equal "Elena Vargas", advisor.name
    assert_equal "advisor", advisor.role.name
    assert_equal "active", advisor.status
    assert_equal "active", advisor.subscription_status
    assert_equal @team.id, advisor.team_id
    assert_equal countries(:cr).id, advisor.country_id
    assert advisor.authenticate(DemoSeeds::DEMO_PASSWORD)
    refute advisor.authenticate("not-the-demo-password")
  end

  test "enrich_presentation_catalog creates demo leads with related records" do
    advisor = users(:advisor)
    admin = users(:admin)
    # Fixture users may not match seed emails; ensure assistant exists for note authors.
    DemoSeeds.ensure_demo_users!(team: @team)
    advisor = User.find_by!(email: "advisor@leadflow.local")
    admin = User.find_by!(email: "admin@leadflow.local")

    DemoSeeds.enrich_presentation_catalog!(
      team: @team,
      us: @us,
      cr: @cr,
      advisor: advisor,
      admin: admin
    )

    assert Lead.exists?(email: "priya.shah@demo.leadflow.local")
    priya = Lead.find_by!(email: "priya.shah@demo.leadflow.local")
    assert priya.tasks.exists?
    assert priya.notes.exists?
    assert priya.meetings.exists?
    assert priya.opportunities.exists?

    assert_no_difference "Lead.where(\"email LIKE '%@demo.leadflow.local'\").count" do
      DemoSeeds.enrich_presentation_catalog!(
        team: @team,
        us: @us,
        cr: @cr,
        advisor: advisor,
        admin: admin
      )
    end
  end

  test "seed_dashboard_sample_data assigns leads to advisor on empty CRM" do
    Lead.destroy_all

    advisor = users(:advisor)
    admin = users(:admin)

    DemoSeeds.seed_dashboard_sample_data(
      team: @team,
      us: @us,
      cr: @cr,
      advisor: advisor,
      admin: admin
    )

    assert advisor.leads.exists?
    assert_operator advisor.leads.count, :>=, 1
  end

  test "seed_dashboard_sample_data ensures advisor lead when other leads already exist" do
    advisor = users(:advisor)
    admin = users(:admin)
    advisor.leads.update_all(user_id: admin.id)
    assert Lead.exists?
    refute advisor.leads.exists?

    DemoSeeds.seed_dashboard_sample_data(
      team: @team,
      us: @us,
      cr: @cr,
      advisor: advisor,
      admin: admin
    )

    assert advisor.leads.exists?
    assert Lead.exists?(email: DemoSeeds::ADVISOR_ENSURE_LEAD_EMAIL, user_id: advisor.id)
  end

  test "ensure_advisor_assigned_lead reclaims reserved email with demo attrs" do
    advisor = users(:advisor)
    admin = users(:admin)
    advisor.leads.update_all(user_id: admin.id)

    stale = Lead.create!(
      name: "Wrong Owner",
      email: DemoSeeds::ADVISOR_ENSURE_LEAD_EMAIL,
      stage: lead_stages(:prospect),
      user: admin,
      team: @team,
      company: companies(:acme),
      country: @cr
    )

    DemoSeeds.ensure_advisor_assigned_lead!(team: @team, us: @us, advisor: advisor)
    stale.reload

    assert_equal advisor.id, stale.user_id
    assert_equal @team.id, stale.team_id
    assert_equal @us.id, stale.country_id
    assert_equal "Demo Advisor Lead", stale.name
    assert_equal lead_stages(:qualified).id, stale.stage_id
    assert_equal "TechNova Inc", stale.company.name
  end

  test "ensure_advisor_assigned_lead is a no-op when advisor already has leads" do
    advisor = users(:advisor)
    assert advisor.leads.exists?

    assert_no_difference "Lead.count" do
      DemoSeeds.ensure_advisor_assigned_lead!(team: @team, us: @us, advisor: advisor)
    end
  end
end
