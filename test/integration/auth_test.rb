# frozen_string_literal: true

require "test_helper"

class AuthTest < ActionDispatch::IntegrationTest
  test "signed-out visitors must sign in first" do
    get root_path
    assert_redirected_to new_session_path
  end

  test "signing out ends the session and locks the app" do
    user = sign_in
    assert_equal 1, user.sessions.count

    delete session_path
    assert_redirected_to new_session_path
    assert_equal 0, user.sessions.reload.count

    get root_path
    assert_redirected_to new_session_path
  end

  test "an idle session signs the owner out" do
    user = sign_in

    travel 16.minutes do
      get root_path
      assert_redirected_to new_session_path
    end

    assert_equal 0, user.sessions.reload.count
  end

  test "a failed sign in never says which detail was wrong" do
    post session_path, params: {
      email: "nobody@no.body",
      password: "SomePassw0rd@"
    }
    assert_response :unprocessable_content
    wrong_email = flash[:alert]

    user = users(:lucky)

    post session_path, params: {
      email: user.email,
      password: "SomeWrongPassw0rd@"
    }
    assert_response :unprocessable_content
    wrong_password = flash[:alert]

    assert_equal "Invalid email or password", wrong_email
    assert_equal wrong_email, wrong_password
  end
end
