class CreateDependencies < ActiveRecord::Migration[6.0]
  def change
    create_table :dependencies do |t|
      t.integer :version_id
      t.integer :package_id
      t.string :package_name
      t.string :platform
      t.string :kind
      t.boolean :optional, default: false
      t.string :requirements

      t.timestamps
    end
  end
end
