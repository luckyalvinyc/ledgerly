# frozen_string_literal: true

class BankAccount < ApplicationRecord
  belongs_to :user
  has_many :imports, dependent: :destroy
  has_many :transactions, dependent: :destroy

  # The last confirmed import mapping, so the next import of the same format pre-fills.
  serialize :mapping, coder: Csv::Mapping

  validates :name, presence: true
  validates :currency, inclusion: { in: Money::SUPPORTED_CURRENCIES }

  def profit_and_loss(period)
    scope = transactions.where(included: true, posted_on: period.range)
    revenue = Money.new(scope.where("amount_cents > 0").sum(:amount_cents))
    expenses = Money.new(-scope.where("amount_cents < 0").sum(:amount_cents))

    Pnl.build(
      period: period,
      currency: currency,
      revenue: revenue,
      expenses: expenses
    )
  end
end
