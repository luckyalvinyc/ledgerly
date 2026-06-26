# frozen_string_literal: true

class BankAccountsController < ApplicationController
  include Paginated

  before_action :redirect_if_unauthenticated
  before_action :set_bank_account, only: [ :show, :edit, :update, :destroy ]

  def new
    @bank_account = current_user.bank_accounts.new
  end

  def create
    @bank_account = current_user.bank_accounts.new(bank_account_create_params)
    if @bank_account.save
      redirect_to @bank_account
    else
      render :new, status: :unprocessable_content
    end
  end

  def show
    @page = paginate(@bank_account.transactions.order(posted_on: :desc))
  end

  def edit
  end

  def update
    if @bank_account.update(bank_account_update_params)
      redirect_to @bank_account
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    name = @bank_account.name
    @bank_account.destroy
    redirect_to root_path, flash: { caution: t("flash.bank_accounts.deleted", name: name) }
  end

  private

    def set_bank_account
      @bank_account = current_user.bank_accounts.find(params[:id])
    end

    def bank_account_create_params
      params.expect(bank_account: [ :name, :currency ])
    end

    def bank_account_update_params
      params.expect(bank_account: [ :name ])
    end
end
