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

  task find_direct_dependents_db: :environment do
    internal_packages = Package.internal
    direct_repo_ids = RepositoryDependency.where(package_id: internal_packages.map(&:id), direct: true).pluck(:repository_id).uniq

    names = []
    direct_repo_ids.each do |id|
      repo = Repository.find(id)
      names << repo.full_name
    end

    names.sort.each{|n| puts n };nil
  end

  task find_indirect_dependents_db: :environment do
    internal_package_ids = Package.internal.pluck(:id)

    direct_repo_ids = RepositoryDependency.where(package_id: internal_package_ids, direct: true).pluck(:repository_id).uniq
    indirect_repo_ids = RepositoryDependency.where(package_id: internal_package_ids, direct: false).pluck(:repository_id).uniq
    only_indirect_repo_ids = indirect_repo_ids - direct_repo_ids

    names = []
    only_indirect_repo_ids.each do |id|
      repo = Repository.find(id)
      names << repo.full_name
    end

    names.sort.each{|n| puts n };nil
  end

  task find_direct_dependents_recurse: :environment do
    # TODO
  end

  task find_indirect_dependents_recurse: :environment do
    # TODO
  end
end
