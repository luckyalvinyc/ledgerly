class AddMappingToBankAccounts < ActiveRecord::Migration[8.1]
  def change
    add_column :bank_accounts, :mapping, :text
  end
end
