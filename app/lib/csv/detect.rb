# frozen_string_literal: true

module Csv
  class Detect
    class << self
      def call(io)
        header_line = io.readline
        delimiter = detect_delimiter(header_line)
        column_map = detect_columns(header_line, delimiter: delimiter)
        amount_strategy = detect_amount_strategy(column_map)
        rows = read_sample_rows(io, delimiter: delimiter)
        date_format = detect_date_format(rows, header: column_map[:date])

        Mapping.new(
          currency: nil,
          delimiter: delimiter,
          column_map: column_map,
          amount_strategy: amount_strategy,
          date_format: date_format
        )
      end

      private

        DELIMITERS = [ ",", ";", "\t", "|" ].freeze

        def detect_delimiter(line)
          DELIMITERS.max_by { |d| line.count(d) }
        end

        SYNONYMS = {
          date: [ "DATE", "POSTING DATE", "VALUE DATE", "TRANSACTION DATE" ],
          reference: [ "REFERENCE", "REF NO", "REF" ],
          description: [ "DESCRIPTION", "DETAILS", "NARRATION", "PARTICULARS", "MEMO" ],
          debit: [ "DEBIT", "WITHDRAWAL", "MONEY OUT", "PAID OUT" ],
          credit: [ "CREDIT", "DEPOSIT", "MONEY IN", "PAID IN" ],
          amount: [ "AMOUNT" ],
          balance: [ "BALANCE", "ENDING BALANCE", "RUNNING BALANCE", "CLOSING BALANCE" ]
        }.freeze

        def detect_columns(header_line, delimiter:)
          claimed = Set.new
          headers = CSV.parse_line(header_line, col_sep: delimiter)

          SYNONYMS.each_with_object({}) do |(field, words), map|
            header = headers.find do |h|
              next if claimed.include?(h)

              normalized = h.to_s.strip.upcase
              words.any? { |w| normalized == w || normalized.include?(w) }
            end

            next if header.nil?

            claimed << header
            map[field] = header
          end
        end

        def detect_amount_strategy(column_map)
          if column_map[:debit].present? && column_map[:credit].present?
            :debit_credit
          else
            :signed
          end
        end

        SAMPLE_ROW_SIZE = 20

        def read_sample_rows(io, delimiter:)
          rows = []
          csv = CSV.open(io.path, headers: true, col_sep: delimiter)

          SAMPLE_ROW_SIZE.times do
            row = csv.readline
            break if row.nil?

            rows << row
          end

          rows
        end

        def detect_date_format(rows, header:)
          values = rows.filter_map { |row| row[header] }
          return "%Y-%m-%d" if values.all? { |v| v.match?(/\A\d{4}-\d{2}-\d{2}\z/) }

          parts = values.filter_map { |v| v.split("/").first(2).map(&:to_i) if v.include?("/") }
          if parts.any? { |first, _| first > 12 }
            "%d/%m/%Y"
          else
            "%m/%d/%Y"
          end
        end
    end
  end
end
