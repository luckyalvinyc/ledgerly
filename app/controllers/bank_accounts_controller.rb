# frozen_string_literal: true

class BankAccountsController < ApplicationController
  include Paginated

  before_action :redirect_if_unauthenticated

  def new
    @bank_account = current_user.bank_accounts.new
  end

  def create
    @bank_account = current_user.bank_accounts.new(bank_account_params)
    if @bank_account.save
      redirect_to @bank_account
    else
      render :new, status: :unprocessable_content
    end
  end

  def show
    @bank_account = current_user.bank_accounts.find(params[:id])
    @page = paginate(@bank_account.transactions.order(posted_on: :desc))
  end

  private

    def bank_account_params
      params.expect(bank_account: [ :name, :currency ])
    end
end
