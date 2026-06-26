# frozen_string_literal: true

require "test_helper"

class BankAccountTest < ActionDispatch::IntegrationTest
  setup do
    @user = sign_in
  end

  test "the account page lists its transactions" do
    bank_account = @user.bank_accounts.create!(name: "Bank A", currency: "PHP")

    import_rows(bank_account) do |csv|
      csv << [ "Date", "Description", "Amount", "Currency", "Running Balance" ]
      csv << [ "2026-06-01", "Stripe payout", "9800.00", "USD", "0" ]
    end

    get bank_account_path(bank_account)
    assert_response :success
    assert_select ".pnl-transactions tbody tr", 1
  end

  test "the account page shows an empty state with no transactions" do
    bank_account = @user.bank_accounts.create!(name: "Empty Bank", currency: "PHP")

    get bank_account_path(bank_account)
    assert_response :success
    assert_select ".empty"
  end
end
