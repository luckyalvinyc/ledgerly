# frozen_string_literal: true

module Csv
  class Parser
    Result = Data.define(:row, :error) do
      def ok? = error.nil?
    end

    def initialize(mapper)
      @mapper = mapper
    end

    def each_row(io)
      return to_enum(:each_row, io) if !block_given?

      options = {
        headers: true,
        skip_blanks: true,
        col_sep: @mapper.delimiter
      }

      CSV.foreach(io, **options) do |row|
        yield map(row)
      end
    end

    private

      def map(row)
        Result.new(row: @mapper.call(row), error: nil)
      rescue ArgumentError, TypeError, Mapper::Error => e
        Result.new(row: nil, error: e.message)
      end
  end
end
