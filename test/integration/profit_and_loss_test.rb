# frozen_string_literal: true

require "test_helper"

class ProfitAndLossTest < ActionDispatch::IntegrationTest
  setup do
    user = sign_in
    @bank_account = user.bank_accounts.create!(
      name: "Bank A",
      currency: "PHP"
    )
  end

  test "money in and money out are totalled separately" do
    import_rows(@bank_account) do |csv|
      csv << [ "Date", "Description", "Amount", "Currency", "Running Balance" ]
      csv << [ "2026-06-01", "Stripe payout", "9800.00", "USD", "50877.70" ]
      csv << [ "2026-06-20", "Monthly bank fee", "-25.00", "USD", "41077.70" ]
    end

    get bank_account_profit_and_loss_path(@bank_account)
    assert_response :success

    statement = @bank_account.profit_and_loss(
      Pnl::Period.month(Date.new(2026, 6, 25))
    )
    assert_equal 980000, statement.revenue.cents
    assert_equal 2500, statement.expenses.cents
    assert_equal 977500, statement.net_profit.cents
  end

  test "excluding a transaction raises the profit" do
    import_rows(@bank_account) do |csv|
      csv << [ "Date", "Description", "Amount", "Currency", "Running Balance" ]
      csv << [ "2026-06-01", "Stripe payout", "9800.00", "USD", "50877.70" ]
      csv << [ "2026-06-20", "Monthly bank fee", "-25.00", "USD", "41077.70" ]
    end

    transaction = @bank_account.transactions.find_by(posted_on: Date.new(2026, 6, 20))

    patch transaction_path(transaction), as: :turbo_stream, params: {
      transaction: {
        included: false
      }
    }

    assert_response :success
    assert_not transaction.reload.included

    statement = @bank_account.profit_and_loss(
      Pnl::Period.month(Date.new(2026, 6, 25))
    )
    assert_equal 980000, statement.revenue.cents
    assert_equal 0, statement.expenses.cents
    assert_equal 980000, statement.net_profit.cents
  end

  test "a long list of transactions is paginated" do
    import_rows(@bank_account) do |csv|
      csv << [ "Date", "Description", "Amount", "Currency", "Running Balance" ]
      30.times do |i|
        day = format("%02d", (i % 28) + 1)
        csv << [ "2026-06-#{day}", "Txn #{i}", "100.00", "USD", "0" ]
      end
    end

    get bank_account_profit_and_loss_path(@bank_account, period: "month", date: "2026-06-15")
    assert_response :success
    assert_select ".pnl-transactions tbody tr", 25
    assert_select ".pager"

    get bank_account_profit_and_loss_path(@bank_account, period: "month", date: "2026-06-15", page: 2)
    assert_response :success
    assert_select ".pnl-transactions tbody tr", 5
  end
end
