class RemovePmfFromEvents < ActiveRecord::Migration[7.1]
  def change
    remove_column :events, :pmf, :boolean
  end
end
