# frozen_string_literal: true

class Import < ApplicationRecord
  STATUSES = [
    :reviewing,
    :pending,
    :processing,
    :completed,
    :failed
  ].freeze

  belongs_to :bank_account
  has_many :transactions, dependent: :destroy
  has_one_attached :file

  enum :status, STATUSES.index_by(&:itself), default: :reviewing
end
