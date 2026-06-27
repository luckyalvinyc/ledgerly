# frozen_string_literal: true

class ImportJob < ApplicationJob
  queue_as :default

  discard_on ActiveJob::DeserializationError

  BATCH_SIZE = ENV.fetch("BATCH_SIZE_IMPORT") { 1_000 }.to_i

  def perform(import)
    claimed = Import
      .where(id: import.id, status: [ :pending, :failed ])
      .update_all(status: :processing, updated_at: Time.current)

    return if claimed.zero?

    import.reload

    bank_account = import.bank_account
    mapper = Csv::Mapper.new(bank_account.mapping.with(currency: bank_account.currency))

    total = 0
    failed = 0

    import.file.open do |file|
      Csv::Parser.foreach(file, mapper:).each_slice(BATCH_SIZE) do |results|
        valid = results.select(&:ok?)
        failed += results.length - valid.length
        total += results.length

        insert(import, rows: valid.map(&:row)) if valid.any?
      end
    end

    owned = import.transactions.count

    import.update!(
      status: :completed,
      total_rows: total,
      imported_rows: owned,
      duplicate_rows: (total - failed) - owned,
      failed_rows: failed
    )
  rescue => e
    import.update!(
      status: :failed,
      error_message: e.message
    )

    raise
  end

  private

    def insert(import, rows:)
      now = Time.current

      attributes = rows.map do |row|
        attributes_for(
          import,
          row: row,
          now: now
        )
      end

      Transaction.insert_all(
        attributes,
        unique_by: [ :bank_account_id, :fingerprint ]
      )
    end

    def attributes_for(import, row:, now:)
      {
        bank_account_id: import.bank_account_id,
        import_id: import.id,
        posted_on: row.posted_on,
        description: row.description,
        reference: row.reference,
        amount_cents: row.amount.cents,
        fingerprint: row.fingerprint,
        created_at: now,
        updated_at: now
      }
    end
end
