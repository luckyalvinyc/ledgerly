# frozen_string_literal: true

module ImportsHelper
  DATE_FORMATS = [
    [ "Year first (2026-01-31)", "%Y-%m-%d" ],
    [ "Day first (31/01/2026)", "%d/%m/%Y" ],
    [ "Month first (01/31/2026)", "%m/%d/%Y" ]
  ].freeze

  DELIMITERS = [
    [ "Comma", "," ],
    [ "Semicolon", ";" ],
    [ "Tab", "\t" ],
    [ "Pipe", "|" ]
  ].freeze

  AMOUNT_STRATEGIES = [
    [ "One signed amount", "signed" ],
    [ "Separate money in and out", "debit_credit" ]
  ].freeze

  # The canonical fields to map, and their labels. The amount fields depend on the strategy.
  def column_fields(amount_strategy)
    amount =
      if amount_strategy.to_sym == :debit_credit
        { debit: "Money out (debit)", credit: "Money in (credit)" }
      else
        { amount: "Amount" }
      end

    { date: "Date", description: "Description" }
      .merge(amount)
      .merge(balance: "Balance (optional)", reference: "Reference (optional)")
  end
end
