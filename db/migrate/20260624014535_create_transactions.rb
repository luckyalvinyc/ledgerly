class CreateTransactions < ActiveRecord::Migration[8.1]
  def change
    create_table :transactions do |t|
      t.references :bank_account, null: false, foreign_key: true, index: false
      t.references :import, null: false, foreign_key: true
      t.date :posted_on, null: false
      t.string :description, null: false
      t.string :reference
      t.integer :amount_cents, null: false
      t.integer :balance_cents
      t.string :fingerprint, null: false
      t.boolean :included, null: false, default: true
      t.timestamps
    end

    add_index :transactions, [ :bank_account_id, :fingerprint ], unique: true
    add_index :transactions, [ :bank_account_id, :posted_on ]
  end
end
