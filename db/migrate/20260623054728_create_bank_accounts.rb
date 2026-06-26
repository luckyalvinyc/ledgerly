class CreateBankAccounts < ActiveRecord::Migration[8.1]
  def change
    create_table :bank_accounts do |t|
      t.references :user, null: false, foreign_key: true
      t.string :name, null: false
      t.string :currency, null: false
      t.timestamps
    end
  end
end
