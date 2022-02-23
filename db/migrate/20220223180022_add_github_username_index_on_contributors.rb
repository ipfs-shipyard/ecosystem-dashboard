class AddGithubUsernameIndexOnContributors < ActiveRecord::Migration[7.0]
  def change
    add_index :contributors, :github_username
  end
end
