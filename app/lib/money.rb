# frozen_string_literal: true

class Money
  SUPPORTED_CURRENCIES = Set.new([ "ZAR", "USD", "GBP", "PHP" ].sort)

  class << self
    # Wrap a number of cents, or pass through a Money as-is.
    def for(value)
      value.is_a?(Money) ? value : new(value)
    end

    def parse!(amount)
      return if amount.nil?

      text = amount.to_s.strip
      return if text.empty?

      digits = text.gsub(/[^0-9.]/, "")
      return if digits.empty?

      negative = text.start_with?("-", "(")
      cents = (BigDecimal(digits) * 100).round(2).to_i
      cents = -cents if negative

      new(cents)
    end
  end

  attr_reader :cents

  def initialize(cents)
    @cents = cents
  end

  def zero?
    cents.zero?
  end

  def negative?
    cents.negative?
  end

  def to_d
    BigDecimal(cents) / 100
  end

  def -(other)
    self.class.new(cents - other.cents)
  end

  def -@
    self.class.new(-cents)
  end
end
