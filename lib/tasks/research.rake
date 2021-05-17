namespace :research do
  task arweave: :environment do
    # download all the repos
    o = Organization.find_or_create_by(name: 'ArweaveTeam')
    Repository.import_org(o.name)

    # # find all the arweave packages
    Repository.archived(false).org(o.name).find_missing_npm_packages
    Repository.archived(false).org(o.name).find_missing_cargo_packages
    Repository.archived(false).org(o.name).find_missing_go_packages

    # # download dependents of each package
    o.packages.each(&:find_dependent_github_repos)

    # output the unique list of total dependents
    repos = []

    o.packages.each do |pkg|
      repos << pkg.dependent_repositories
    end


    exclude_fields = ['direct_internal_dependency_package_ids', 'indirect_internal_dependency_package_ids']

    scope = Repository.internal
    csv_string = CSV.generate do |csv|
      csv << Repository.attribute_names.excluding(exclude_fields) + ['direct_internal_dependency_package_names', 'indirect_internal_dependency_package_names']
      repos.flatten.uniq(&:full_name).sort_by(&:full_name).each do |repo|
        csv << repo.attributes.except(*exclude_fields).values + [repo.direct_internal_dependency_package_names, repo.indirect_internal_dependency_package_names]
      end
    end

    puts csv_string
  end
end
