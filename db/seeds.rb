# frozen_string_literal: true

# Demo seed. Idempotent and deterministic: the data comes from fixed CSV files
# under db/seeds/statements, imported through the real pipeline, so re-running
# never changes the result. The same files double as upload material for the
# live demo.

# Always (re)set the demo password so re-seeding rehashes it with the current Argon2 pepper.
demo = User.find_or_initialize_by(email: "demo@ledgerly.app")
demo.password = "DemoPassw0rd!"
demo.save!

statements = [
  { name: "UnionBank",         currency: "PHP", file: "unionbank_php.csv" },
  { name: "Northwind Trading", currency: "USD", file: "northwind_usd.csv" },
  { name: "High Street Co",    currency: "GBP", file: "highstreet_gbp.csv" },
  { name: "Karoo Supplies",    currency: "ZAR", file: "karoo_zar.csv" }
]

statements.each do |statement|
  account = demo.bank_accounts.find_or_create_by!(name: statement[:name]) do |a|
    a.currency = statement[:currency]
  end

  next if account.transactions.any?

  path = Rails.root.join("db/seeds/statements", statement[:file])

  import = account.imports.new(filename: statement[:file], status: :pending)
  import.file.attach(io: File.open(path), filename: statement[:file], content_type: "text/csv")
  import.save!

  account.update!(mapping: import.file.open { |io| Csv::Detect.call(io) }.with(currency: account.currency))

  ImportJob.perform_now(import)
end

puts "Seeded #{demo.bank_accounts.count} accounts, #{demo.transactions.count} transactions for #{demo.email}"
