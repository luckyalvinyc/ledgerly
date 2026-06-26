# frozen_string_literal: true

require "test_helper"

class UserSignInTest < ActionDispatch::IntegrationTest
  test "correct details sign the owner in" do
    user = User.create!(
      email: "john@doe.com",
      password: "SomePassw0rd!"
    )

    post session_path, params: {
      email: user.email,
      password: user.password
    }

    follow_redirect!

    get root_path
    assert_response :success
  end

  test "unknown details cannot sign in" do
    post session_path, params: {
      email: "john@doe.com",
      password:  "SomePassw0rd!"
    }

    assert_response :unprocessable_content
    assert_equal "Invalid email or password", flash[:alert]
  end
end
