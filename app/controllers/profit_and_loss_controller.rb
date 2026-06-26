# frozen_string_literal: true

class ProfitAndLossController < ApplicationController
  include PeriodScoped
  include Paginated

  before_action :redirect_if_unauthenticated

  def show
    load_statement(current_user.bank_accounts.find(params[:bank_account_id]))

    @page = paginate(
      @bank_account
        .transactions
        .where(posted_on: @period.range)
        .order(posted_on: :desc)
    )
  end
end
