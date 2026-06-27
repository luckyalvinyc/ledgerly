# frozen_string_literal: true

require "test_helper"

class ImportTest < ActionDispatch::IntegrationTest
  setup do
    @user = sign_in
  end

  test "imports a statement with debit and credit columns" do
    bank_account = @user.bank_accounts.create!(
      name: "Bank A",
      currency: "PHP"
    )

    file = create_csv_file do |csv|
      csv << [ "DATE", "REFERENCE NO", "DESCRIPTION", "DEBIT", "CREDIT", "ENDING BALANCE" ]
      csv << [ "06/21/2026", "UB620001", "SOFTWARE SUBSCRIPTION", "2392.60", nil, "48017.48" ]
    end

    post bank_account_imports_path(bank_account), params: {
      file: file
    }

    import = bank_account.imports.sole

    assert_enqueued_with(job: ImportJob) do
      post confirm_import_path(import), params: { mapping: detected_mapping(import) }
    end

    perform_enqueued_jobs

    assert_equal "completed", import.reload.status
    assert_equal 1, bank_account.transactions.count

    transaction = bank_account.transactions.find_by(reference: "UB620001")
    assert transaction
    assert_equal Date.new(2026, 6, 21), transaction.posted_on
    assert_equal (-239260), transaction.amount_cents
    assert_equal 4801748, transaction.balance_cents
    assert_equal "SOFTWARE SUBSCRIPTION", transaction.description
    assert transaction.included
  end

  test "re-importing a statement adds no duplicates" do
    bank_account = @user.bank_accounts.create!(
      name: "Bank A",
      currency: "PHP"
    )

    file = create_csv_file do |csv|
      csv << [ "DATE", "REFERENCE NO", "DESCRIPTION", "DEBIT", "CREDIT", "ENDING BALANCE" ]
      csv << [ "06/21/2026", "UB620001", "SOFTWARE SUBSCRIPTION", "2392.60", nil, "48017.48" ]
    end

    post bank_account_imports_path(bank_account), params: {
      file: file
    }

    first_import = bank_account.imports.sole

    confirm_import(first_import)

    first_import.reload
    assert_equal 1, first_import.total_rows
    assert_equal 1, first_import.imported_rows
    assert_equal 0, first_import.duplicate_rows
    assert_equal 0, first_import.failed_rows

    transactions = bank_account.transactions
    assert_equal 1, transactions.count

    post bank_account_imports_path(bank_account), params: {
      file: file
    }

    second_import = bank_account.imports.last
    assert_not_equal second_import, first_import

    confirm_import(second_import)

    second_import.reload
    assert_equal 1, second_import.total_rows
    assert_equal 0, second_import.imported_rows
    assert_equal 1, second_import.duplicate_rows
    assert_equal 0, second_import.failed_rows

    assert_equal 1, transactions.reload.count
  end

  test "a malformed row is skipped and counted, the rest import" do
    bank_account = @user.bank_accounts.create!(
      name: "Bank A",
      currency: "PHP"
    )

    file = create_csv_file do |csv|
      csv << [ "DATE", "REFERENCE NO", "DESCRIPTION", "DEBIT", "CREDIT", "ENDING BALANCE" ]
      csv << [ "06/21/2026", "OK1", "Valid expense", "100.00", nil, "5000.00" ]
      csv << [ "06/20/2026", "BAD1", "No amount", nil, nil, "4900.00" ]
    end

    post bank_account_imports_path(bank_account), params: {
      file: file
    }

    import = bank_account.imports.sole

    confirm_import(import)

    import.reload
    assert_equal "completed", import.status
    assert_equal 2, import.total_rows
    assert_equal 1, import.imported_rows
    assert_equal 1, import.failed_rows
    assert_equal 0, import.duplicate_rows
    assert_equal 1, bank_account.transactions.count
  end

  test "imports a statement with a single signed amount" do
    bank_account = @user.bank_accounts.create!(
      name: "Bank A",
      currency: "PHP"
    )

    file = create_csv_file do |csv|
      csv << [ "Date", "Description", "Amount", "Currency", "Running Balance" ]
      csv << [ "2026-06-01", "Stripe payout", "9800.00", "USD", "50877.70" ]
      csv << [ "2026-06-20", "Monthly bank fee", "-25.00", "USD", "41077.70" ]
    end

    post bank_account_imports_path(bank_account), params: {
      file: file
    }

    import = bank_account.imports.sole

    confirm_import(import)

    assert_equal 2, bank_account.transactions.count

    transaction = bank_account.transactions.find_by(posted_on: Date.new(2026, 6, 1))
    assert transaction
    assert_equal 980000, transaction.amount_cents
    assert_equal 5087770, transaction.balance_cents
    assert_equal "Stripe payout", transaction.description

    transaction = bank_account.transactions.find_by(posted_on: Date.new(2026, 6, 20))
    assert transaction
    assert_equal (-2500), transaction.amount_cents
    assert_equal 4107770, transaction.balance_cents
    assert_equal "Monthly bank fee", transaction.description
  end

  test "the sample bank statements all import" do
    {
      "signed_amount.csv" => "USD",
      "debit_credit_amount.csv" => "PHP"
    }.each do |filename, currency|
      bank_account = @user.bank_accounts.create!(
        name: filename,
        currency: currency
      )

      file = fixture_file_upload("bank_transactions/#{filename}")

      post bank_account_imports_path(bank_account), params: {
        file: file
      }

      import = bank_account.imports.sole

      confirm_import(import)

      import.reload
      assert_equal "completed", import.status
      assert_operator import.transactions.count, :>, 0
    end
  end

  test "the preview flags rows it cannot read with the current mapping" do
    bank_account = @user.bank_accounts.create!(name: "Bank A", currency: "PHP")

    file = create_csv_file do |csv|
      csv << [ "Date", "Description", "Amount" ]
      csv << [ "31/01/2026", "Rent", "-1000.00" ]
    end
    post bank_account_imports_path(bank_account), params: { file: file }
    import = bank_account.imports.sole

    post preview_import_path(import), params: {
      mapping: {
        delimiter: ",",
        amount_strategy: "signed",
        date_format: "%m/%d/%Y",
        column_map: { date: "Date", description: "Description", amount: "Amount" }
      }
    }

    assert_response :success
    assert_includes response.body, "read any transactions"
  end

  test "confirming with an edited mapping imports using that mapping" do
    bank_account = @user.bank_accounts.create!(name: "Bank A", currency: "USD")

    file = create_csv_file do |csv|
      csv << [ "Date", "Description", "Amount" ]
      csv << [ "01/02/2026", "Sale", "500.00" ]
    end
    post bank_account_imports_path(bank_account), params: { file: file }
    import = bank_account.imports.sole

    perform_enqueued_jobs do
      post confirm_import_path(import), params: {
        mapping: {
          delimiter: ",",
          amount_strategy: "signed",
          date_format: "%d/%m/%Y",
          column_map: { date: "Date", description: "Description", amount: "Amount" }
        }
      }
    end

    transaction = bank_account.transactions.sole
    assert_equal Date.new(2026, 2, 1), transaction.posted_on
  end

  test "confirming an incomplete mapping does not import" do
    bank_account = @user.bank_accounts.create!(name: "Bank A", currency: "USD")

    file = create_csv_file do |csv|
      csv << [ "Date", "Description", "Amount" ]
      csv << [ "2026-06-01", "Sale", "500.00" ]
    end
    post bank_account_imports_path(bank_account), params: { file: file }
    import = bank_account.imports.sole

    assert_no_enqueued_jobs do
      post confirm_import_path(import), params: {
        mapping: {
          delimiter: ",",
          amount_strategy: "signed",
          date_format: "%Y-%m-%d",
          column_map: { date: "Date", description: "Description", amount: "" }
        }
      }
    end

    assert_response :unprocessable_content
    assert import.reload.reviewing?
  end

  test "remembers the mapping for the next import to the same bank" do
    bank_account = @user.bank_accounts.create!(name: "Bank A", currency: "USD")

    file = create_csv_file do |csv|
      csv << [ "Date", "Description", "Amount" ]
      csv << [ "01/02/2026", "Sale", "500.00" ]
    end
    post bank_account_imports_path(bank_account), params: { file: file }
    first = bank_account.imports.sole

    post confirm_import_path(first), params: {
      mapping: {
        delimiter: ",",
        amount_strategy: "signed",
        date_format: "%d/%m/%Y",
        column_map: { date: "Date", description: "Description", amount: "Amount" }
      }
    }

    assert_equal "%d/%m/%Y", bank_account.reload.mapping.date_format

    file = create_csv_file do |csv|
      csv << [ "Date", "Description", "Amount" ]
      csv << [ "03/04/2026", "Sale", "100.00" ]
    end
    post bank_account_imports_path(bank_account), params: { file: file }
    second = bank_account.imports.where.not(id: first.id).sole

    get review_import_path(second)
    assert_response :success
    assert_select "select[name=?] option[selected][value=?]", "mapping[date_format]", "%d/%m/%Y"
  end

  test "falls back to detection when the bank changes its format" do
    bank_account = @user.bank_accounts.create!(name: "Bank A", currency: "USD")

    file = create_csv_file do |csv|
      csv << [ "Date", "Description", "Amount" ]
      csv << [ "2026-01-01", "Sale", "100.00" ]
    end
    post bank_account_imports_path(bank_account), params: { file: file }
    confirm_import(bank_account.imports.sole)

    file = create_csv_file do |csv|
      csv << [ "Posting Date", "Narration", "Money In", "Money Out" ]
      csv << [ "2026-02-01", "Refund", "50.00", nil ]
    end
    post bank_account_imports_path(bank_account), params: { file: file }
    second = bank_account.imports.where(status: :reviewing).sole

    get review_import_path(second)

    assert_response :success
    assert_includes response.body, "Refund"
    assert_not_includes response.body, "read any transactions"
  end
end
