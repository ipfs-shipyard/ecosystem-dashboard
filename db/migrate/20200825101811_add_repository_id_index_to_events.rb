class AddRepositoryIdIndexToEvents < ActiveRecord::Migration[6.0]
  def change
    add_index :events, :repository_id
  end
end
