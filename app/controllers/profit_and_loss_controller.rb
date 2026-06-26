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
      format.csv { export_to_csv(transactions) }
    end
  end

  private

    def export_to_csv(transactions)
      currency = @bank_account.currency
      filename = "#{@bank_account.name.parameterize}-profit-and-loss-#{@period.label.parameterize}.csv"

      csv_exporter(transactions, currency:, filename:, included: true)
    end
end
