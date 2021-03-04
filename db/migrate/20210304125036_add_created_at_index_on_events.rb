class AddCreatedAtIndexOnEvents < ActiveRecord::Migration[6.1]
  def change
    add_index :events, :created_at
  end
end
