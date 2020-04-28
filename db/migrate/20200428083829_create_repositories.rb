class CreateRepositories < ActiveRecord::Migration[6.0]
  def change
    create_table :repositories do |t|
      t.integer :github_id
      t.string :full_name
      t.string :org
      t.string :language
      t.boolean :archived
      t.boolean :fork
      t.string :description
      t.datetime :pushed_at
      t.integer :size
      t.integer :stargazers_count
      t.integer :open_issues_count
      t.integer :forks_count
      t.integer :subscribers_count
      t.string :default_branch
      t.datetime :last_sync_at

      t.timestamps
    end
  end
end
