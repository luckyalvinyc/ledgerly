# frozen_string_literal: true

module Csv
  module Export
    HEADERS = [ "Date", "Description", "Amount", "Currency" ].freeze
    FORMULA_START = /\A[=+\-@\t\r]/

    def self.call(transactions, currency:)
      tempfile = Tempfile.new
      tempfile.unlink

      CSV.open(tempfile, "w", headers: HEADERS, write_headers: true) do |csv|
        transactions.find_each(batch_size: 1000) do |transaction|
          row = [
            transaction.posted_on.iso8601,
            formula_safe(transaction.description),
            format("%.2f", transaction.amount.to_d),
            currency
          ]
          csv << row
        end
      end

      tempfile
    end

    # A spreadsheet runs a cell starting with =, +, -, @ or a control char as a formula. The
    # description is free text from the bank file, so quote it to keep it as plain text.
    def self.formula_safe(text)
      text.to_s.match?(FORMULA_START) ? "'#{text}" : text
    end
  end
end
