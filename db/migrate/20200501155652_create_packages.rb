class CreatePackages < ActiveRecord::Migration[6.0]
  def change
    create_table :packages do |t|
      t.string :name
      t.string :platform
      t.text :description
      t.text :keywords
      t.string :homepage
      t.string :licenses
      t.string :repository_url
      t.integer :repository_id
      t.string :normalized_licenses, default: [], array: true
      t.integer :versions_count, default: 0, null: false
      t.datetime :latest_release_published_at
      t.string :latest_release_number
      t.string :keywords_array, default: [], array: true
      t.integer :dependents_count, default: 0, null: false
      t.string :language
      t.string :status
      t.datetime :last_synced_at
      t.integer :dependent_repos_count
      t.integer :runtime_dependencies_count
      t.string :latest_stable_release_number
      t.string :latest_stable_release_published_at

      t.timestamps
    end
  end
end
