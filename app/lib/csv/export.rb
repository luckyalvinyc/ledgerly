# frozen_string_literal: true

module Csv
  # Turns a set of transactions into a plain CSV string, machine readable:
  # ISO dates and decimal amounts, no currency symbols or thousands separators.
  module Export
    HEADERS = [ "Date", "Description", "Amount", "Currency", "Counts toward profit" ].freeze

    def self.call(transactions, currency:)
      ::CSV.generate do |csv|
        csv << HEADERS
        transactions.each do |transaction|
          csv << [
            transaction.posted_on.iso8601,
            transaction.description,
            format("%.2f", transaction.amount.to_d),
            currency,
            transaction.included
          ]
        end
      end
    end
  end
end
