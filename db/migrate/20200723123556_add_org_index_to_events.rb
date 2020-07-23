class AddOrgIndexToEvents < ActiveRecord::Migration[6.0]
  def change
    add_index :events, [:org, :event_type]
  end
end
