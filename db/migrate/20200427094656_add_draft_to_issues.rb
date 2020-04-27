class AddDraftToIssues < ActiveRecord::Migration[6.0]
  def change
    add_column :issues, :draft, :boolean
  end
end
