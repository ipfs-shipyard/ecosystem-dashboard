class DropDependencyEvents < ActiveRecord::Migration[7.1]
  def change
    drop_table :dependency_events
  end
end
