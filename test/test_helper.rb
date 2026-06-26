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

    def import_rows(bank_account, &block)
      file = create_csv_file(&block)

      post bank_account_imports_path(bank_account), params: {
        file: file
      }

      import = bank_account.imports.sole

      perform_enqueued_jobs do
        post confirm_import_path(import)
      end
    end

    def create_csv_file(&block)
      Tempfile.create do |f|
        CSV.open(f, "w", &block)
        Rack::Test::UploadedFile.new(f)
      end
    end
  end
end

module ActionDispatch
  class IntegrationTest
    setup { https! }
  end
end
