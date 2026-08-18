# frozen_string_literal: true

require "test_helper"

class DashboardMetricsTest < ActiveSupport::TestCase
  setup do
    travel_to Date.new(2026, 7, 5)
  end

  teardown do
    travel_back
  end

  test "advisor metrics reflect assigned records only" do
    payload = DashboardMetrics.new(users(:advisor)).call
    metrics = payload[:metrics]

    assert_equal 2, metrics[:open_leads]
    assert_equal 1, metrics[:active_opportunities]
    assert_equal 2, metrics[:overdue_tasks]
    assert_equal 1, metrics[:upcoming_meetings]
    assert_in_delta 32_000.0, metrics[:pipeline_value]
  end

  test "admin metrics reflect organization-wide totals" do
    metrics = DashboardMetrics.new(users(:admin)).call[:metrics]

    assert_equal 3, metrics[:open_leads]
    assert_equal 3, metrics[:overdue_tasks]
    assert_equal 1, metrics[:upcoming_meetings]
    assert_in_delta 32_000.0, metrics[:pipeline_value]
  end

  test "book_only metrics for an admin are that person's owned records" do
    metrics = DashboardMetrics.new(users(:admin), book_only: true).call[:metrics]

    assert_equal 1, metrics[:open_leads]
    refute_equal DashboardMetrics.new(users(:admin)).call[:metrics][:open_leads], metrics[:open_leads]
  end

  test "assistant metrics match assigned-advisor scope" do
    assistant_payload = DashboardMetrics.new(users(:assistant)).call
    advisor_payload = DashboardMetrics.new(users(:advisor)).call

    assert_equal advisor_payload[:metrics], assistant_payload[:metrics]
  end

  test "closed leads and won opportunities are excluded" do
    metrics = DashboardMetrics.new(users(:advisor)).call[:metrics]

    refute_includes LeadPolicy::Scope.new(users(:advisor), Lead).resolve.merge(Lead.open).pluck(:name),
                    leads(:closed_lead).name

    assert metrics[:pipeline_value] < 99_999.0
  end

  test "recent leads and pipeline stages are scoped" do
    payload = DashboardMetrics.new(users(:advisor)).call

    assert payload[:recent_leads].any? { |row| row[:name] == leads(:sarah).name }
    refute payload[:recent_leads].any? { |row| row[:name] == leads(:admin_owned).name }

    proposal = payload[:pipeline_stages].find { |row| row[:name] == "Proposal" }
    assert proposal
    assert_equal 1, proposal[:count]
    assert_in_delta 32_000.0, proposal[:value]
  end

  test "upcoming activities include scoped meetings with detail fields" do
    activities = DashboardMetrics.new(users(:advisor)).call[:upcoming_activities]
    meeting_row = activities.find { |row| row[:title] == meetings(:review).title && row[:kind] == "meeting" }

    assert meeting_row
    assert_equal meetings(:review).id, meeting_row[:id]
    assert_equal meetings(:review).lead_id, meeting_row[:lead_id]
    assert_equal true, meeting_row[:can_edit]
    assert meeting_row[:scheduled_on].present?
    assert meeting_row[:start_time].present?
  end

  test "activity days filter limits the upcoming window" do
    # Fixture meeting is on 2026-07-10; from 2026-07-05 that is 5 days ahead.
    today_only = DashboardMetrics.new(users(:advisor), activity_days: 0).call[:upcoming_activities]
    week = DashboardMetrics.new(users(:advisor), activity_days: 7).call[:upcoming_activities]

    refute today_only.any? { |row| row[:title] == meetings(:review).title }
    assert week.any? { |row| row[:title] == meetings(:review).title }
  end

  test "normalize_activity_days falls back to default" do
    assert_equal 7, DashboardMetrics.normalize_activity_days(nil)
    assert_equal 7, DashboardMetrics.normalize_activity_days("nope")
    assert_equal 3, DashboardMetrics.normalize_activity_days("3")
  end

  test "recent leads can be filtered by stage" do
    qualified = lead_stages(:qualified)
    payload = DashboardMetrics.new(users(:advisor), lead_stage_id: qualified.id).call

    assert payload[:recent_leads].any? { |row| row[:name] == leads(:sarah).name }
    refute payload[:recent_leads].any? { |row| row[:name] == leads(:marcus).name }
    assert_equal qualified.id, payload[:lead_stage_id]
  end
end
