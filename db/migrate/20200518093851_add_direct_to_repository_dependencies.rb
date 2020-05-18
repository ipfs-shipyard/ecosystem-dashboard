class AddDirectToRepositoryDependencies < ActiveRecord::Migration[6.0]
  def change
    add_column :repository_dependencies, :direct, :boolean, default: false
  end
end
