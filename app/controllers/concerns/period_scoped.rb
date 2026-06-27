# frozen_string_literal: true

module PeriodScoped
  extend ActiveSupport::Concern

  private

    def load_statement(bank_account)
      @bank_account = bank_account
      @granularity = current_granularity
      @statement = bank_account.profit_and_loss(current_anchor, granularity: @granularity)
      @period = @statement.period
    end

    GRANULARITIES = [ "month", "quarter", "year" ].freeze

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
