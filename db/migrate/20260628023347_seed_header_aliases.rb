class SeedHeaderAliases < ActiveRecord::Migration[8.1]
  class HeaderAlias < ActiveRecord::Base
    self.table_name = "header_aliases"
  end

  def up
    rows = YAML.load_file(Rails.root.join("db/seeds/header_aliases.yml")).flat_map do |field, patterns|
      patterns.map { |pattern| { field: field, pattern: pattern.strip.upcase } }
    end

    HeaderAlias.upsert_all(rows, unique_by: :pattern)
  end

  def down
    HeaderAlias.delete_all
  end
end
