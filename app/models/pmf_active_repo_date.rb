class PmfActiveRepoDate < ApplicationRecord
  def self.fetch_by_date(date)
    find_by_date(date) || create_by_date(date)
  end

  def self.create_by_date(date)
    names = Event.where(pmf: true).where('Date(created_at) = ?', date).distinct.pluck(:repository_full_name)
    create(date: date, repository_full_names: names)
  end

  def self.update_by_date(date)
    if record = find_by_date(date)
      record.update_repo_names
    else
      create_by_date(date)
    end
  end

  def self.generate_all
    start_date = Event.where(pmf: true).first.created_at.to_date

    (start_date..Date.today).each do |date|
      PmfActiveRepoDate.update_by_date(date)
    end
  end

  def self.regenerate_recent
    (1.week.ago.to_date..Date.today).each do |date|
      PmfActiveRepoDate.update_pmf_events(date)
      PmfActiveRepoDate.update_by_date(date)
    end
  end

  def update_repo_names
    update_column(:repository_full_names, Event.where(pmf: true).where('Date(created_at) = ?', date).distinct.pluck(:repository_full_name))
  end

  def self.update_pmf_events(date)
    Event.humans.not_core.where.not(event_type: ['WatchEvent', 'MemberEvent', 'PublicEvent']).where(pmf: nil).where('Date(created_at) = ?', date).in_batches(of: 1000).update_all(pmf: true)
  end
end

