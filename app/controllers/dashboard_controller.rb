# frozen_string_literal: true

class DashboardController < CustomerController
  def index
    @period = Pnl::Period.month(Date.current)
    counts = current_user.transactions.group(:bank_account_id).count

    @bank_accounts = current_user.bank_accounts.map do |bank_account|
      [ bank_account, bank_account.profit_and_loss(@period), counts.fetch(bank_account.id, 0) ]
    end
  end
end
