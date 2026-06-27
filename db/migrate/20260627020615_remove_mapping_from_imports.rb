class RemoveMappingFromImports < ActiveRecord::Migration[8.1]
  def change
    remove_column :imports, :mapping, :text
  end
end
