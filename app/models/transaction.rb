# frozen_string_literal: true

class Transaction < ApplicationRecord
  belongs_to :bank_account
  belongs_to :import

  def amount
    Money.new(amount_cents)
  end
end
