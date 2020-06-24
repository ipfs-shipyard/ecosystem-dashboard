namespace :issues do
  task sync: :environment do
    Issue.download_active_repos
    Issue.sync_pull_requests
  end

  task sync_collabs: :environment do
    Organization.collaborator.pluck(:name).each do |org|
      Repository.sync_recently_active_repos(org)
    end
  end

  task sync_recent: :environment do
    Repository.sync_recently_active_internal_repos
    Issue.update_collab_labels
  end
end
