class AddIndexOnHtmlUrl < ActiveRecord::Migration[6.0]
  def change
    add_index :issues, :collabs, using: 'gin'
    add_index :issues, :html_url
  end
end
