class AddLastSyncedAtToIssues < ActiveRecord::Migration[6.0]
  def change
    add_column :issues, :last_synced_at, :datetime
  end
end
