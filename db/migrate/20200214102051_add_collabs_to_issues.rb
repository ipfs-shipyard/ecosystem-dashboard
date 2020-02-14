class AddCollabsToIssues < ActiveRecord::Migration[6.0]
  def change
    add_column :issues, :collabs, :string, default: [], array: true
  end
end
