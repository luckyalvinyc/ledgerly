# frozen_string_literal: true

module PeriodScoped
  extend ActiveSupport::Concern

  private

    def load_statement(bank_account)
      @bank_account = bank_account
      @granularity = current_granularity
      @period = current_period
      @statement = bank_account.profit_and_loss(@period)
    end

    GRANULARITIES = [ "month", "quarter", "year" ].freeze

    def current_period
      case current_granularity
      when "month" then Pnl::Period.month(current_anchor)
      when "quarter" then Pnl::Period.quarter(current_anchor)
      when "year" then Pnl::Period.year(current_anchor)
      end
    end

    def current_granularity
      period = params[:period]
      period.presence_in(GRANULARITIES) || "month"
    end

    def current_anchor
      Date.parse(params[:date].to_s)
    rescue ArgumentError, TypeError
      Date.current
    end
end
