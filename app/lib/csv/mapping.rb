# frozen_string_literal: true

module Csv
  # How one bank's CSV maps onto our canonical columns. Produced by Csv::Detect, edited on the
  # review screen, consumed by Csv::Mapper, and persisted on an Import. It is also its own
  # Active Record serializer (dump/load), so a column can hold a Mapping value object directly.
  Mapping = Data.define(:currency, :delimiter, :column_map, :amount_strategy, :date_format) do
    def self.dump(mapping)
      return if mapping.nil?

      JSON.generate(mapping.to_h)
    end

    def self.load(value)
      return if value.blank?

      data = value.is_a?(String) ? JSON.parse(value) : value

      new(
        currency: data["currency"],
        delimiter: data["delimiter"],
        column_map: (data["column_map"] || {}).transform_keys(&:to_sym).compact,
        amount_strategy: data["amount_strategy"]&.to_sym,
        date_format: data["date_format"]
      )
    end

    # Enough mapped to land transactions: a date, a description, and a way to read the amount.
    def complete?
      column_map[:date].present? &&
        column_map[:description].present? &&
        (column_map[:amount].present? || (column_map[:debit].present? && column_map[:credit].present?))
    end
  end
end
