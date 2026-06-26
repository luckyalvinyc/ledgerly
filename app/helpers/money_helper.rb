# frozen_string_literal: true

module MoneyHelper
  CURRENCY_UNITS = {
    "USD" => "$",
    "GBP" => "£",
    "ZAR" => "R",
    "PHP" => "₱"
  }.freeze

  def money(amount, currency:)
    return "-" if amount.nil?

    number_to_currency(
      amount.to_d,
      unit: CURRENCY_UNITS.fetch(currency) { "#{currency} " }
    )
  end
end
