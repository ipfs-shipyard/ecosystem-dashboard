class CreatePmfActiveRepoDates < ActiveRecord::Migration[7.0]
  def change
    create_table :pmf_active_repo_dates do |t|
      t.date :date, index: true
      t.string :repository_full_names, array: true, default: []

      t.timestamps
    end
  end
end
