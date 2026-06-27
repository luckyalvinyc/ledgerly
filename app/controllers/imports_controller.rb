# frozen_string_literal: true

class ImportsController < ApplicationController
  before_action :redirect_if_unauthenticated
  before_action :set_import, only: [ :show, :review, :preview, :confirm ]

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
  end

  def review
    @mapping = current_mapping
    load_preview
    @adjust_open = @rows.any?(&:unreadable?)
  end

  # Re-renders the review frame for the mapping currently in the form (live preview).
  def preview
    @mapping = mapping_from(params)
    load_preview
    @adjust_open = true
    render :review
  end

  def confirm
    @mapping = mapping_from(params)

    if !@mapping.complete?
      @error = "Map a date, a description, and an amount before importing."
      load_preview
      @adjust_open = true
      render :review, status: :unprocessable_content
      return
    end

    @import.bank_account.update!(mapping: @mapping)

    claimed = current_user.imports
      .where(id: @import.id, status: :reviewing)
      .update_all(status: :pending, updated_at: Time.current)

    ImportJob.perform_later(@import) if claimed == 1
    redirect_to @import
  end

  private

    def set_import
      @import = current_user.imports.find(params[:id])
    end

    # Start from what the bank used last time, but only if it still fits this file. If the bank
    # changed its format, those columns won't be there, so fall back to a fresh detection.
    def current_mapping
      remembered = @import.bank_account.mapping
      remembered && remembered_fits?(remembered) ? remembered : detected_mapping
    end

    def remembered_fits?(mapping)
      headers = headers_for(mapping.delimiter)
      mapping.column_map.values.all? { |header| headers.include?(header) }
    end

    def detected_mapping
      @import.file.open { |io| Csv::Detect.call(io) }.with(currency: @import.bank_account.currency)
    end

    SAMPLE_SIZE = 15

    # The sample is read cell by cell, so a row still shows the columns it could read and flags
    # the ones it couldn't. Headers come from the same pass, so the column selects follow the file.
    def load_preview
      mapper = Csv::Mapper.new(@mapping)
      @import.file.open do |io|
        csv = CSV.new(io, headers: true, skip_blanks: true, col_sep: @mapping.delimiter)
        @rows = csv.first(SAMPLE_SIZE).map { |row| mapper.preview(row) }
        @headers = csv.headers || []
      end
    end

    def headers_for(delimiter)
      @import.file.open { |io| CSV.parse_line(io.readline, col_sep: delimiter) }
    end

    COLUMN_FIELDS = %i[date description amount debit credit balance reference].freeze

    def mapping_from(params)
      attrs = params.expect(mapping: [ :delimiter, :amount_strategy, :date_format, column_map: COLUMN_FIELDS ])
      column_map = attrs[:column_map].to_h.symbolize_keys.compact_blank

      Csv::Mapping.new(
        currency: @import.bank_account.currency,
        delimiter: attrs[:delimiter],
        column_map: column_map,
        amount_strategy: attrs[:amount_strategy].to_sym,
        date_format: attrs[:date_format]
      )
    end

    # Where the import flow should return to, set when the flow was entered.
    def import_return_to(import)
      session[:import_return_to].presence || bank_account_path(import.bank_account)
    end

    # Only accept a local path, to avoid an open-redirect through return_to.
    def safe_return_to(path)
      path if path.to_s.start_with?("/") && !path.to_s.start_with?("//")
    end
end
