class AddLastEventsSyncAtToContributors < ActiveRecord::Migration[6.1]
  def change
    add_column :contributors, :last_events_sync_at, :datetime
    add_column :contributors, :etag, :string
  end
end
