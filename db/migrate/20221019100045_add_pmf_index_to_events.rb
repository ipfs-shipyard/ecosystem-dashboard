class AddPmfIndexToEvents < ActiveRecord::Migration[7.0]
  def change
    add_index :events, 'date(created_at)'
  end
end
