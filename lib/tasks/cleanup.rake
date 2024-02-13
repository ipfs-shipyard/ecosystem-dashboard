namespace :cleanup do
  desc "Cleanup repositories"
  task repos: :environment do
    Repository.community.without_internal_deps.find_each(&:destroy)
  end
end
