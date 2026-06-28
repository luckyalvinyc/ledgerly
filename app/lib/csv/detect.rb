# frozen_string_literal: true

module Csv
  class Detect
    FIELDS = %i[date reference description debit credit amount balance].freeze

    class << self
      def call(io)
        header_line = io.readline
        delimiter = detect_delimiter(header_line)
        column_map = detect_columns(header_line, delimiter: delimiter)

        Mapping.new(
          currency: nil,
          delimiter: delimiter,
          column_map: column_map,
          amount_strategy: detect_amount_strategy(column_map),
          date_format: detect_date_format(io, delimiter: delimiter, header: column_map[:date])
        )
      end

      private

        DELIMITERS = [ ",", ";", "\t", "|" ].freeze

        def detect_delimiter(line)
          DELIMITERS.max_by { |d| line.count(d) }
        end

        def detect_columns(header_line, delimiter:)
          claimed = Set.new
          aliases = HeaderAlias.by_field
          headers = CSV.parse_line(header_line, col_sep: delimiter)

          FIELDS.each_with_object({}) do |field, map|
            patterns = aliases[field.to_s] || []
            header = headers.find do |h|
              next if claimed.include?(h)

              normalized = h.to_s.strip.upcase
              patterns.any? { |pattern| normalized == pattern || normalized.include?(pattern) }
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

        # Scan until a value settles the day/month order: a part over 12 can only be the day.
        # Most files decide in the first rows; a fully ambiguous file defaults to day first.
        def detect_date_format(io, delimiter:, header:)
          return "%d/%m/%Y" if header.nil?

          CSV.foreach(io.path, headers: true, col_sep: delimiter) do |row|
            value = row[header].to_s
            return "%Y-%m-%d" if value.match?(/\A\d{4}-\d{2}-\d{2}\z/)
            next unless value.include?("/")

            first, second = value.split("/").first(2).map(&:to_i)
            return "%d/%m/%Y" if first > 12
            return "%m/%d/%Y" if second && second > 12
          end

          "%d/%m/%Y"
        end
    end
  end
end
