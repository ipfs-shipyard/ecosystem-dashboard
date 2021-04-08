class AddBoardIdsToIssues < ActiveRecord::Migration[6.1]
  def change
    add_column :issues, :board_ids, :integer, default: [], array: true
  end
end
