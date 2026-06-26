class CreateImports < ActiveRecord::Migration[8.1]
  def change
    create_table :imports do |t|
      t.references :bank_account, null: false, foreign_key: true
      t.string :filename, null: false
      t.string :status, null: false, default: "pending"
      t.integer :total_rows, null: false, default: 0
      t.integer :imported_rows, null: false, default: 0
      t.integer :duplicate_rows, null: false, default: 0
      t.integer :failed_rows, null: false, default: 0
      t.text :error_message
      t.timestamps
    end
  end
end
