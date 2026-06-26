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

  test "renaming an account updates its name" do
    bank_account = @user.bank_accounts.create!(name: "Old Name", currency: "PHP")

    patch bank_account_path(bank_account), params: { bank_account: { name: "New Name" } }

    assert_redirected_to bank_account
    assert_equal "New Name", bank_account.reload.name
  end

  test "the currency cannot be changed once the account exists" do
    bank_account = @user.bank_accounts.create!(name: "Fixed", currency: "PHP")

    patch bank_account_path(bank_account), params: { bank_account: { name: "Fixed", currency: "USD" } }

    assert_equal "PHP", bank_account.reload.currency
  end

  test "deleting an account removes it and its transactions" do
    bank_account = @user.bank_accounts.create!(name: "Doomed", currency: "PHP")

    import_rows(bank_account) do |csv|
      csv << [ "Date", "Description", "Amount", "Currency", "Running Balance" ]
      csv << [ "2026-06-01", "Stripe payout", "9800.00", "USD", "0" ]
    end
    assert bank_account.transactions.any?

    assert_difference -> { @user.bank_accounts.count } => -1, -> { Transaction.count } => -1 do
      delete bank_account_path(bank_account)
    end

    assert_redirected_to root_path
  end
end
