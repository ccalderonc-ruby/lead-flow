# frozen_string_literal: true

require "test_helper"

class LeadsControllerTest < ActionDispatch::IntegrationTest
  test "leads index requires authentication" do
    get leads_path

    assert_redirected_to login_path
  end

  test "advisor only sees assigned leads" do
    sign_in_as users(:advisor)

    get leads_path

    assert_response :success
    assert_includes response.body, leads(:sarah).name
    assert_includes response.body, leads(:marcus).name
    assert_includes response.body, leads(:closed_lead).name
    refute_includes response.body, leads(:admin_owned).name
  end

  test "admin sees all leads" do
    sign_in_as users(:admin)

    get leads_path

    assert_response :success
    assert_includes response.body, leads(:sarah).name
    assert_includes response.body, leads(:admin_owned).name
  end

  test "search filters by name email or company" do
    sign_in_as users(:advisor)

    get leads_path, params: { q: "technova" }

    assert_response :success
    assert_includes response.body, leads(:sarah).name
    refute_includes response.body, leads(:marcus).name
  end

  test "search by email finds matching lead" do
    sign_in_as users(:advisor)

    get leads_path, params: { q: "marcus@example.com" }

    assert_response :success
    assert_includes response.body, leads(:marcus).name
    refute_includes response.body, leads(:sarah).name
  end

  test "whitespace-only search returns all scoped leads" do
    sign_in_as users(:advisor)

    get leads_path, params: { q: "   " }

    assert_response :success
    assert_includes response.body, leads(:sarah).name
    assert_includes response.body, leads(:marcus).name
  end

  test "pagination meta uses 25 per page and clamps out-of-range pages" do
    sign_in_as users(:admin)

    get leads_path, params: { page: 999 }

    assert_response :success
    assert_includes response.body, '"per_page":25'
    assert_includes response.body, '"page":1'
  end

  test "array page param does not crash" do
    sign_in_as users(:advisor)

    get leads_path, params: { page: [ "2" ] }

    assert_response :success
  end

  test "assistant sees organization-wide leads" do
    sign_in_as users(:assistant)

    get leads_path

    assert_response :success
    assert_includes response.body, leads(:sarah).name
    assert_includes response.body, leads(:admin_owned).name
  end

  test "search is case-insensitive for company and email" do
    sign_in_as users(:advisor)

    get leads_path, params: { q: "TECHNOVA" }

    assert_response :success
    assert_includes response.body, leads(:sarah).name
    refute_includes response.body, leads(:marcus).name

    get leads_path, params: { q: "MARCUS@EXAMPLE.COM" }

    assert_response :success
    assert_includes response.body, leads(:marcus).name
    refute_includes response.body, leads(:sarah).name
  end

  test "array search param does not crash" do
    sign_in_as users(:advisor)

    get leads_path, params: { q: [ "sarah" ] }

    assert_response :success
    assert_includes response.body, leads(:sarah).name
  end

  test "new lead form requires authentication" do
    get new_lead_path

    assert_redirected_to login_path
  end

  test "advisor can open new lead form" do
    sign_in_as users(:advisor)

    get new_lead_path

    assert_response :success
    assert_includes response.body, '"component":"leads/new"'
    assert_includes response.body, '"force_assignee":true'
  end

  test "assistant is denied new lead form" do
    sign_in_as users(:assistant)

    get new_lead_path

    assert_redirected_to root_path
    assert_equal "You are not authorized to perform this action.", flash[:alert]
  end

  test "advisor creates lead assigned to self" do
    sign_in_as users(:advisor)

    assert_difference "Lead.count", 1 do
      post leads_path, params: valid_lead_params.merge(user_id: users(:admin).id)
    end

    lead = Lead.order(:id).last
    assert_equal users(:advisor).id, lead.user_id
    assert_equal "new.prospect@example.com", lead.email
    assert_redirected_to leads_path
    assert_equal "Lead created.", flash[:notice]
  end

  test "admin can assign lead to an advisor" do
    sign_in_as users(:admin)

    assert_difference "Lead.count", 1 do
      post leads_path, params: valid_lead_params.merge(
        email: "admin.created@example.com",
        user_id: users(:advisor).id
      )
    end

    lead = Lead.find_by!(email: "admin.created@example.com")
    assert_equal users(:advisor).id, lead.user_id
  end

  test "company name variants reuse existing company" do
    sign_in_as users(:advisor)
    existing = companies(:acme)

    assert_no_difference "Company.count" do
      assert_difference "Lead.count", 1 do
        post leads_path, params: valid_lead_params.merge(
          email: "acme.variant@example.com",
          company_name: "ACME CORP.",
          company_country_id: countries(:cr).id
        )
      end
    end

    lead = Lead.find_by!(email: "acme.variant@example.com")
    assert_equal existing.id, lead.company_id
  end

  test "missing required fields redirect with inertia errors" do
    sign_in_as users(:advisor)

    assert_no_difference "Lead.count" do
      post leads_path, params: {
        name: "",
        email: "",
        company_name: "",
        company_country_id: "",
        country_id: "",
        stage_id: ""
      }
    end

    assert_redirected_to new_lead_path
  end

  test "duplicate email is rejected without creating lead" do
    sign_in_as users(:advisor)

    assert_no_difference "Lead.count" do
      post leads_path, params: valid_lead_params.merge(
        email: "SARAH@EXAMPLE.COM",
        name: "Duplicate Sarah"
      )
    end

    assert_redirected_to new_lead_path
    assert_equal "Sarah Jenkins", leads(:sarah).reload.name
  end

  test "assistant cannot create lead" do
    sign_in_as users(:assistant)

    assert_no_difference "Lead.count" do
      post leads_path, params: valid_lead_params
    end

    assert_redirected_to root_path
  end

  test "index shows can_create for advisor but not assistant" do
    sign_in_as users(:advisor)
    get leads_path
    assert_response :success
    assert_includes response.body, '"can_create":true'

    delete logout_path
    sign_in_as users(:assistant)
    get leads_path
    assert_response :success
    assert_includes response.body, '"can_create":false'
  end

  private

  def valid_lead_params
    {
      name: "New Prospect",
      email: "new.prospect@example.com",
      phone: "555-0199",
      estimated_value: "12000",
      company_name: "Brand New Co",
      company_country_id: countries(:us).id,
      country_id: countries(:us).id,
      stage_id: lead_stages(:prospect).id,
      user_id: users(:advisor).id
    }
  end
end
