class AddSolFilesToRepositories < ActiveRecord::Migration[6.1]
  def change
    add_column :repositories, :sol_files, :boolean, default: false
  end
end
