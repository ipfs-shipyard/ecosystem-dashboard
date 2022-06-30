class AddCoreToEvents < ActiveRecord::Migration[7.0]
  def change
    add_column :events, :core, :boolean
  end
end
