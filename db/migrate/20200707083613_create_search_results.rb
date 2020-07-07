class CreateSearchResults < ActiveRecord::Migration[6.0]
  def change
    create_table :search_results do |t|
      t.integer :search_query_id
      t.string :kind
      t.string :repository_full_name
      t.string :org
      t.string :title
      t.string :html_url
      t.jsonb :text_matches, null: false, default: '{}'

      t.timestamps
    end
  end
end
