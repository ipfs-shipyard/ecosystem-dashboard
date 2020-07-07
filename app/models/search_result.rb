class SearchResult < ApplicationRecord
  belongs_to :search_query

  scope :this_period, ->(period) { where('search_results.created_at > ?', period.days.ago) }
  scope :last_period, ->(period) { where('search_results.created_at > ?', (period*2).days.ago).where('search_results.created_at < ?', period.days.ago) }

  def repository_url
    "https://github.com/#{repository_full_name}"
  end

  def icon_url
    "https://github.com/#{org}.png"
  end
end
