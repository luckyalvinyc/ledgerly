# frozen_string_literal: true

class BankAccount < ApplicationRecord
  belongs_to :user
  has_many :imports, dependent: :destroy
  has_many :transactions, dependent: :destroy

  # The last confirmed import mapping, so the next import of the same format pre-fills.
  serialize :mapping, coder: Csv::Mapping

  validates :name, presence: true
  validates :currency, inclusion: { in: Money::SUPPORTED_CURRENCIES }

  def profit_and_loss(period, granularity: "month")
    period = Pnl::Period.for(period, granularity: granularity)
    scope = transactions.where(included: true, posted_on: period.range)

    Pnl.build(
      period: period,
      currency: currency,
      revenue: scope.where("amount_cents > 0").sum(:amount_cents),
      expenses: -scope.where("amount_cents < 0").sum(:amount_cents)
    )
  end
end
