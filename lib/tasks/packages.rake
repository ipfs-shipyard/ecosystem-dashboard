namespace :packages do
  task sync_internal: :environment do
    Package.internal.maintained.find_each(&:sync)
  end

  task find_missing_npm_packages: :environment do
    Package.download_internal_dependent_packages
    Repository.find_missing_npm_packages
    Repository.find_missing_cargo_packages
    Repository.find_missing_go_packages
    Organization.where('docker_hub_org is not null').each(&:sync_docker_packages)
  end

  task sync: :environment do
    Package.order('last_synced_at ASC nulls first').limit(100).each(&:sync)
  end

  task find_missing_package_repos: :environment do
    Package.find_missing_package_repos
  end

  task find_dependent_github_repos: :environment do
    Package.find_dependent_github_repos
  end
end
