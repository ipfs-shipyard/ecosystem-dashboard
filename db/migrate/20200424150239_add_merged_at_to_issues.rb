class AddMergedAtToIssues < ActiveRecord::Migration[6.0]
  def change
    add_column :issues, :merged_at, :datetime
  end
end
