# frozen_string_literal: true

require "test_helper"

class Admin::SessionsTest < ActionDispatch::IntegrationTest
  test "an admin signs in through the admin page" do
    post admin_session_path, params: { email: users(:admin).email, password: "SomePassw0rd@" }

    assert_redirected_to admin_root_path
    assert_not_nil cookies.get_cookie("__Host-session_token")
  end

  test "a customer cannot sign in through the admin page" do
    post admin_session_path, params: { email: users(:lucky).email, password: "SomePassw0rd@" }

    assert_response :unprocessable_content
    assert_nil cookies.get_cookie("__Host-session_token")
  end

  test "an admin cannot sign in through the customer page" do
    post session_path, params: { email: users(:admin).email, password: "SomePassw0rd@" }

    assert_response :unprocessable_content
    assert_nil cookies.get_cookie("__Host-session_token")
  end

  test "a customer reaching the admin area lands on the admin sign in" do
    sign_in(users(:lucky))

    get admin_root_path

    assert_redirected_to admin_new_session_path
  end

  test "an admin is kept out of the customer area" do
    admin_sign_in

    get root_path

    assert_redirected_to admin_root_path
  end
end
