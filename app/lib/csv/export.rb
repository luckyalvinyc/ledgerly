# frozen_string_literal: true

module Csv
  # Turns a set of transactions into a plain CSV string, machine readable:
  # ISO dates and decimal amounts, no currency symbols or thousands separators.
  module Export
    HEADERS = [ "Date", "Description", "Amount", "Currency" ].freeze

    # include_status adds a "Counts toward profit" column. The full account ledger uses it;
    # the profit and loss export omits it and only passes rows that already count.
    def self.call(transactions, currency:, include_status: false)
      headers = include_status ? HEADERS + [ "Counts toward profit" ] : HEADERS

      ::CSV.generate do |csv|
        csv << headers
        # Batched so a large export (a full year) never loads every row at once.
        transactions.find_each(batch_size: 1000) do |transaction|
          row = [
            transaction.posted_on.iso8601,
            transaction.description,
            format("%.2f", transaction.amount.to_d),
            currency
          ]
          row << transaction.included if include_status
          csv << row
        end
      end
    end
  end
end
