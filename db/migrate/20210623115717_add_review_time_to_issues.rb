class AddReviewTimeToIssues < ActiveRecord::Migration[6.1]
  def change
    add_column :issues, :review_time, :integer
    add_column :issues, :review_requested_at, :datetime
  end
end
