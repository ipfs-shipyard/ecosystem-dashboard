namespace :issues do
  task sync: :environment do
    Issue.download_active_repos
  end
end
