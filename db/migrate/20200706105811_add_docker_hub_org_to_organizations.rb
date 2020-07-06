class AddDockerHubOrgToOrganizations < ActiveRecord::Migration[6.0]
  def change
    add_column :organizations, :docker_hub_org, :string
  end
end
