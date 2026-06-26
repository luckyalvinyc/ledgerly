# frozen_string_literal: true

class DashboardController < ApplicationController
  before_action :redirect_if_unauthenticated

  def index
    @period = Pnl::Period.month(Date.current)

    @bank_accounts = current_user.bank_accounts.map do |bank_account|
      [ bank_account, bank_account.profit_and_loss(@period) ]
    end
  end
end
