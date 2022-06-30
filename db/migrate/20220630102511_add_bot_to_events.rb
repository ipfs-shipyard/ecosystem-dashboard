class AddBotToEvents < ActiveRecord::Migration[7.0]
  def change
    add_column :events, :bot, :boolean
  end
end
