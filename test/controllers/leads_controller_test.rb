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
end
