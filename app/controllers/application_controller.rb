# frozen_string_literal: true

class ApplicationController < ActionController::Base
  include Authentication

  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  helper_method :current_theme

  before_action :set_no_store

  private

    def set_no_store
      return if current_user.nil?

      response.headers["Cache-Control"] = "no-store"
    end

    # "light" or "dark" when the user has overridden the OS default, else nil.
    def current_theme
      cookies[:theme].presence_in(%w[light dark])
    end

    def csv_exporter(transactions, currency:, filename:, included: nil)
      transactions = transactions.where(included: included) if !included.nil?
      csv_file = Csv::Export.call(transactions, currency: currency)

      send_file csv_file, filename: filename, type: "text/csv"
    ensure
      csv_file.close!
    end
end
