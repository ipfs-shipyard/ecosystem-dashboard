class AddDiscoveredToRepositories < ActiveRecord::Migration[6.1]
  def change
    add_column :repositories, :discovered, :boolean, default: false
  end
end
