class AddCollabsToContributors < ActiveRecord::Migration[7.0]
  def change
    add_column :contributors, :collabs, :string, default: [], array: true
  end
end
