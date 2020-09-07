class AddHtmlUrlUniqueConstraintToIssues < ActiveRecord::Migration[6.0]
  def change
    add_index :issues, :html_url, unique: true
  end
end
