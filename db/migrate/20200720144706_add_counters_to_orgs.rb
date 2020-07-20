class AddCountersToOrgs < ActiveRecord::Migration[6.0]
  def change
    add_column :organizations, :search_results_count, :integer, default: 0
    add_column :organizations, :events_count, :integer, default: 0
  end
end
