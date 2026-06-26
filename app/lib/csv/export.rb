# frozen_string_literal: true

module Csv
  module Export
    HEADERS = [ "Date", "Description", "Amount", "Currency" ].freeze

    def self.call(transactions, currency:)
      tempfile = Tempfile.new
      tempfile.unlink

      CSV.open(tempfile, "w", headers: HEADERS, write_headers: true) do |csv|
        transactions.find_each(batch_size: 1000) do |transaction|
          row = [
            transaction.posted_on.iso8601,
            transaction.description,
            format("%.2f", transaction.amount.to_d),
            currency
          ]
          csv << row
        end
      end

      tempfile
    end
  end
end
