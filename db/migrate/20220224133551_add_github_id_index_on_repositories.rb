class AddGithubIdIndexOnRepositories < ActiveRecord::Migration[7.0]
  def change
    add_index :repositories, :github_id
  end
end
