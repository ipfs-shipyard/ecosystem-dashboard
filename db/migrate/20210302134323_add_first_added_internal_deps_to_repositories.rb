class AddFirstAddedInternalDepsToRepositories < ActiveRecord::Migration[6.1]
  def change
    add_column :repositories, :first_added_internal_deps, :datetime
    add_column :repositories, :last_internal_dep_removed, :datetime
  end
end
