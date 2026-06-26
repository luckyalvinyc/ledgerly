# frozen_string_literal: true

class ImportsController < ApplicationController
  before_action :redirect_if_unauthenticated

  helper_method :import_return_to

  def new
    @bank_account = current_user.bank_accounts.find(params[:bank_account_id])
    @import = @bank_account.imports.new
    session[:import_return_to] = safe_return_to(params[:return_to])
  end

  def create
    @bank_account = current_user.bank_accounts.find(params[:bank_account_id])

    file = params[:file]
    @import = @bank_account.imports.build(filename: file.original_filename)
    @import.file.attach(file)

    if @import.save
      redirect_to review_import_path(@import)
    else
      render :new, status: :unprocessable_content
    end
  end

  def show
    @import = current_user.imports.find(params[:id])
  end

  def review
    @import = current_user.imports.find(params[:id])
    currency = @import.bank_account.currency

    @import.file.open do |io|
      @mapping = Csv::Detect.call(io).with(currency: currency)
      mapper = Csv::Mapper.new(@mapping)
      @rows = Csv::Parser.new(mapper).each_row(io).lazy.filter_map(&:row).first(10)
        .sort_by(&:posted_on).reverse
    end
  end

  def confirm
    @import = current_user.imports.find(params[:id])

    claimed = current_user.imports
      .where(id: @import.id, status: :reviewing)
      .update_all(status: :pending, updated_at: Time.current)

    ImportJob.perform_later(@import) if claimed == 1
    redirect_to @import
  end

  private

    # Where the import flow should return to, set when the flow was entered.
    def import_return_to(import)
      session[:import_return_to].presence || bank_account_path(import.bank_account)
    end

    # Only accept a local path, to avoid an open-redirect through return_to.
    def safe_return_to(path)
      path if path.to_s.start_with?("/") && !path.to_s.start_with?("//")
    end
end
