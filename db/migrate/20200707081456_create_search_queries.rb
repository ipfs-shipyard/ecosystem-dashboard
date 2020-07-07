class CreateSearchQueries < ActiveRecord::Migration[6.0]
  def change
    create_table :search_queries do |t|
      t.string :query
      t.string :kind
      t.string :sort
      t.string :order

      t.timestamps
    end
  end
end
