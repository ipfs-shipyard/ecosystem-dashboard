namespace :packages do
  task sync_internal: :environment do
    Package.internal.maintained.find_each(&:sync)
  end

  task find_missing_npm_packages: :environment do
    Repository.find_missing_npm_packages
  end
end
