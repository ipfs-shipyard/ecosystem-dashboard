class AddEtagToOrganizations < ActiveRecord::Migration[6.0]
  def change
    add_column :organizations, :etag, :string
  end
end
