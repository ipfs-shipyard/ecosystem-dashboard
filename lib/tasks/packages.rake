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

  task find_direct_dependent_repos: :environment do
    internal_package_ids = Package.internal.pluck(:id)
    direct_repo_ids = RepositoryDependency.where(package_id: internal_package_ids, direct: true).pluck(:repository_id).uniq

    names = []
    direct_repo_ids.each do |id|
      repo = Repository.find(id)
      names << repo.full_name
    end

    names.sort.each{|n| puts n };nil
    puts "#{direct_repo_ids.length} direct dependent repos total"
  end

  task find_indirect_dependent_repos: :environment do
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

    puts "#{only_indirect_repo_ids.length} indirect dependent repos total"
  end

  task find_direct_dependent_packages: :environment do
    internal_package_ids = Package.internal.pluck(:id)
    direct_version_ids = Dependency.where(package_id: internal_package_ids).pluck(:version_id).uniq

    direct_package_ids = Version.where(id: direct_version_ids).pluck(:package_id).uniq

    names = []
    direct_package_ids.each do |id|
      package = Package.find(id)
      names << "#{package.platform_name}/#{package.name}"
    end

    names.sort.each{|n| puts n };nil

    puts "#{direct_package_ids.length} direct dependent packages total"
  end

  task find_indirect_dependent_packages: :environment do
    internal_package_ids = Package.internal.pluck(:id)

    order = 1
    puts "# 1st order"
    exclude_package_ids = []
    dependent_package_ids = internal_package_ids

    all_indirect_dependent_ids = []

    while dependent_package_ids.length > 0 do
      order += 1
      puts ""
      puts "# #{order.ordinalize} order"
      exclude_package_ids = (exclude_package_ids + dependent_package_ids).uniq
      dependent_package_ids = load_dependents(dependent_package_ids, exclude_package_ids)
      all_indirect_dependent_ids = (all_indirect_dependent_ids + dependent_package_ids).uniq
    end

    puts "#{all_indirect_dependent_ids.length} indirect dependent packages total"
  end

  task find_indirect_dependent_recursive_repos: :environment do
    internal_package_ids = Package.internal.pluck(:id)

    exclude_package_ids = []
    dependent_package_ids = internal_package_ids
    all_indirect_dependent_ids = []

    while dependent_package_ids.length > 0 do
      exclude_package_ids = (exclude_package_ids + dependent_package_ids).uniq
      dependent_package_ids = load_dependents(dependent_package_ids, exclude_package_ids, false)
      all_indirect_dependent_ids = (all_indirect_dependent_ids + dependent_package_ids).uniq
    end

    indirect_repo_ids = RepositoryDependency.where(package_id: all_indirect_dependent_ids).pluck(:repository_id).uniq

    names = []
    indirect_repo_ids.each do |id|
      repo = Repository.find(id)
      names << repo.full_name
    end

    names.sort.each{|n| puts n };nil
    puts "#{indirect_repo_ids.length} indirect dependent repos total"
  end

  task indirect_diff: :environment do
    internal_package_ids = Package.internal.pluck(:id)

    direct_repo_ids = RepositoryDependency.where(package_id: internal_package_ids, direct: true).pluck(:repository_id).uniq
    indirect_repo_ids = RepositoryDependency.where(package_id: internal_package_ids, direct: false).pluck(:repository_id).uniq
    only_indirect_repo_ids = indirect_repo_ids - direct_repo_ids


    exclude_package_ids = []
    dependent_package_ids = internal_package_ids
    all_indirect_dependent_ids = []

    while dependent_package_ids.length > 0 do
      exclude_package_ids = (exclude_package_ids + dependent_package_ids).uniq
      dependent_package_ids = load_dependents(dependent_package_ids, exclude_package_ids, false)
      all_indirect_dependent_ids = (all_indirect_dependent_ids + dependent_package_ids).uniq
    end

    indirect_repo_ids = RepositoryDependency.where(package_id: all_indirect_dependent_ids).pluck(:repository_id).uniq

    diff = indirect_repo_ids - only_indirect_repo_ids - direct_repo_ids

    names = []
    diff.each do |id|
      repo = Repository.find(id)
      names << repo.full_name
    end

    names.sort.each{|n| puts n };nil
    puts "#{diff.length} indirect repos diff total"
  end
end

def load_dependents(package_ids, exclude_package_ids, log = true)
  version_ids = Dependency.where(package_id: package_ids).pluck(:version_id).uniq
  direct_package_ids = Version.where(id: version_ids).pluck(:package_id).uniq

  only_package_ids = direct_package_ids - exclude_package_ids

  if log
    names = []
    only_package_ids.each do |id|
      package = Package.find(id)
      names << "#{package.platform_name}/#{package.name}"
    end

    names.sort.each{|n| puts n };nil
  end

  return only_package_ids
end
