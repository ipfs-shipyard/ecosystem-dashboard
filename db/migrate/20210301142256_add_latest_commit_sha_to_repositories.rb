class AddLatestCommitShaToRepositories < ActiveRecord::Migration[6.1]
  def change
    add_column :repositories, :latest_commit_sha, :string
    add_column :repositories, :latest_dependency_mine, :datetime
  end
end
