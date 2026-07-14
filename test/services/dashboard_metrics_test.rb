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
    metrics = DashboardMetrics.new(users(:advisor)).call

    assert_equal 2, metrics[:open_leads]
    assert_equal 2, metrics[:overdue_tasks]
    assert_equal 1, metrics[:upcoming_meetings]
    assert_in_delta 32_000.0, metrics[:pipeline_value]
  end

  test "admin metrics reflect organization-wide totals" do
    metrics = DashboardMetrics.new(users(:admin)).call

    assert_equal 3, metrics[:open_leads]
    assert_equal 3, metrics[:overdue_tasks]
    assert_equal 1, metrics[:upcoming_meetings]
    assert_in_delta 32_000.0, metrics[:pipeline_value]
  end

  test "assistant metrics match org-wide read scope" do
    metrics = DashboardMetrics.new(users(:assistant)).call

    assert_equal metrics, DashboardMetrics.new(users(:admin)).call
  end

  test "closed leads and won opportunities are excluded" do
    advisor_metrics = DashboardMetrics.new(users(:advisor)).call

    refute_includes LeadPolicy::Scope.new(users(:advisor), Lead).resolve.merge(Lead.open).pluck(:name),
                    leads(:closed_lead).name

    assert advisor_metrics[:pipeline_value] < 99_999.0
  end
end
