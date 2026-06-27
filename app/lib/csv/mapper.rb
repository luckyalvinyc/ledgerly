# frozen_string_literal: true

module Csv
  class Mapper
    Error = Class.new(StandardError)

    ParsedRow = Data.define(:posted_on, :description, :reference, :amount, :balance) do
      def fingerprint
        Digest::SHA256.hexdigest(
          [
            posted_on.iso8601,
            description,
            amount.cents,
            balance&.cents
          ].join("\x1F")
        )
      end
    end

    Cell = Data.define(:value, :ok) do
      def ok? = ok
    end

    def initialize(mapping)
      @mapping = mapping
    end

    def delimiter
      @mapping.delimiter
    end

    def call(row)
      parsed = ParsedRow.new(
        posted_on: posted_on(row),
        description: description(row),
        reference: resolve(row, :reference),
        amount: amount(row),
        balance: balance(row)
      )
      raise Error, "row has no amount" if parsed.amount.nil?

      parsed
    end

    # Per-field read for the review preview. Never raises: each cell says whether it parsed, and
    # keeps the raw text when it didn't, so the screen shows what it read and flags what it didn't.
    def preview(row)
      value = amount(row)

      {
        posted_on: date_cell(row),
        description: Cell.new(value: description(row), ok: true),
        amount: value ? Cell.new(value: value, ok: true) : Cell.new(value: resolve(row, :amount), ok: false),
        balance: Cell.new(value: balance(row), ok: true)
      }
    end

    private

      def posted_on(row)
        value = resolve(row, :date)
        Date.strptime(value, @mapping.date_format)
      end

      def date_cell(row)
        value = resolve(row, :date)
        Cell.new(value: Date.strptime(value.to_s, @mapping.date_format), ok: true)
      rescue ArgumentError, TypeError
        Cell.new(value: value, ok: false)
      end

      def description(row)
        value = resolve(row, :description)
        value.to_s.delete("\r\n").squeeze(" ").strip
      end

      def amount(row)
        case @mapping.amount_strategy
        when :signed
          value = resolve(row, :amount)
          Money.parse!(value)
        when :debit_credit
          value = resolve(row, :debit)
          debit = Money.parse!(value)
          return -debit if debit.present?

          value = resolve(row, :credit)
          Money.parse!(value)
        end
      end

      def balance(row)
        value = resolve(row, :balance)
        Money.parse!(value)
      end

      def resolve(row, field)
        header = @mapping.column_map[field]
        return if header.nil?

        row[header]
      end
  end
end
