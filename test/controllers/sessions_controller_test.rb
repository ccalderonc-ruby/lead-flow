require "test_helper"

class SessionsControllerTest < ActionDispatch::IntegrationTest
  test "login page is reachable when signed out" do
    get login_path
    assert_response :success
  end

  test "sign in with valid credentials" do
    post session_path, params: { email: users(:admin).email, password: "password" }

    assert_redirected_to root_path
    follow_redirect!
    assert_response :success

    get root_path
    assert_response :success
  end

  test "sign in with invalid credentials" do
    post session_path, params: { email: users(:admin).email, password: "wrong" }

    assert_redirected_to login_path
    follow_redirect!
    assert_response :success
  end

  test "sign out clears session" do
    post session_path, params: { email: users(:admin).email, password: "password" }
    delete logout_path

    assert_redirected_to login_path
    get root_path
    assert_redirected_to login_path
  end

  test "root requires authentication" do
    get root_path
    assert_redirected_to login_path
  end

  test "signed in user visiting login is redirected home" do
    post session_path, params: { email: users(:admin).email, password: "password" }
    get login_path

    assert_redirected_to root_path
  end
end
