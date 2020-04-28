class AddEtagToRepositories < ActiveRecord::Migration[6.0]
  def change
    add_column :repositories, :etag, :string
  end
end
