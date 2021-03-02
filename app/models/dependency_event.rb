class DependencyEvent < ApplicationRecord
  belongs_to :repository
  belongs_to :package

  scope :internal, -> { where(package_id: Package.internal.pluck(:id)) }

  scope :platform, ->(platform) { where(platform: platform) }
  scope :action, ->(action) { where(action: action) }

  scope :this_period, ->(period) { where('dependency_events.committed_at > ?', period.days.ago) }
  scope :last_period, ->(period) { where('dependency_events.committed_at > ?', (period*2).days.ago).where('dependency_events.committed_at < ?', period.days.ago) }
  scope :this_week, -> { where('dependency_events.committed_at > ?', 1.week.ago) }
  scope :last_week, -> { where('dependency_events.committed_at > ?', 2.week.ago).where('dependency_events.committed_at < ?', 1.week.ago) }

  scope :created_before, ->(datetime) { where('dependency_events.committed_at < ?', datetime) }
  scope :created_after, ->(datetime) { where('dependency_events.committed_at > ?', datetime) }
end
