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

  # Csv::Mapping is its own coder, so import.mapping is a Csv::Mapping value object.
  serialize :mapping, coder: Csv::Mapping

  enum :status, STATUSES.index_by(&:itself), default: :reviewing
end
