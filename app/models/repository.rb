class Repository < ApplicationRecord
  include DependencyMiner

  IGNORABLE_EXCEPTIONS = [
    Octokit::Unauthorized,
    Octokit::InvalidRepository,
    Octokit::RepositoryUnavailable,
    Octokit::NotFound,
    Octokit::Conflict,
    Octokit::Forbidden,
    Octokit::InternalServerError,
    Octokit::BadGateway,
    Octokit::ClientError,
    Octokit::UnavailableForLegalReasons
  ]

  has_many :events
  has_many :release_events, -> { where event_type: 'ReleaseEvent' }, class_name: 'Event'
  has_many :manifests, dependent: :destroy
  has_many :repository_dependencies
  has_many :dependencies, through: :manifests, source: :repository_dependencies
  has_many :dependency_events, dependent: :delete_all
  has_many :tags
  has_many :packages
  has_many :issues, foreign_key: :repo_full_name, primary_key: :full_name
  has_many :search_results, foreign_key: :repository_full_name, primary_key: :full_name

  belongs_to :organization, foreign_key: :org, primary_key: :name, optional: true

  scope :internal, -> { includes(:organization).where(organizations: {internal: true}) }
  scope :partner, -> { includes(:organization).where(organizations: {partner: true}) }
  scope :internal_or_partner, -> { joins(:organization).where('organizations.internal = ? OR organizations.partner = ?', true, true) }
  scope :not_internal, -> { where.not(org: Organization.internal.pluck(:name)) }
  scope :collaborator, -> { includes(:organization).where(organizations: {internal: false}) }
  scope :not_community, -> { where(org: Organization.not_community.pluck(:name)) }
  scope :community, -> { where.not(org: Organization.not_community.pluck(:name)) }
  scope :org, ->(org) { where(org: org) }
  scope :language, ->(language) { where(language: language) }
  scope :fork, ->(fork) { where(fork: fork) }
  scope :archived, ->(archived) { where(archived: archived) }
  scope :active, -> { archived(false) }
  scope :source, -> { fork(false) }
  scope :no_topic, -> { where("topics = '{}'") }
  scope :topic, ->(topic) { where("topics @> ARRAY[?]::varchar[]", topic) }
  scope :triage, -> { where(triage: true) }
  scope :smart, -> { where(sol_files: true) }

  scope :with_internal_deps, ->(count = 1) { having("SUM(coalesce(array_length(direct_internal_dependency_package_ids, 1),0) + coalesce(array_length(indirect_internal_dependency_package_ids, 1),0)) >= ?", count).group(:id) }

  scope :with_manifests, -> { joins(:manifests).group(:id) }
  scope :without_manifests, -> { includes(:manifests).where(manifests: {repository_id: nil}) }

  scope :with_dependency_events, -> { joins(:dependency_events).group(:id) }
  scope :without_dependency_events, -> { includes(:dependency_events).where(dependency_events: {repository_id: nil}) }

  scope :with_search_results, -> { joins(:search_results).group(:id) }
  scope :without_search_results, -> { includes(:search_results).where(search_results: {repository_full_name: nil}) }

  scope :this_period, ->(period) { where('repositories.created_at > ?', period.days.ago) }
  scope :last_period, ->(period) { where('repositories.created_at > ?', (period*2).days.ago).where('repositories.created_at < ?', period.days.ago) }

  def self.download_org_repos(org)
    remote_repos = Issue.github_client.org_repos(org, type: 'public')
    remote_repos.each do |remote_repo|
      update_from_github(remote_repo)
    end
    nil
  end

  def self.download(full_name_or_id)
    begin
      remote_repo = Issue.github_client.repo(full_name_or_id, accept: 'application/vnd.github.drax-preview+json,application/vnd.github.mercy-preview+json')
      update_from_github(remote_repo)
    rescue Octokit::NotFound
      if full_name_or_id.is_a?(String)
        Repository.find_by_full_name(full_name_or_id).try(:destroy)
      else
        Repository.find_by_github_id(full_name_or_id).try(:destroy)
      end
    rescue Octokit::InvalidRepository
      # full_name isn't a proper repo name
    rescue Octokit::RepositoryUnavailable
      # repo locked/disabled
      if full_name_or_id.is_a?(String)
        repo = Repository.find_by_full_name(full_name_or_id)
      else
        repo = Repository.find_by_github_id(full_name_or_id)
      end
      repo.update_column(:last_sync_at, Time.zone.now) if repo
    end
  end

  def self.download_if_missing_and_active(name)
    return if name.to_s.blank?
    r = Repository.where('full_name ilike ?', name.to_s).first
    unless r
      begin
        remote_repo = Issue.github_client.repo(name)
        if remote_repo.fork || remote_repo.archived
          puts "SKIPPING #{name} - fork:#{remote_repo.fork} archived:#{remote_repo.archived}"
        else
          Repository.update_from_github(remote_repo)
        end
      rescue Octokit::NotFound, Octokit::InvalidRepository
        # not found or invalid
      end
    end
  end

  def self.import_org(org)
    Repository.download_org_repos(org)
    Repository.org(org).update_all(etag: nil)
    Repository.org(org).active.source.each{|r| r.sync_events(true) }
    Issue.update_collab_labels
  end

  def self.update_from_github(remote_repo)
    begin
      repo = Repository.find_or_create_by(github_id: remote_repo.id)
      repo.full_name = remote_repo.full_name
      repo.created_at = remote_repo.created_at
      repo.updated_at = remote_repo.updated_at
      repo.org = remote_repo.full_name.split('/').first
      repo.language = remote_repo.language
      repo.archived = remote_repo.archived
      repo.fork = remote_repo.fork
      repo.description = remote_repo.description
      repo.pushed_at = remote_repo.pushed_at
      repo.size = remote_repo.size
      repo.stargazers_count = remote_repo.stargazers_count
      repo.open_issues_count = remote_repo.open_issues_count
      repo.forks_count = remote_repo.forks_count
      repo.subscribers_count = remote_repo.subscribers_count
      repo.default_branch = remote_repo.default_branch
      repo.topics = remote_repo.topics
      repo.last_sync_at = Time.now
      if repo.archived_changed?
        if repo.archived?
          repo.archive_all_issues!
        else
          repo.unarchive_all_issues!
        end
      end
      sync_files = repo.pushed_at_changed?
      repo.save
      if !repo.fork? && !repo.archived? && sync_files
        repo.download_manifests
        repo.update_internal_dependency_lists
        repo.update_file_list
        repo.mine_dependencies_async
      end
      repo
    rescue ArgumentError, Octokit::Error
      repo.update_column(:last_sync_at, Time.zone.now) if repo
    end
  end

  def self.discover_from_search_results(period = 7)
    repos_from_search = SearchResult.group(:repository_full_name).this_period(period).count.keys
    existing = Repository.where(full_name: repos_from_search).pluck(:full_name)
    missing = repos_from_search - existing
    missing.each do |name|
      Repository.download_if_missing_and_active(name)
    end
  end

  def html_url
    "https://github.com/#{full_name}"
  end

  def blob_url(sha = nil)
    sha ||= default_branch
    "#{html_url}/blob/#{sha}/"
  end

  def file_url(filename, sha = nil)
    sha ||= default_branch
    "#{blob_url(sha)}/#{filename}"
  end

  def new_file_url(filename, branch = nil)
    branch ||= default_branch
    "#{html_url}/new/#{branch}?filename=#{filename}"
  end

  def download_events(auto_paginate = false)
    client = Octokit::Client.new(access_token: ENV['GITHUB_TOKEN'])
    begin
      if auto_paginate || etag.blank?
        events = client.repository_events(full_name, auto_paginate: auto_paginate)
      else
        events = client.repository_events(full_name, headers: {'If-None-Match' => etag})
      end

      update_column(:last_events_sync_at, Time.zone.now)
      return [] if events == ''
      new_etag = client.last_response.headers['etag']
      if !auto_paginate && new_etag && new_etag != etag
        update_column(:etag, new_etag)
      end
      events
    rescue *IGNORABLE_EXCEPTIONS
      []
    end
  end

  def download_issues(since = 1.week.ago)
    Issue.download(full_name, since)
  end

  def sync_events(auto_paginate = false)
    download_events(auto_paginate).each do |e|
      Event.record_event(self, e)
    end
  end

  def self.download_internal_repos
    Organization.internal_or_partner.pluck(:name).each do |org|
      download_org_repos(org)
    end
  end

  def self.download_org_events(org)
    Issue.github_client.organization_public_events(org)
  end


  def self.sync_recently_active_internal_repos
    Organization.internal_or_partner.each(&:sync_recently_active_repos)
  end

  def color
    Languages::Language[language].try(:color)
  end

  def download_manifests
    file_list = get_file_list
    return if file_list.blank?
    new_manifests = parse_manifests(file_list)

    if new_manifests.blank?
      manifests.each(&:destroy)
      return
    end

    new_manifests.each {|m| sync_manifest(m) }

    delete_old_manifests(new_manifests)
  end

  def parse_manifests(file_list)
    manifest_paths = Bibliothecary.identify_manifests(file_list)

    manifest_paths.map do |manifest_path|
      file = get_file_contents(manifest_path)
      if file.present? && file[:content].present?
        begin
          manifest = Bibliothecary.analyse_file(manifest_path, file[:content]).first
          manifest.merge!(sha: file[:sha]) if manifest
          manifest
        rescue
          nil
        end
      end
    end.reject(&:blank?)
  end

  def sync_manifest(m)
    args = {platform: m[:platform], kind: m[:kind], filepath: m[:path], sha: m[:sha]}

    unless manifests.find_by(args)
      return unless m[:dependencies].present? && m[:dependencies].any?
      manifest = manifests.create(args)
      dependencies = m[:dependencies].map(&:with_indifferent_access).uniq{|dep| [dep[:name].try(:strip), dep[:requirement], dep[:type]]}

      packages = Package.platform(manifest.platform).where(name: dependencies.map{|d| d[:name]})

      deps = dependencies.map do |dep|
        platform = manifest.platform
        next unless dep.is_a?(Hash)

        package = packages.select{|p| p.name == dep[:name] }.first

        {
          manifest_id: manifest.id,
          package_id: package.try(:id),
          package_name: dep[:name].try(:strip),
          platform: platform,
          requirements: dep[:requirement],
          kind: dep[:type],
          repository_id: self.id,
          direct: manifest.kind == 'manifest',
          created_at: Time.now,
          updated_at: Time.now
        }
      end.compact

      RepositoryDependency.insert_all(deps)
    end
  end

  def delete_old_manifests(new_manifests)
    existing_manifests = manifests.map{|m| [m.platform, m.filepath] }
    to_be_removed = existing_manifests - new_manifests.map{|m| [m[:platform], m[:path]] }
    to_be_removed.each do |m|
      manifests.where(platform: m[0], filepath: m[1]).each(&:destroy)
    end
    manifests.where.not(id: manifests.latest.map(&:id)).each(&:destroy)
  end

  def get_file_list
    @file_list ||= begin
      tree = Issue.github_client.tree(full_name, default_branch, :recursive => true).tree
      tree.select{|item| item.type == 'blob' }.map{|file| file.path }
    rescue *IGNORABLE_EXCEPTIONS
      nil
    end
  end

  def get_file_contents(path)
    file = Issue.github_client.contents(full_name, path: path)
    return nil if file.is_a?(Array)
    {
      sha: file.sha,
      content: file.content.present? ? Base64.decode64(file.content) : file.content
    }
  rescue URI::InvalidURIError
    nil
  rescue *IGNORABLE_EXCEPTIONS
    nil
  end

  def update_file_list
    file_list = get_file_list
    return if file_list.nil?
    self.readme_path          = file_list.find{|file| file.match(/^README/i) }
    self.changelog_path       = file_list.find{|file| file.match(/^CHANGE|^HISTORY/i) }
    self.contributing_path    = file_list.find{|file| file.match(/^(docs\/)?(.github\/)?CONTRIBUTING/i) }
    self.license_path         = file_list.find{|file| file.match(/^LICENSE|^COPYING|^MIT-LICENSE/i) }
    self.code_of_conduct_path = file_list.find{|file| file.match(/^(docs\/)?(.github\/)?CODE[-_]OF[-_]CONDUCT/i) }
    self.sol_files            = file_list.any?{|file| file.match(/\.sol$/i) }

    save if self.changed?
  end

  def valid_audit?
    description.present? &&
    readme_path.present?  &&
    code_of_conduct_path.present? &&
    contributing_path.present? &&
    license_path.present? &&
    (
      release_events.length > 0 ? changelog_path.present? : true
    )
  end

  def self.find_missing_npm_packages
    internal_or_partner.active.source.joins(:manifests).where('manifests.filepath ilike ?', '%package.json').uniq.each(&:find_npm_packages)

    Package.internal_or_partner.platform('npm').find_each do |package|
      RepositoryDependency.platform('npm').without_package_id.where(package_name: package.name).update_all(package_id: package.id)
      Dependency.platform('npm').without_package_id.where(package_name: package.name).update_all(package_id: package.id)
      package.save
    end
  end

  def self.find_missing_cargo_packages
    internal_or_partner.active.source.joins(:manifests).where('manifests.filepath ilike ?', '%Cargo.toml').uniq.each(&:find_cargo_packages)

    Package.internal_or_partner.platform('cargo').find_each do |package|
      RepositoryDependency.platform('cargo').without_package_id.where(package_name: package.name).update_all(package_id: package.id)
      Dependency.platform('cargo').without_package_id.where(package_name: package.name).update_all(package_id: package.id)
      package.save
    end
  end

  def self.find_missing_go_packages
    internal_or_partner.active.source.joins(:manifests).where('manifests.filepath ilike ?', '%go.mod').uniq.each(&:find_go_packages)

    Package.internal_or_partner.platform('go').find_each do |package|
      RepositoryDependency.platform('go').without_package_id.where(package_name: package.name).update_all(package_id: package.id)
      Dependency.platform('go').without_package_id.where(package_name: package.name).update_all(package_id: package.id)
      package.save
    end
  end

  def find_npm_packages
    manifests.platform('npm').where('filepath ilike ?', '%package.json').each do |manifest|
      file = manifest.repository.get_file_contents(manifest.filepath)

      if file.present? && file[:content].present?
        begin
          json = JSON.parse(file[:content])
          PackageManager::Npm.update(json['name']) if json['name']
        rescue JSON::ParserError, TypeError
          # invalid manifest
        end
      end
    end
  end

  def find_cargo_packages
    manifests.platform('cargo').where('filepath ilike ?', '%Cargo.toml').each do |manifest|
      file = manifest.repository.get_file_contents(manifest.filepath)

      if file.present? && file[:content].present?
        toml = TomlRB.parse(file[:content])
        PackageManager::Cargo.update(toml['package']['name']) if toml['package']
      end
    end
  end

  def find_go_packages
    manifests.platform('go').where('filepath ilike ?', '%go.mod').each do |manifest|
      file = manifest.repository.get_file_contents(manifest.filepath)

      if file.present? && file[:content].present?
        module_line = file[:content].lines.map(&:strip).map{|line| line.match(/^(module\s+)?(.+)\s+(.+)$/) }.compact.first
        PackageManager::Go.update(module_line[3].strip) if module_line && module_line[3].strip
      end
    end
  end

  def download_tags
    existing_tag_names = tags.pluck(:name)
    tags = Issue.github_client.refs(full_name, 'tags')
    Array(tags).each do |tag|
      next unless tag && tag.is_a?(Sawyer::Resource) && tag['ref']
      download_tag(tag, existing_tag_names)
    end
    packages.find_each(&:forced_save) if tags.present?
  rescue *IGNORABLE_EXCEPTIONS
    nil
  end

  def download_tag(tag, existing_tag_names)
    match = tag.ref.match(/refs\/tags\/(.*)/)
    return unless match
    name = match[1]
    return if existing_tag_names.include?(name)

    object = Issue.github_client.get(tag.object.url)

    tag_hash = {
      name: name,
      kind: tag.object.type,
      sha: tag.object.sha
    }

    case tag.object.type
    when 'commit'
      tag_hash[:published_at] = object.committer.date
    when 'tag'
      tag_hash[:published_at] = object.tagger.date
    end

    tags.create(tag_hash)
  end

  def archive_all_issues!
    issues.update_all(locked: true)
  end

  def unarchive_all_issues!
    issues.update_all(locked: false)
  end

  def sync
    Repository.download(github_id)
    sync_events
    update_score
  end

  def sync_if_updates
    sync if sync_events.any?
  end

  def internal_package_dependency_ids
    direct_internal_dependency_package_ids + indirect_internal_dependency_package_ids
  end

  def ecosystem_score_parts
    display_name = ENV['DISPLAY_NAME'].presence || ENV['DEFAULT_ORG'].presence || Organization.internal.first.try(:name)
    keyword_match = full_name.match?(/#{Regexp.quote(display_name)}/i) || description.to_s.match?(/#{Regexp.quote(display_name)}/i) || Array(topics).any?{|t| t.match?(/#{Regexp.quote(display_name)}/i) }

    search_results_length = search_results.select{|sr| sr.kind != 'code'}.length
    search_score = search_results_length > 0 ? Math.log(search_results_length, 10) : 0

    internal_package_dependencies = internal_package_dependency_ids.length
    internal_package_score = internal_package_dependencies > 0 ? Math.log(internal_package_dependencies, 10) : 0

    # TODO
    # Is it owned by an internal org?       (owner)
    # Is it owned by a collab org?          (owner)
    # Is it owned by a collab contributor?  (owner)
    # Is it owned by a core contributor?    (owner)
    # Is it owned by a community contributor?  (owner)
    # # Does it use go-ipfs as a library?
    # # Does it use js-ipfs as a library?
    # # Does it use go-ipfs via docker?

    {
      fork: fork? ? -10 : 0,
      archived: archived? ? -10 : 0,
      keyword: keyword_match ? 1 : 0,
      search: search_score,
      internal_packages: internal_package_score
    }
  end

  def popularity_score_parts
    stars = stargazers_count && stargazers_count > 0 ? 1 : 0
    stars += 1 if stargazers_count && stargazers_count > 100
    # How many forks?
    forks = forks_count && forks_count > 0 ? 1 : 0
    # How long has it existed?
    created = (Date.today-created_at.to_date).to_i > 0 ? Math.log((Date.today-created_at.to_date).to_i, 10)/2 : 0
    # When was it last updated?
    updated = (Date.today-updated_at.to_date).to_i > 0 ? -Math.log((Date.today-updated_at.to_date).to_i, 10) : 0
    # When was it last committed to?
    committed = pushed_at && (Date.today-pushed_at.to_date).to_i  > 0 ? -Math.log((Date.today-pushed_at.to_date).to_i, 10) : 0

    {
      stars: stars,
      forks: forks,
      created: created,
      updated: updated,
      committed: committed
    }
  end

  def calculate_score
    new_score = ecosystem_score_parts.values.sum

    # only consider general attributes if repo appears to be connected to the ecosystem
    new_score += popularity_score_parts.values.sum if new_score >= 1

    new_score.round
  end

  def update_score
    new_score = calculate_score
    update_column(:score, new_score) if new_score != score
  end

  def self.recalculate_scores
    includes(:search_results).find_each{|r| r.update_score }
  end

  def update_internal_dependency_lists
    internal_package_ids = Package.internal_or_partner.pluck(:id)
    if direct_internal_dependency_package_ids.blank? && indirect_internal_dependency_package_ids.blank?
      return unless manifests.any?
      return unless repository_dependencies.any?
    end

    direct_ids = repository_dependencies.direct.where(package_id: internal_package_ids).pluck(:package_id)
    lockfile_ids = repository_dependencies.transitive.where(package_id: internal_package_ids).pluck(:package_id)
    indirect_ids = lockfile_ids - direct_ids

    update(
      direct_internal_dependency_package_ids: direct_ids.uniq,
      indirect_internal_dependency_package_ids: indirect_ids.uniq
    )
  end

  def direct_internal_dependency_packages
    Package.where(id: direct_internal_dependency_package_ids)
  end

  def indirect_internal_dependency_packages
    Package.where(id: indirect_internal_dependency_package_ids)
  end

  def direct_internal_dependency_package_names
    direct_internal_dependency_packages.select(:name, :platform).map{|pkg| "#{pkg.platform}/#{pkg.name}"}
  end

  def indirect_internal_dependency_package_names
    direct_internal_dependency_packages.select(:name, :platform).map{|pkg| "#{pkg.platform}/#{pkg.name}"}
  end

  def direct_internal_dependencies
    repository_dependencies.where(package_id: direct_internal_dependency_package_ids)
  end

  def indirect_internal_dependencies
    repository_dependencies.where(package_id: indirect_internal_dependency_package_ids)
  end

  def mine_dependencies_async
    DependencyEventsWorker.perform_async(id)
  end
end
