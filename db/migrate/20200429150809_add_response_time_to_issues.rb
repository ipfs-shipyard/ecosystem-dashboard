class AddResponseTimeToIssues < ActiveRecord::Migration[6.0]
  def change
    add_column :issues, :response_time, :integer
  end
end
