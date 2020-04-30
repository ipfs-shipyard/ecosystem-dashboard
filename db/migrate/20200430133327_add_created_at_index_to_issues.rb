class AddCreatedAtIndexToIssues < ActiveRecord::Migration[6.0]
  def change
    add_index :issues, :created_at
    remove_index :issues, :html_url
  end
end
