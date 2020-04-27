class AddFirstResponseAtToIssues < ActiveRecord::Migration[6.0]
  def change
    add_column :issues, :first_response_at, :datetime
  end
end
