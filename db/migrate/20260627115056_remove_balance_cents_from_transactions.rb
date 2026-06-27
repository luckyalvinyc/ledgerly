class RemoveBalanceCentsFromTransactions < ActiveRecord::Migration[8.1]
  def change
    remove_column :transactions, :balance_cents, :integer
  end
end
