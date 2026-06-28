# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_06_28_030000) do
  create_table "active_storage_attachments", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.string "content_type"
    t.datetime "created_at", null: false
    t.string "filename", null: false
    t.string "key", null: false
    t.text "metadata"
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "bank_accounts", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "currency", null: false
    t.text "mapping"
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["user_id"], name: "index_bank_accounts_on_user_id"
  end

  create_table "header_aliases", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "field", null: false
    t.string "pattern", null: false
    t.datetime "updated_at", null: false
    t.index ["pattern"], name: "index_header_aliases_on_pattern", unique: true
  end

  create_table "imports", force: :cascade do |t|
    t.integer "bank_account_id", null: false
    t.datetime "created_at", null: false
    t.integer "duplicate_rows", default: 0, null: false
    t.text "error_message"
    t.integer "failed_rows", default: 0, null: false
    t.string "filename", null: false
    t.integer "imported_rows", default: 0, null: false
    t.string "status", default: "pending", null: false
    t.integer "total_rows", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["bank_account_id"], name: "index_imports_on_bank_account_id"
  end

  create_table "sessions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "ip_address", null: false
    t.string "token", null: false
    t.datetime "updated_at", null: false
    t.string "user_agent", null: false
    t.integer "user_id", null: false
    t.index ["token"], name: "index_sessions_on_token", unique: true
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "transactions", force: :cascade do |t|
    t.integer "amount_cents", null: false
    t.integer "bank_account_id", null: false
    t.datetime "created_at", null: false
    t.string "description", null: false
    t.string "fingerprint", null: false
    t.integer "import_id", null: false
    t.boolean "included", default: true, null: false
    t.date "posted_on", null: false
    t.string "reference"
    t.datetime "updated_at", null: false
    t.index ["bank_account_id", "fingerprint"], name: "index_transactions_on_bank_account_id_and_fingerprint", unique: true
    t.index ["bank_account_id", "posted_on"], name: "index_transactions_on_bank_account_id_and_posted_on"
    t.index ["import_id"], name: "index_transactions_on_import_id"
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email", null: false
    t.string "password_digest", null: false
    t.string "role", default: "customer", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "bank_accounts", "users"
  add_foreign_key "imports", "bank_accounts"
  add_foreign_key "sessions", "users"
  add_foreign_key "transactions", "bank_accounts"
  add_foreign_key "transactions", "imports"
end
