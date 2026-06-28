# frozen_string_literal: true

module ImportsHelper
  HELP = {
    date: "The column that holds each transaction's date.",
    description: "The column that says what each transaction was for.",
    amount: "The column with the transaction amount.",
    debit: "The column with money leaving your account.",
    credit: "The column with money coming into your account."
  }.freeze

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

  def mapping_label(id, text, field)
    tag.div(class: "field-label") do
      safe_join([ label_tag(id, text), help_mark(field) ])
    end
  end

  def column_fields(amount_strategy)
    amount =
      if amount_strategy.to_sym == :debit_credit
        { debit: "Money out (debit)", credit: "Money in (credit)" }
      else
        { amount: "Amount" }
      end

    { date: "Date", description: "Description", **amount }
  end
end
