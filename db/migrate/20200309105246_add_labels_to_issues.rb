class AddLabelsToIssues < ActiveRecord::Migration[6.0]
  def change
    add_column :issues, :labels, :string, default: [], array: true
  end
end
