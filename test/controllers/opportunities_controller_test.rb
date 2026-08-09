# frozen_string_literal: true

require "test_helper"

class OpportunitiesControllerTest < ActionDispatch::IntegrationTest
  test "opportunities index requires authentication" do
    get opportunities_path

    assert_redirected_to login_path
  end

  test "advisor sees only opportunities on assigned leads" do
    sign_in_as users(:advisor)
    opportunity = opportunities(:migration)

    get opportunities_path

    assert_response :success
    assert_includes response.body, '"component":"opportunities/index"'
    assert_includes response.body, opportunity.title
    assert_includes response.body, '"stages"'
    assert_includes response.body, opportunity_stages(:prospect).name
    assert_includes response.body, opportunity_stages(:proposal).name
    assert_includes response.body, opportunity_stages(:won).name
    assert_includes response.body, opportunity_stages(:lost).name
    assert_includes response.body, "\"value\":\"#{opportunity.value}\""
    assert_includes response.body, "\"lead_id\":#{opportunity.lead_id}"
    refute_includes response.body, opportunities(:won_deal).title
  end

  test "empty stages still serialize an opportunities array" do
    sign_in_as users(:advisor)

    get opportunities_path

    assert_response :success
    # Prospect has no advisor-scoped opportunities in fixtures; empty arrays still appear.
    assert_includes response.body, '"name":"Prospect"'
    assert_includes response.body, '"opportunities":[]'
  end

  test "admin sees opportunities across leads" do
    sign_in_as users(:admin)

    get opportunities_path

    assert_response :success
    assert_includes response.body, opportunities(:migration).title
    assert_includes response.body, opportunities(:won_deal).title
  end

  test "assistant can view pipeline read-only" do
    sign_in_as users(:assistant)

    get opportunities_path

    assert_response :success
    assert_includes response.body, opportunities(:migration).title
    assert_includes response.body, opportunities(:won_deal).title
  end

  test "stages are ordered by position" do
    sign_in_as users(:advisor)

    get opportunities_path

    assert_response :success
    prospect_at = response.body.index('"name":"Prospect"')
    proposal_at = response.body.index('"name":"Proposal"')
    won_at = response.body.index('"name":"Won"')
    lost_at = response.body.index('"name":"Lost"')

    assert prospect_at
    assert proposal_at
    assert won_at
    assert lost_at
    assert_operator prospect_at, :<, proposal_at
    assert_operator proposal_at, :<, won_at
    assert_operator won_at, :<, lost_at
  end

  test "opportunity appears under its stage column" do
    sign_in_as users(:advisor)
    opportunity = opportunities(:migration)
    stage = opportunity.stage

    get opportunities_path

    assert_response :success
    # Stage payload includes nested opportunity title near stage id
    assert_includes response.body, "\"id\":#{stage.id}"
    assert_includes response.body, opportunity.title
    assert_includes response.body, "\"stage_id\":#{stage.id}"
  end

  test "index payload includes description can_update and stage_options" do
    sign_in_as users(:advisor)
    opportunity = opportunities(:migration)

    get opportunities_path

    assert_response :success
    assert_includes response.body, '"stage_options"'
    assert_includes response.body, "\"description\":\"#{opportunity.description}\""
    assert_includes response.body, '"can_update":true'
  end

  test "assistant index marks opportunities can_update false" do
    sign_in_as users(:assistant)

    get opportunities_path

    assert_response :success
    assert_includes response.body, '"can_update":false,"can_create_note":true'
    refute_includes response.body, '"can_update":true,"can_create_note"'
  end

  test "advisor updates stage on assigned opportunity" do
    sign_in_as users(:advisor)
    opportunity = opportunities(:migration)
    won = opportunity_stages(:won)

    patch opportunity_path(opportunity), params: {
      title: opportunity.title,
      value: opportunity.value.to_s,
      stage_id: won.id,
      close_date: opportunity.close_date.iso8601,
      description: opportunity.description
    }

    assert_redirected_to opportunities_path
    assert_equal "Opportunity updated.", flash[:notice]
    assert_equal won.id, opportunity.reload.stage_id
  end

  test "advisor cannot update unassigned opportunity" do
    sign_in_as users(:advisor)
    opportunity = opportunities(:won_deal)

    patch opportunity_path(opportunity), params: {
      title: "Hijacked",
      stage_id: opportunity.stage_id
    }

    assert_response :not_found
    assert_equal "Closed Won Deal", opportunity.reload.title
  end

  test "assistant cannot update opportunity" do
    sign_in_as users(:assistant)
    opportunity = opportunities(:migration)
    original_stage = opportunity.stage_id

    patch opportunity_path(opportunity), params: {
      title: opportunity.title,
      value: opportunity.value.to_s,
      stage_id: opportunity_stages(:won).id,
      description: opportunity.description
    }

    assert_redirected_to root_path
    assert_equal "You are not authorized to perform this action.", flash[:alert]
    assert_equal original_stage, opportunity.reload.stage_id
  end

  test "blank title returns inertia errors" do
    sign_in_as users(:advisor)
    opportunity = opportunities(:migration)

    patch opportunity_path(opportunity), params: {
      title: "",
      value: opportunity.value.to_s,
      stage_id: opportunity.stage_id,
      description: opportunity.description
    }

    assert_redirected_to opportunities_path
    follow_redirect!
    assert_includes response.body, "title"
    assert_includes response.body, '"form":["opportunity"]'
    assert_equal "CRM Migration", opportunity.reload.title
  end

  test "omitted value and stage_id leave existing attributes unchanged" do
    sign_in_as users(:advisor)
    opportunity = opportunities(:migration)
    original_value = opportunity.value
    original_stage = opportunity.stage_id

    patch opportunity_path(opportunity), params: {
      title: "Renamed Migration",
      description: "Partial update"
    }

    assert_redirected_to opportunities_path
    opportunity.reload
    assert_equal "Renamed Migration", opportunity.title
    assert_equal "Partial update", opportunity.description
    assert_equal original_value, opportunity.value
    assert_equal original_stage, opportunity.stage_id
  end

  test "value zero returns inertia errors and keeps stage" do
    sign_in_as users(:advisor)
    opportunity = opportunities(:migration)
    original_stage = opportunity.stage_id

    patch opportunity_path(opportunity), params: {
      title: opportunity.title,
      value: "0",
      stage_id: opportunity.stage_id,
      close_date: opportunity.close_date.iso8601,
      description: opportunity.description
    }

    assert_redirected_to opportunities_path
    follow_redirect!
    assert_includes response.body, "value"
    assert_includes response.body, '"form":["opportunity"]'
    assert_includes response.body, "\"opportunity_id\":[#{opportunity.id}]"
    assert_equal original_stage, opportunity.reload.stage_id
  end

  test "negative value returns inertia errors" do
    sign_in_as users(:advisor)
    opportunity = opportunities(:migration)

    patch opportunity_path(opportunity), params: {
      title: opportunity.title,
      value: "-10",
      stage_id: opportunity.stage_id,
      description: opportunity.description
    }

    assert_redirected_to opportunities_path
    follow_redirect!
    assert_includes response.body, "value"
    assert_equal 32000.0, opportunity.reload.value
  end

  test "invalid stage_id returns inertia errors" do
    sign_in_as users(:advisor)
    opportunity = opportunities(:migration)

    patch opportunity_path(opportunity), params: {
      title: opportunity.title,
      value: opportunity.value.to_s,
      stage_id: 0,
      description: opportunity.description
    }

    assert_redirected_to opportunities_path
    follow_redirect!
    assert_includes response.body, "stage_id"
    assert_equal opportunity_stages(:proposal).id, opportunity.reload.stage_id
  end
end
