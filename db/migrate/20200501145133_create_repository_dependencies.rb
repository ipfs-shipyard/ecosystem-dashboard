class CreateRepositoryDependencies < ActiveRecord::Migration[6.0]
  def change
    create_table :repository_dependencies do |t|
      t.integer :package_id
      t.integer :manifest_id
      t.integer :repository_id
      t.boolean :optional
      t.string :package_name
      t.string :platform
      t.string :requirements
      t.string :kind

      t.timestamps
    end
  end
end
