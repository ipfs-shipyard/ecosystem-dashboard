class AddTopicsToRepositories < ActiveRecord::Migration[6.0]
  def change
    add_column :repositories, :topics, :string, default: [], array: true
  end
end
