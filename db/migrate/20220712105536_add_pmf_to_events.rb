class AddPmfToEvents < ActiveRecord::Migration[7.0]
  def change
    add_column :events, :pmf, :boolean
    add_index :events, :pmf
  end
end
