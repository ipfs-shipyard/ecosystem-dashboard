class AddLastEventsSyncAtToRepositories < ActiveRecord::Migration[6.1]
  def change
    add_column :repositories, :last_events_sync_at, :datetime
  end
end
