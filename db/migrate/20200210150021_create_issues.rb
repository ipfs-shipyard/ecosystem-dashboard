class CreateIssues < ActiveRecord::Migration[6.0]
  def change
    create_table :issues do |t|
      t.string :title
      t.text :body
      t.string :state
      t.integer :number
      t.string :html_url
      t.integer :comments_count
      t.string :user
      t.string :repo_full_name
      t.datetime :closed_at

      t.timestamps
    end
  end
end
