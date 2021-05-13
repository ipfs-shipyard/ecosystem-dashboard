class AddRepositoryDependenciesIndex < ActiveRecord::Migration[6.1]
  def change
    add_index :repository_dependencies, :package_name
  end
end
