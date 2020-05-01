class CreateVersions < ActiveRecord::Migration[6.0]
  def change
    create_table :versions do |t|
      t.integer :package_id
      t.string :number
      t.datetime :published_at
      t.integer :runtime_dependencies_count
      t.string :spdx_expression
      t.jsonb :original_license

      t.timestamps
    end
  end
end
