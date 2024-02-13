class DropPmfIndex < ActiveRecord::Migration[7.1]
  def change
    remove_index :events, name: "index_events_on_pmf"
  end
end
