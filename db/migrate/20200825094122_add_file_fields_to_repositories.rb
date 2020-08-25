class AddFileFieldsToRepositories < ActiveRecord::Migration[6.0]
  def change
    add_column :repositories, :readme_path, :string
    add_column :repositories, :code_of_conduct_path, :string
    add_column :repositories, :contributing_path, :string
    add_column :repositories, :license_path, :string
    add_column :repositories, :changelog_path, :string
  end
end
