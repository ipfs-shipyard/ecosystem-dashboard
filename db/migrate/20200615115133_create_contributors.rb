class CreateContributors < ActiveRecord::Migration[6.0]
  def change
    create_table :contributors do |t|
      t.string :github_username
      t.integer :github_id
      t.boolean :core, default: false
      t.boolean :bot, default: false

      t.timestamps
    end
  end
end
