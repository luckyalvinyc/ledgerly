# frozen_string_literal: true

module Pnl
  Period = Data.define(:starts_on, :ends_on, :label) do
    class << self
      def month(date)
        new(
          starts_on: date.beginning_of_month,
          ends_on: date.end_of_month,
          label: date.strftime("%B %Y")
        )
      end

      def quarter(date)
        new(
          starts_on: date.beginning_of_quarter,
          ends_on: date.end_of_quarter,
          label: "Q#{(date.month / 3.0).ceil} #{date.year}"
        )
      end

      def year(date)
        new(
          starts_on: date.beginning_of_year,
          ends_on: date.end_of_year,
          label: date.year.to_s
        )
      end
    end

    def range
      starts_on..ends_on
    end
  end

  Statement = Data.define(:period, :currency, :revenue, :expenses, :net_profit) do
    def net_margin
      return if revenue.zero?

      (net_profit.to_d / revenue.to_d * 100).round(1)
    end
  end

  extend self

  def build(period:, currency:, revenue:, expenses:)
    Statement.new(
      period: period,
      currency: currency,
      revenue: revenue,
      expenses: expenses,
      net_profit: revenue - expenses
    )
  end
end
