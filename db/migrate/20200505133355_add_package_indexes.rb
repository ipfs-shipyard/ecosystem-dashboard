class AddPackageIndexes < ActiveRecord::Migration[6.0]
  def change
    add_index :manifests, :repository_id
    add_index :packages, [:platform, :name], unique: true
    add_index :repository_dependencies, :manifest_id
    add_index :repository_dependencies, :repository_id
    add_index :repository_dependencies, :package_id
    add_index :dependencies, :package_id
    add_index :dependencies, :version_id
    add_index :versions, [:package_id, :number], :unique => true
  end
end
