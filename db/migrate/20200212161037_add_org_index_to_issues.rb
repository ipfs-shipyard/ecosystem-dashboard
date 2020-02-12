class AddOrgIndexToIssues < ActiveRecord::Migration[6.0]
  def change
    add_index :issues, :org
    add_index :issues, :state
    add_index :issues, :user
    add_index :issues, :repo_full_name
  end
end
