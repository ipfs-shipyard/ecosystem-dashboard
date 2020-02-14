namespace :issues do
  task sync: :environment do
    Issue.download_active_repos
    Isssue.update_collab_labels
  end
end
