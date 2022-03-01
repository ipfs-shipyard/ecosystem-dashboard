namespace :issues do
  desc 'sync recently active repos from each collaborator org'
  task sync_collabs: :environment do
    Organization.collaborator.each(&:sync_recently_active_repos)
  end

  desc 'sync issues from recently active repositories'
  task sync_recent: :environment do
    Repository.not_internal.triage.each(&:download_issues)
    Repository.not_internal.triage.each(&:sync_events)

    Repository.sync_recently_active_internal_repos
    Issue.update_collab_labels
    Issue.internal.state('open').where('issues.last_synced_at < ? or issues.last_synced_at is null', 1.hour.ago).where('issues.created_at > ?', 1.week.ago).limit(1000).order('issues.last_synced_at asc nulls first, issues.updated_at asc').each(&:sync)
    Organization.collaborator.each(&:update_counts)
  end

  desc 'sync internal issues that have not been synced in over 24 hours'
  task sync_daily: :environment do
    ids = Issue.internal.state('open').where('issues.last_synced_at < ? or issues.last_synced_at is null', 1.day.ago).limit(1000).order('issues.last_synced_at asc nulls first, issues.updated_at asc').pluck(:id)
    Issue.where(id: ids).find_each(&:sync)
  end
end
