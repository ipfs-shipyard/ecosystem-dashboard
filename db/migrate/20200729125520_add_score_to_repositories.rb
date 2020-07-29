class AddScoreToRepositories < ActiveRecord::Migration[6.0]
  def change
    add_column :repositories, :score, :integer, default: 0
  end
end
