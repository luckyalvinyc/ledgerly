# frozen_string_literal: true

class ProfitAndLossController < ApplicationController
  include PeriodScoped
  include Paginated

  before_action :redirect_if_unauthenticated

  def show
    load_statement(current_user.bank_accounts.find(params[:bank_account_id]))

    transactions = @bank_account
      .transactions
      .where(posted_on: @period.range)
      .order(posted_on: :desc)

    respond_to do |format|
      format.html { @page = paginate(transactions) }
      format.csv do
        counted = @bank_account.transactions.where(posted_on: @period.range, included: true)
        send_data Csv::Export.call(counted, currency: @bank_account.currency),
          filename: "#{@bank_account.name.parameterize}-profit-and-loss-#{@period.label.parameterize}.csv",
          type: "text/csv"
      end
    end
  end
end
