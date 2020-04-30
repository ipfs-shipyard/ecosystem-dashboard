class CreateEvents < ActiveRecord::Migration[6.0]
  def change
    create_table :events do |t|
      t.string :github_id
      t.string :actor
      t.string :event_type
      t.string :action
      t.integer :repository_id
      t.string :repository_full_name
      t.string :org
      t.jsonb :payload, null: false, default: '{}'

      t.timestamps
    end
  end
end
