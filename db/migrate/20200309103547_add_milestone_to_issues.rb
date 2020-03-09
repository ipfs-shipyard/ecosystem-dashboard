class AddMilestoneToIssues < ActiveRecord::Migration[6.0]
  def change
    add_column :issues, :milestone_name, :string
    add_column :issues, :milestone_id, :integer
  end
end
