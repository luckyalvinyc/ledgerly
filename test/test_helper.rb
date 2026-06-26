ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    # Add more helper methods to be used by all tests here...

    def sign_in(user = nil)
      cookies.delete("__Host-session_token")

      user ||= users(:lucky)

      post session_path, params: {
        email: user.email,
        password: "SomePassw0rd@"
      }

      cookie = cookies.get_cookie("__Host-session_token")
      assert_not_nil cookie

      user
    end
  end
end

module ActionDispatch
  class IntegrationTest
    setup { https! }
  end
end
