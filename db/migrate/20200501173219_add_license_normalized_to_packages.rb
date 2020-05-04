class AddLicenseNormalizedToPackages < ActiveRecord::Migration[6.0]
  def change
    add_column :packages, :license_normalized, :boolean, default: false
  end
end
