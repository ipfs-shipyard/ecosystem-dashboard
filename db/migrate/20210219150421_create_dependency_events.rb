class CreateDependencyEvents < ActiveRecord::Migration[6.1]
  def change
    create_table :dependency_events do |t|
      t.references :repository, index: true
      t.references :package, index: true
      t.string :action
      t.string :package_name
      t.string :commit_message
      t.string :requirement
      t.string :kind
      t.string :manifest_path
      t.string :manifest_kind
      t.string :branch
      t.string :commit_sha
      t.string :platform
      t.string :previous_requirement
      t.string :previous_kind
      t.datetime :committed_at, index: true
    end
  end
end
