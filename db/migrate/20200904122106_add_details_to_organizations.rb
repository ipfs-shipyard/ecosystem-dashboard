class AddDetailsToOrganizations < ActiveRecord::Migration[6.0]
  def change
    add_column :organizations, :url, :string
    add_column :organizations, :description, :string
    add_column :organizations, :email, :string
    add_column :organizations, :location, :string
    add_column :organizations, :verified, :boolean
    add_column :organizations, :display_name, :string
    add_column :organizations, :company, :string
    add_column :organizations, :twitter, :string
    add_column :organizations, :last_synced_at, :datetime
  end
end
