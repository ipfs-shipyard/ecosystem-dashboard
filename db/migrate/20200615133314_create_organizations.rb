class CreateOrganizations < ActiveRecord::Migration[6.0]
  def change
    create_table :organizations do |t|
      t.string :name
      t.integer :github_id
      t.boolean :internal, default: false
      t.boolean :collaborator, default: false

      t.timestamps
    end
  end
end
