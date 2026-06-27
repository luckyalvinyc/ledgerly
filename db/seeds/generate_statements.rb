# frozen_string_literal: true

# Deterministic generator for the demo bank statements.
#
#   ruby db/seeds/generate_statements.rb
#
# Writes four CSV files under db/seeds/statements covering 2026-01-01 through
# "today" (2026-06-25), each in a different real-world bank format. A fixed RNG
# seed makes the output reproducible: same files every run. The seed task then
# imports these through the real pipeline.

require "csv"
require "date"

SEED = 20_260_629
START_ON = Date.new(2026, 1, 1)
TODAY = Date.new(2026, 6, 25)
OUT = File.expand_path("statements", __dir__)

# description => range of whole currency units
INCOME = {
  "Customer invoice" => 4_000..18_000,
  "Sales receipt"    => 2_000..9_000,
  "Stripe payout"    => 3_000..15_000,
  "Consulting fee"   => 5_000..20_000,
  "Cash sale"        => 1_000..6_000
}.freeze

EXPENSE = {
  "Office rent"           => 4_000..6_000,
  "Utilities"             => 300..1_200,
  "Software subscription" => 100..1_500,
  "Bank fee"              => 20..400,
  "Supplies"              => 200..2_000,
  "Marketing"             => 500..5_000
}.freeze

PAYROLL = 8_000..16_000

Txn = Struct.new(:date, :description, :cents) # cents signed: + income, - expense

def months(from, to)
  list = []
  d = Date.new(from.year, from.month, 1)
  while d <= to
    list << d
    d = d >> 1
  end
  list
end

def cents(rng, range)
  rng.rand(range) * 100 + rng.rand(0..99)
end

def fmt(cents)
  sign = cents.negative? ? "-" : ""
  c = cents.abs
  "#{sign}#{c / 100}.#{(c % 100).to_s.rjust(2, '0')}"
end

def generate(rng)
  txns = []

  months(START_ON, TODAY).each do |month|
    eom = Date.new(month.year, month.month, -1)
    last = [ eom, TODAY ].min
    days = (month..last).to_a

    # one payroll a month, then a spread of other costs and income, income-heavy
    txns << Txn.new(days.sample(random: rng), "Payroll", -cents(rng, PAYROLL))

    rng.rand(10..13).times do
      desc = (EXPENSE.keys).sample(random: rng)
      txns << Txn.new(days.sample(random: rng), desc, -cents(rng, EXPENSE[desc]))
    end

    rng.rand(6..8).times do
      desc = INCOME.keys.sample(random: rng)
      txns << Txn.new(days.sample(random: rng), desc, cents(rng, INCOME[desc]))
    end
  end

  txns.sort_by(&:date)
end

# --- format writers (each takes the chronological txns + an opening balance) ---

# The running balance is accumulated chronologically, then the rows are emitted newest first
# to match how a real bank statement reads. The third value is the chronological index, used
# for reference numbers that increase over time.
def statement_rows(txns, opening)
  balance = opening
  txns.each_with_index.map do |t, i|
    balance += t.cents
    [ t, balance, i ]
  end.reverse
end

def write_debit_credit_mmdd(file, txns, opening) # comma, MM/DD/YYYY, PHP
  CSV.open(File.join(OUT, file), "w") do |csv|
    csv << %w[Date Reference Description Debit Credit Balance]
    statement_rows(txns, opening).each do |t, balance, i|
      debit  = t.cents.negative? ? fmt(-t.cents) : nil
      credit = t.cents.positive? ? fmt(t.cents) : nil
      csv << [ t.date.strftime("%m/%d/%Y"), "TXN-#{1000 + i}", t.description, debit, credit, fmt(balance) ]
    end
  end
end

def write_signed_iso(file, txns, opening) # comma, ISO, USD, Currency column
  CSV.open(File.join(OUT, file), "w") do |csv|
    csv << %w[Date Description Amount Currency Balance]
    statement_rows(txns, opening).each do |t, balance|
      csv << [ t.date.strftime("%Y-%m-%d"), t.description, fmt(t.cents), "USD", fmt(balance) ]
    end
  end
end

def write_money_in_out_ddmm(file, txns, opening) # semicolon, DD/MM/YYYY, GBP
  CSV.open(File.join(OUT, file), "w", col_sep: ";") do |csv|
    csv << [ "Date", "Details", "Money Out", "Money In", "Balance" ]
    statement_rows(txns, opening).each do |t, balance|
      out = t.cents.negative? ? fmt(-t.cents) : nil
      inn = t.cents.positive? ? fmt(t.cents) : nil
      csv << [ t.date.strftime("%d/%m/%Y"), t.description, out, inn, fmt(balance) ]
    end
  end
end

def write_signed_ddmm_narration(file, txns, opening) # comma, DD/MM/YYYY, ZAR, Narration
  CSV.open(File.join(OUT, file), "w") do |csv|
    csv << [ "Transaction Date", "Narration", "Amount", "Balance" ]
    statement_rows(txns, opening).each do |t, balance|
      csv << [ t.date.strftime("%d/%m/%Y"), t.description, fmt(t.cents), fmt(balance) ]
    end
  end
end

accounts = [
  [ "unionbank.csv",  50_000, :write_debit_credit_mmdd ],
  [ "northwind.csv",  40_000, :write_signed_iso ],
  [ "highstreet.csv", 30_000, :write_money_in_out_ddmm ],
  [ "karoo.csv",      60_000, :write_signed_ddmm_narration ]
]

accounts.each_with_index do |(file, opening, writer), index|
  rng = Random.new(SEED + index)
  txns = generate(rng)
  send(writer, file, txns, opening * 100)
  puts "#{file}: #{txns.size} rows"
end
