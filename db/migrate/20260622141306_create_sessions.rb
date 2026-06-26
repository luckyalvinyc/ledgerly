class CreateSessions < ActiveRecord::Migration[8.1]
  def change
    create_table :sessions do |t|
      t.references :user, null: false, foreign_key: true
      t.string :token, null: false, index: { unique: true }
      t.string :ip_address, null: false
      t.string :user_agent, null: false
      t.timestamps
    end
  end
end
