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

  test "admin can filter by stage" do
    sign_in_as users(:admin)

    get leads_path, params: { stage_id: lead_stages(:qualified).id }

    assert_response :success
    assert_includes response.body, leads(:sarah).name
    refute_includes response.body, leads(:marcus).name
    assert_includes response.body, "\"stage_id\":#{lead_stages(:qualified).id}"
  end

  test "admin can filter by assignee" do
    sign_in_as users(:admin)

    get leads_path, params: { user_id: users(:advisor).id }

    assert_response :success
    assert_includes response.body, leads(:sarah).name
    assert_includes response.body, leads(:marcus).name
    refute_includes response.body, leads(:admin_owned).name
    assert_includes response.body, "\"user_id\":#{users(:advisor).id}"
    assert_includes response.body, '"can_filter_assignee":true'
  end

  test "admin can combine stage and assignee filters" do
    sign_in_as users(:admin)

    get leads_path, params: {
      stage_id: lead_stages(:prospect).id,
      user_id: users(:advisor).id
    }

    assert_response :success
    assert_includes response.body, leads(:marcus).name
    refute_includes response.body, leads(:sarah).name
    refute_includes response.body, leads(:admin_owned).name
  end

  test "advisor stage filter stays within assigned leads" do
    sign_in_as users(:advisor)

    get leads_path, params: { stage_id: lead_stages(:prospect).id }

    assert_response :success
    assert_includes response.body, leads(:marcus).name
    refute_includes response.body, leads(:sarah).name
    refute_includes response.body, leads(:admin_owned).name
    assert_includes response.body, '"can_filter_assignee":false'
  end

  test "advisor user_id param does not expand scope" do
    sign_in_as users(:advisor)

    get leads_path, params: { user_id: users(:admin).id }

    assert_response :success
    assert_includes response.body, leads(:sarah).name
    refute_includes response.body, leads(:admin_owned).name
    assert_includes response.body, '"user_id":null'
  end

  test "invalid stage_id is ignored" do
    sign_in_as users(:admin)

    get leads_path, params: { stage_id: "abc" }

    assert_response :success
    assert_includes response.body, '"stage_id":null'
    assert_includes response.body, leads(:sarah).name
  end

  test "nonexistent stage_id is ignored" do
    sign_in_as users(:admin)

    get leads_path, params: { stage_id: 0 }

    assert_response :success
    assert_includes response.body, '"stage_id":null'
    assert_includes response.body, leads(:sarah).name
    assert_includes response.body, leads(:marcus).name
  end

  test "admin non-assignable user_id is ignored" do
    sign_in_as users(:admin)

    get leads_path, params: { user_id: users(:assistant).id }

    assert_response :success
    assert_includes response.body, '"user_id":null'
    assert_includes response.body, leads(:sarah).name
    assert_includes response.body, leads(:admin_owned).name
  end

  test "admin disabled assignee user_id is ignored" do
    users(:advisor).update!(status: "disabled")
    sign_in_as users(:admin)

    get leads_path, params: { user_id: users(:advisor).id }

    assert_response :success
    assert_includes response.body, '"user_id":null'
    assert_includes response.body, leads(:sarah).name
    assert_includes response.body, leads(:admin_owned).name
  end

  test "assistant can filter by stage" do
    sign_in_as users(:assistant)

    get leads_path, params: { stage_id: lead_stages(:qualified).id }

    assert_response :success
    assert_includes response.body, leads(:sarah).name
    refute_includes response.body, leads(:marcus).name
    assert_includes response.body, '"can_filter_assignee":false'
    assert_includes response.body, '"user_id":null'
  end

  test "array stage_id param does not crash" do
    sign_in_as users(:admin)

    get leads_path, params: { stage_id: [ lead_stages(:qualified).id ] }

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
    assert_redirected_to lead_path(lead)
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
    assert_redirected_to lead_path(lead)
  end

  test "company name variants reuse existing company without updating country" do
    sign_in_as users(:advisor)
    existing = companies(:acme)
    original_country_id = existing.country_id

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
    assert_equal original_country_id, existing.reload.country_id
  end

  test "checkbox updates existing company country on reuse" do
    sign_in_as users(:advisor)
    existing = companies(:acme)

    post leads_path, params: valid_lead_params.merge(
      email: "acme.update-country@example.com",
      company_name: "ACME CORP.",
      company_country_id: countries(:cr).id,
      update_existing_company_country: true
    )

    assert_redirected_to lead_path(Lead.find_by!(email: "acme.update-country@example.com"))
    assert_equal countries(:cr).id, existing.reload.country_id
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
    follow_redirect!
    assert_includes response.body, '"company_name"'
    assert_includes response.body, "can't be blank"
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
    follow_redirect!
    assert_includes response.body, "already belongs to another lead"
    assert_equal "Sarah Jenkins", leads(:sarah).reload.name
  end

  test "checkbox without company country rejects update request" do
    sign_in_as users(:advisor)

    assert_no_difference "Lead.count" do
      post leads_path, params: valid_lead_params.merge(
        email: "acme.blank-update@example.com",
        company_name: "ACME CORP.",
        company_country_id: "",
        update_existing_company_country: true
      )
    end

    assert_redirected_to new_lead_path
    follow_redirect!
    assert_includes response.body, "company_country_id"
  end

  test "admin blank assignee is rejected with user_id error" do
    sign_in_as users(:admin)

    assert_no_difference "Lead.count" do
      post leads_path, params: valid_lead_params.merge(
        email: "needs.assignee@example.com",
        user_id: ""
      )
    end

    assert_redirected_to new_lead_path
    follow_redirect!
    assert_includes response.body, '"user_id"'
  end

  test "admin unallowlisted assignee is rejected" do
    sign_in_as users(:admin)

    assert_no_difference "Lead.count" do
      post leads_path, params: valid_lead_params.merge(
        email: "bad.assignee@example.com",
        user_id: users(:assistant).id
      )
    end

    assert_redirected_to new_lead_path
    follow_redirect!
    assert_includes response.body, '"user_id"'
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

  test "edit lead requires authentication" do
    get edit_lead_path(leads(:sarah))

    assert_redirected_to login_path
  end

  test "advisor can edit assigned lead" do
    sign_in_as users(:advisor)

    get edit_lead_path(leads(:sarah))

    assert_response :success
    assert_includes response.body, '"component":"leads/edit"'
    assert_includes response.body, leads(:sarah).email
  end

  test "advisor cannot edit unassigned lead" do
    sign_in_as users(:advisor)

    get edit_lead_path(leads(:admin_owned))

    assert_response :not_found
  end

  test "assistant cannot edit lead" do
    sign_in_as users(:assistant)

    get edit_lead_path(leads(:sarah))

    assert_redirected_to root_path
    assert_equal "You are not authorized to perform this action.", flash[:alert]
  end

  test "advisor updates assigned lead" do
    sign_in_as users(:advisor)
    lead = leads(:marcus)

    patch lead_path(lead), params: valid_lead_params.merge(
      name: "Marcus Updated",
      email: lead.email,
      company_name: lead.company.name,
      company_country_id: lead.company.country_id,
      country_id: lead.country_id,
      stage_id: lead.stage_id,
      user_id: users(:admin).id
    )

    assert_redirected_to lead_path(lead)
    assert_equal "Lead updated.", flash[:notice]
    lead.reload
    assert_equal "Marcus Updated", lead.name
    assert_equal users(:advisor).id, lead.user_id
  end

  test "advisor cannot update unassigned lead" do
    sign_in_as users(:advisor)

    patch lead_path(leads(:admin_owned)), params: valid_lead_params.merge(
      email: "should.not@example.com"
    )

    assert_response :not_found
    refute_equal "should.not@example.com", leads(:admin_owned).reload.email
  end

  test "assistant cannot update lead" do
    sign_in_as users(:assistant)

    patch lead_path(leads(:sarah)), params: valid_lead_params.merge(
      email: leads(:sarah).email,
      name: "Hacked"
    )

    assert_redirected_to root_path
    assert_equal "Sarah Jenkins", leads(:sarah).reload.name
  end

  test "update rejects duplicate email belonging to another lead" do
    sign_in_as users(:advisor)
    lead = leads(:marcus)

    patch lead_path(lead), params: valid_lead_params.merge(
      email: "SARAH@EXAMPLE.COM",
      company_name: lead.company.name,
      company_country_id: lead.company.country_id,
      country_id: lead.country_id,
      stage_id: lead.stage_id
    )

    assert_redirected_to edit_lead_path(lead)
    follow_redirect!
    assert_includes response.body, "already belongs to another lead"
    assert_equal "marcus@example.com", lead.reload.email
  end

  test "update reuses company by normalized name" do
    sign_in_as users(:advisor)
    lead = leads(:marcus)
    existing = companies(:technova)

    assert_no_difference "Company.count" do
      patch lead_path(lead), params: valid_lead_params.merge(
        email: lead.email,
        company_name: "TECHNOVA SOLUTIONS",
        company_country_id: countries(:cr).id,
        country_id: lead.country_id,
        stage_id: lead.stage_id
      )
    end

    assert_redirected_to lead_path(lead)
    assert_equal existing.id, lead.reload.company_id
    assert_equal countries(:us).id, existing.reload.country_id
  end

  test "index includes can_update per lead for advisor" do
    sign_in_as users(:advisor)

    get leads_path

    assert_response :success
    assert_includes response.body, '"can_update":true'
  end

  test "admin can edit and reassign lead" do
    sign_in_as users(:admin)
    lead = leads(:sarah)

    get edit_lead_path(lead)

    assert_response :success
    assert_includes response.body, '"component":"leads/edit"'
    assert_includes response.body, lead.email

    patch lead_path(lead), params: valid_lead_params.merge(
      name: "Sarah Reassigned",
      email: lead.email,
      company_name: lead.company.name,
      company_country_id: lead.company.country_id,
      country_id: lead.country_id,
      stage_id: lead.stage_id,
      user_id: users(:admin).id
    )

    assert_redirected_to lead_path(lead)
    assert_equal "Lead updated.", flash[:notice]
    lead.reload
    assert_equal "Sarah Reassigned", lead.name
    assert_equal users(:admin).id, lead.user_id
  end

  test "update can opt in to change existing company country" do
    sign_in_as users(:advisor)
    lead = leads(:marcus)
    company = companies(:acme)
    assert_equal company.id, lead.company_id

    patch lead_path(lead), params: valid_lead_params.merge(
      email: lead.email,
      company_name: "ACME CORP.",
      company_country_id: countries(:cr).id,
      update_existing_company_country: true,
      country_id: lead.country_id,
      stage_id: lead.stage_id
    )

    assert_redirected_to lead_path(lead)
    assert_equal countries(:cr).id, company.reload.country_id
  end

  test "index shows can_update false for assistant" do
    sign_in_as users(:assistant)

    get leads_path

    assert_response :success
    assert_includes response.body, '"can_update":false'
    refute_includes response.body, '"can_update":true'
  end

  test "update rejects non-numeric estimated_value" do
    sign_in_as users(:advisor)
    lead = leads(:marcus)

    assert_no_changes -> { lead.reload.estimated_value } do
      patch lead_path(lead), params: valid_lead_params.merge(
        email: lead.email,
        company_name: lead.company.name,
        company_country_id: lead.company.country_id,
        country_id: lead.country_id,
        stage_id: lead.stage_id,
        estimated_value: "not-a-number"
      )
    end

    assert_redirected_to edit_lead_path(lead)
    follow_redirect!
    assert_includes response.body, "estimated_value"
  end

  test "update preserves phone when phone key omitted" do
    sign_in_as users(:advisor)
    lead = leads(:sarah)
    original_phone = lead.phone
    assert_predicate original_phone, :present?

    patch lead_path(lead), params: valid_lead_params.merge(
      name: lead.name,
      email: lead.email,
      company_name: lead.company.name,
      company_country_id: lead.company.country_id,
      country_id: lead.country_id,
      stage_id: lead.stage_id
    ).except(:phone)

    assert_redirected_to lead_path(lead)
    assert_equal original_phone, lead.reload.phone
  end

  test "show lead requires authentication" do
    get lead_path(leads(:sarah))

    assert_redirected_to login_path
  end

  test "advisor can show assigned lead with related previews" do
    sign_in_as users(:advisor)
    lead = leads(:sarah)

    get lead_path(lead)

    assert_response :success
    assert_includes response.body, '"component":"leads/show"'
    assert_includes response.body, lead.email
    assert_includes response.body, lead.phone
    assert_includes response.body, lead.company.name
    assert_includes response.body, lead.country.name
    assert_includes response.body, lead.stage.name
    assert_includes response.body, lead.user.name
    assert_includes response.body, '"can_update":true'
    assert_includes response.body, '"can_create_task":true'
    assert_includes response.body, '"can_create_note":true'
    assert_includes response.body, '"truncated":false'
    assert_includes response.body, '"showing":1'
    assert_includes response.body, '"count":1'
    assert_includes response.body, tasks(:follow_up).title
    assert_includes response.body, '"can_complete":true'
    assert_includes response.body, meetings(:review).title
    assert_includes response.body, "Successful discovery call"
    assert_includes response.body, '"content":'
    assert_includes response.body, opportunities(:migration).title
  end

  test "advisor cannot show unassigned lead" do
    sign_in_as users(:advisor)

    get lead_path(leads(:admin_owned))

    assert_response :not_found
  end

  test "assistant can show lead read-only" do
    sign_in_as users(:assistant)

    get lead_path(leads(:sarah))

    assert_response :success
    assert_includes response.body, '"component":"leads/show"'
    assert_includes response.body, '"can_update":false'
    assert_includes response.body, '"can_create_task":true'
    assert_includes response.body, '"can_create_note":true'
  end

  test "admin can show any lead" do
    sign_in_as users(:admin)

    get lead_path(leads(:sarah))

    assert_response :success
    assert_includes response.body, '"component":"leads/show"'
    assert_includes response.body, '"can_update":true'
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
