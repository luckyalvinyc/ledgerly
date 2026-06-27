# frozen_string_literal: true

module Csv
  module Parser
    Result = Data.define(:row, :error) do
      def ok? = error.nil?
    end

    extend self

    def foreach(io, mapper:)
      return to_enum(:foreach, io, mapper: mapper) if !block_given?

      options = {
        headers: true,
        skip_blanks: true,
        col_sep: mapper.delimiter
      }

      CSV.foreach(io, **options) do |row|
        yield map(row, mapper:)
      end
    end

    private

      def map(row, mapper:)
        Result.new(row: mapper.call(row), error: nil)
      rescue ArgumentError, TypeError, Mapper::Error => e
        Result.new(row: nil, error: e.message)
      end
  end
end
