# frozen_string_literal: true

require "test_helper"

class AssistantsControllerTest < ActionDispatch::IntegrationTest
  test "advisor can index assigned assistants" do
    sign_in_as users(:advisor)

    get assistants_path

    assert_response :success
    assert_includes response.body, '"component":"assistants/index"'
    assert_includes response.body, users(:assistant).name
    assert_includes response.body, '"can_manage":true'
    assert_includes response.body, '"per_page":25'
  end

  test "assistant cannot manage assistants" do
    sign_in_as users(:assistant)

    get assistants_path

    assert_redirected_to root_path
  end

  test "advisor can assign and remove an assistant" do
    sign_in_as users(:advisor)
    AdvisorAssistant.delete_all
    other = User.create!(
      name: "Pat Helper",
      email: "pat.helper@example.com",
      password: "password",
      role: roles(:assistant),
      team: teams(:enterprise),
      country: countries(:us),
      status: "active"
    )

    assert_difference "AdvisorAssistant.count", 1 do
      post assistants_path, params: { assistant_id: other.id }
    end

    assignment = AdvisorAssistant.order(:id).last
    assert_equal users(:advisor).id, assignment.advisor_id
    assert_equal other.id, assignment.assistant_id
    assert_redirected_to assistants_path(advisor_id: users(:advisor).id)

    assert_difference "AdvisorAssistant.count", -1 do
      delete assistant_path(assignment)
    end

    assert_redirected_to assistants_path(advisor_id: users(:advisor).id)
  end

  test "admin can manage assistants for a selected advisor" do
    sign_in_as users(:admin)
    AdvisorAssistant.delete_all

    get assistants_path, params: { advisor_id: users(:advisor).id }

    assert_response :success
    assert_includes response.body, users(:advisor).name
    assert_includes response.body, '"can_manage":true'

    assert_difference "AdvisorAssistant.count", 1 do
      post assistants_path, params: {
        advisor_id: users(:advisor).id,
        assistant_id: users(:assistant).id
      }
    end

    assert_redirected_to assistants_path(advisor_id: users(:advisor).id)
  end
end
