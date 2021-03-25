class AddMissingIndexes < ActiveRecord::Migration[6.1]
  def change
    add_index :repositories, :full_name
    add_index :search_results, :created_at
    add_index :search_results, :repository_full_name
  end
end
