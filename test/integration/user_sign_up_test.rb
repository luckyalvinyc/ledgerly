# frozen_string_literal: true

require "test_helper"

class UserSignUpTest < ActionDispatch::IntegrationTest
  test "signing up with valid details creates a user" do
    assert_difference -> { User.count }, 1 do
      post users_path, params: {
        user: {
          email: "lucky@example.com",
          password: "SomePassw0rd!"
        }
      }
    end
  end

  test "signing up normalizes the case for the email" do
    post users_path, params: {
      user: {
        email: "luCky@ExamplE.com",
        password: "SomePassw0rd!"
      }
    }

    assert_equal "lucky@example.com", User.first.email
  end

  test "signing up with an invalid email" do
    assert_no_difference -> { User.count } do
      post users_path, params: {
        user: {
          email: "luckyexample.com",
          password: "SomePassw0rd!"
        }
      }
    end

    assert_response :unprocessable_entity
  end

  test "signing up with a blank email" do
    assert_no_difference -> { User.count } do
      post users_path, params: {
        user: {
          email: "",
          password: "SomePassw0rd!"
        }
      }
    end

    assert_response :unprocessable_entity
  end

  test "signing up with a blank password" do
    assert_no_difference -> { User.count } do
      post users_path, params: {
        user: {
          email: "lucky@example.com",
          password: ""
        }
      }
    end

    assert_response :unprocessable_entity
  end

  test "signing up with a password length is less than 8" do
    assert_no_difference -> { User.count } do
      post users_path, params: {
        user: {
          email: "lucky@example.com",
          password: "S0mePa!"
        }
      }
    end

    assert_response :unprocessable_entity
  end

  test "signing up with a password does not contain an uppercase letter" do
    assert_no_difference -> { User.count } do
      post users_path, params: {
        user: {
          email: "lucky@example.com",
          password: "somepassw0rd!"
        }
      }
    end

    assert_response :unprocessable_entity
  end

  test "signing up with a password does not contain a lowercase letter" do
    assert_no_difference -> { User.count } do
      post users_path, params: {
        user: {
          email: "lucky@example.com",
          password: "SOMEPASSW0RD!"
        }
      }
    end

    assert_response :unprocessable_entity
  end

  test "signing up with a password does not contain a digit" do
    assert_no_difference -> { User.count } do
      post users_path, params: {
        user: {
          email: "lucky@example.com",
          password: "SomePassword!"
        }
      }
    end

    assert_response :unprocessable_entity
  end

  test "signing up with a password does not contain a special character" do
    assert_no_difference -> { User.count } do
      post users_path, params: {
        user: {
          email: "lucky@example.com",
          password: "SomePassw0rd"
        }
      }
    end

    assert_response :unprocessable_entity
  end
end
