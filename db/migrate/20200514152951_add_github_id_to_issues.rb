class AddGithubIdToIssues < ActiveRecord::Migration[6.0]
  def change
    add_column :issues, :github_id, :bigint
  end
end
