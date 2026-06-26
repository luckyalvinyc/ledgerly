# frozen_string_literal: true

require "test_helper"

class UserSignUpTest < ActionDispatch::IntegrationTest
  test "a new owner can sign up" do
    assert_difference -> { User.count }, 1 do
      post users_path, params: {
        user: {
          email: "lucky@example.com",
          password: "SomePassw0rd!"
        }
      }
    end

    follow_redirect!

    get root_path
    assert_response :success
  end

  test "email is stored in a consistent form" do
    post users_path, params: {
      user: {
        email: "luCky@ExamplE.com",
        password: "SomePassw0rd!"
      }
    }

    user = User.find_by(email: "lucky@example.com")
    assert_not_nil user
  end

  test "a malformed email is rejected" do
    assert_no_difference -> { User.count } do
      post users_path, params: {
        user: {
          email: "luckyexample.com",
          password: "SomePassw0rd!"
        }
      }
    end

    assert_response :unprocessable_content
  end

  test "a missing email is rejected" do
    assert_no_difference -> { User.count } do
      post users_path, params: {
        user: {
          email: "",
          password: "SomePassw0rd!"
        }
      }
    end

    assert_response :unprocessable_content
  end

  test "a missing password is rejected" do
    assert_no_difference -> { User.count } do
      post users_path, params: {
        user: {
          email: "lucky@example.com",
          password: ""
        }
      }
    end

    assert_response :unprocessable_content
  end

  test "a short password is rejected" do
    assert_no_difference -> { User.count } do
      post users_path, params: {
        user: {
          email: "lucky@example.com",
          password: "S0mePa!"
        }
      }
    end

    assert_response :unprocessable_content
  end

  test "a password without an uppercase letter is rejected" do
    assert_no_difference -> { User.count } do
      post users_path, params: {
        user: {
          email: "lucky@example.com",
          password: "somepassw0rd!"
        }
      }
    end

    assert_response :unprocessable_content
  end

  test "a password without a lowercase letter is rejected" do
    assert_no_difference -> { User.count } do
      post users_path, params: {
        user: {
          email: "lucky@example.com",
          password: "SOMEPASSW0RD!"
        }
      }
    end

    assert_response :unprocessable_content
  end

  test "a password without a number is rejected" do
    assert_no_difference -> { User.count } do
      post users_path, params: {
        user: {
          email: "lucky@example.com",
          password: "SomePassword!"
        }
      }
    end

    assert_response :unprocessable_content
  end

  test "a password without a symbol is rejected" do
    assert_no_difference -> { User.count } do
      post users_path, params: {
        user: {
          email: "lucky@example.com",
          password: "SomePassw0rd"
        }
      }
    end

    assert_response :unprocessable_content
  end
end
