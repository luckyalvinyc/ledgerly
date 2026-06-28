# frozen_string_literal: true

class HeaderAlias < ApplicationRecord
  normalizes :pattern, with: ->(pattern) { pattern.strip.upcase }

  validates :field, presence: true, inclusion: { in: Csv::Detect::FIELDS.map(&:to_s) }
  validates :pattern, presence: true, uniqueness: true

  class << self
    def by_field
      Rails.cache.fetch([ "header_aliases", count, maximum(:updated_at) ]) do
        all.group_by(&:field).transform_values { |aliases| aliases.map(&:pattern) }
      end
    end
  end
end
