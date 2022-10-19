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

  def update_repo_names
    update_column(:repository_full_names, Event.where(pmf: true).where('Date(created_at) = ?', date).distinct.pluck(:repository_full_name))
  end
end
