namespace :issues do
  task sync: :environment do
    Issue.download_active_repos
    Issue.download_new_repos
    Issue.sync_pull_requests
  end

  task sync_collabs: :environment do
    Issue.external.group(:org).count.each do |org, _count|
      Repository.sync_recently_active_repos(org)
    end
  end

  task sync_recent: :environment do
    Repository.sync_recently_active_internal_repos
    Issue.update_collab_labels
  end
end
