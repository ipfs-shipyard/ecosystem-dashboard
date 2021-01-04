class AddInternalDependencyArraysToRepositories < ActiveRecord::Migration[6.1]
  def change
    add_column :repositories, :direct_internal_dependency_package_ids, :integer, default: [], array: true
    add_column :repositories, :indirect_internal_dependency_package_ids, :integer, default: [], array: true
  end
end
