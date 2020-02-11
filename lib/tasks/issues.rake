namespace :issues do
  task sync: :environment do
    Issues.download_active_repos
  end
end
