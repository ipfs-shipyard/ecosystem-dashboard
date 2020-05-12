class AddCollabDependentRepositoriesCountToPackages < ActiveRecord::Migration[6.0]
  def change
    add_column :packages, :collab_dependent_repos_count, :integer
  end
end
