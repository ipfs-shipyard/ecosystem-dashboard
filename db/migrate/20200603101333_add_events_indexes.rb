class AddEventsIndexes < ActiveRecord::Migration[6.0]
  def change
    add_index :events, :actor
    add_index :events, :github_id
  end
end
