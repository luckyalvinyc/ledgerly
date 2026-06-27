class AddMappingToImports < ActiveRecord::Migration[8.1]
  def change
    add_column :imports, :mapping, :text
  end
end
