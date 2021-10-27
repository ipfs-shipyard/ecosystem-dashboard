class AddKeywordMatchesToRepositories < ActiveRecord::Migration[6.1]
  def change
    add_column :repositories, :keyword_matches, :text
  end
end
