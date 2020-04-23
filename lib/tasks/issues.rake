namespace :issues do
  task sync: :environment do
    Issue.download_active_repos
    Issue.download_new_repos
    Issue.update_collab_labels
  end

  task sync_collabs: :environment do
    Issue.download_active_collab_repos
    Issue.download_new_collab_repos
    Issue.update_collab_labels
  end
end
