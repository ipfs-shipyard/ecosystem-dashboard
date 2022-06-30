class AddContributorsIndex < ActiveRecord::Migration[7.0]
  def change
    add_index :contributors, :core
    add_index :contributors, :bot
  end
end
