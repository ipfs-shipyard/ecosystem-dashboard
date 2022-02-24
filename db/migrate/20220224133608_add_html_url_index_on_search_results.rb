class AddHtmlUrlIndexOnSearchResults < ActiveRecord::Migration[7.0]
  def change
    add_index :search_results, :html_url
  end
end
