class AddLockedToIssues < ActiveRecord::Migration[6.0]
  def change
    add_column :issues, :locked, :boolean
  end
end
