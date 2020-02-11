class AddOrgToIssues < ActiveRecord::Migration[6.0]
  def change
    add_column :issues, :org, :string
  end
end
