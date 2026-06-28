class CreateHeaderAliases < ActiveRecord::Migration[8.1]
  def change
    create_table :header_aliases do |t|
      t.string :field, null: false
      t.string :pattern, null: false

      t.timestamps
    end

    add_index :header_aliases, :pattern, unique: true
  end
end
