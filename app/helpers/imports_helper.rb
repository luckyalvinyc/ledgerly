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

  # Plain-language help for each field, shown as a hover tooltip next to its label.
  HELP = {
    date_format: "How dates are written in your file. For 31/01/2026 choose day first, for 01/31/2026 choose month first.",
    delimiter: "The character that separates columns in your file. Usually a comma.",
    amount_strategy: "Choose 'One signed amount' if a single column shows money in as positive and money out as negative. Choose 'Separate' if your bank uses two columns.",
    date: "The column that holds each transaction's date.",
    description: "The column that says what each transaction was for.",
    amount: "The column with the transaction amount.",
    debit: "The column with money leaving your account.",
    credit: "The column with money coming into your account.",
    balance: "Optional. The running balance after each transaction.",
    reference: "Optional. A reference or cheque number, if your file has one."
  }.freeze

  # A "?" that opens a popover, matching the help control on the profit and loss page.
  def help_mark(field)
    id = "help-#{field}"
    anchor = "--anchor-#{field}"

    safe_join([
      tag.button("?",
        type: "button",
        class: "info-btn",
        popovertarget: id,
        style: "anchor-name: #{anchor}",
        aria: { label: "What is this field?" }),
      tag.div(HELP[field],
        id: id,
        popover: "",
        class: "info-popover",
        style: "position-anchor: #{anchor}")
    ])
  end

  # A field label with its help "?" beside it.
  def mapping_label(id, text, field)
    tag.div(class: "field-label") do
      safe_join([ label_tag(id, text), help_mark(field) ])
    end
  end

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
