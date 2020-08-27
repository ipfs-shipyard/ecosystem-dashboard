class AddTriageToRepositories < ActiveRecord::Migration[6.0]
  def change
    add_column :repositories, :triage, :boolean, default: false
  end
end
