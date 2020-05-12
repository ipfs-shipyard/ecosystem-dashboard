class AddOutdatedPercentageToPackages < ActiveRecord::Migration[6.0]
  def change
    add_column :packages, :outdated, :integer
  end
end
