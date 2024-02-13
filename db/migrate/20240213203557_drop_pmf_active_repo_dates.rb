class DropPmfActiveRepoDates < ActiveRecord::Migration[7.1]
  def change
    drop_table :pmf_active_repo_dates
  end
end
