# frozen_string_literal: true

require "test_helper"

class DashboardTest < ActionDispatch::IntegrationTest
  test "each account shows its own profit, never mixing currencies" do
    travel_to Date.new(2026, 6, 21) do
      user = sign_in

      php_bank_account = user.bank_accounts.create!(
        name: "Peso Account",
        currency: "PHP"
      )
      usd_bank_account = user.bank_accounts.create!(
        name: "Dollar Account",
        currency: "USD"
      )

      import_rows(php_bank_account) do |csv|
        csv << [ "Date", "Description", "Amount", "Currency", "Running Balance" ]
        csv << [ "2026-06-01", "Stripe payout", "9800.00", "PHP", "50877.70" ]
        csv << [ "2026-06-20", "Monthly bank fee", "-25.00", "PHP", "41077.70" ]
      end
      import_rows(usd_bank_account) do |csv|
        csv << [ "Date", "Description", "Amount", "Currency", "Running Balance" ]
        csv << [ "2026-06-01", "Stripe payout", "9800.00", "USD", "50877.70" ]
        csv << [ "2026-06-20", "Monthly bank fee", "-25.00", "USD", "41077.70" ]
      end

      get root_path
      assert_response :success

      assert_select "article.account", count: 2
      assert_includes response.body, "₱9,800.00"
      assert_includes response.body, "$9,800.00"
      assert_not_includes response.body, "19,600"
    end
  end
end
