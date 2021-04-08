class AddPartnerToOrganization < ActiveRecord::Migration[6.1]
  def change
    add_column :organizations, :partner, :boolean, default: false
  end
end
