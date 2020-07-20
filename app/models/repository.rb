class Repository < ApplicationRecord

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
  has_many :manifests, dependent: :destroy
  has_many :repository_dependencies
  has_many :dependencies, through: :manifests, source: :repository_dependencies
  has_many :tags
  has_many :packages
  has_many :issues, foreign_key: :repo_full_name, primary_key: :full_name

  belongs_to :organization, foreign_key: :org, primary_key: :name, optional: true

  scope :internal, -> { includes(:organization).where(organizations: {internal: true}) }
  scope :external, -> { includes(:organization).where(organizations: {internal: false}) }
  scope :org, ->(org) { where(org: org) }
  scope :language, ->(language) { where(language: language) }
  scope :fork, ->(fork) { where(fork: fork) }
  scope :archived, ->(archived) { where(archived: archived) }
  scope :active, -> { archived(false) }
  scope :source, -> { fork(false) }

  scope :with_manifests, -> { joins(:manifests) }
  scope :without_manifests, -> { includes(:manifests).where(manifests: {repository_id: nil}) }

  scope :this_period, ->(period) { where('repositories.created_at > ?', period.days.ago) }
  scope :last_period, ->(period) { where('repositories.created_at > ?', (period*2).days.ago).where('repositories.created_at < ?', period.days.ago) }

  def self.download_org_repos(org)
    remote_repos = Issue.github_client.org_repos(org, type: 'public')
    remote_repos.each do |remote_repo|
      update_from_github(remote_repo)
    end
    nil
  end

  def self.download(full_name)
    begin
      remote_repo = Issue.github_client.repo(full_name)
      update_from_github(remote_repo)
    rescue Octokit::NotFound
      Repository.find_by_full_name(full_name).try(:destroy)
    end
  end

  def self.import_org(org)
    Repository.download_org_repos(org)
    Repository.org(org).update_all(etag: nil)
    Repository.org(org).each{|r| r.sync_events(true) }
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
      repo.last_sync_at = Time.now
      if repo.archived_changed?
        if repo.archived?
          repo.archive_all_issues!
        else
          repo.unarchive_all_issues!
        end
      end
      sync_manifests = repo.pushed_at_changed?
      repo.save
      repo.download_manifests if sync_manifests
      repo
    rescue ArgumentError, Octokit::Error
      # derp
    end
  end

  def html_url
    "https://github.com/#{full_name}"
  end

  def blob_url(sha = nil)
    sha ||= default_branch
    "#{html_url}/blob/#{sha}/"
  end

  def download_events(auto_paginate = false)
    client = Octokit::Client.new(access_token: ENV['GITHUB_TOKEN'])
    begin Octokit::NotFound
      events = client.repository_events(full_name, auto_paginate: auto_paginate, headers: {'If-None-Match' => etag})
      return [] if events == ''
      new_etag = client.last_response.headers['etag']
      if !auto_paginate && new_etag && new_etag != etag
        update_column(:etag, new_etag)
      end
      events
    rescue
      []
    end
  end

  def sync_events(auto_paginate = false)
    download_events(auto_paginate).each do |e|
      Event.record_event(self, e)
    end
  end

  def self.download_internal_repos
    Organization.internal.pluck(:name).each do |org|
      download_org_repos(org)
    end
  end

  def self.download_org_events(org)
    Issue.github_client.organization_public_events(org)
  end

  def self.sync_recently_active_repos(org)
    begin
      repo_names = download_org_events(org).map(&:repo).map(&:name).uniq
      repo_names.each do |full_name|
        repo = existing_repo = Repository.find_by_full_name(full_name)
        repo = Repository.download(full_name) if existing_repo.nil?
        next unless repo
        e = repo.sync_events
        if e.any?
          if Organization.internal.pluck(:name).include?(org)
            Issue.download(full_name)
            Issue.internal.where(repo_full_name: full_name).where('issues.updated_at > ?', 1.hour.ago).each(&:sync)
          end
          Repository.download(full_name) if existing_repo
        end
      end
    rescue Octokit::NotFound
      # org deleted
    end
  end

  def self.sync_recently_active_internal_repos
    Organization.internal.pluck(:name).each do |org|
      sync_recently_active_repos(org)
    end
  end

  def color
    Languages::Language[language].try(:color)
  end

  def download_manifests
    file_list = get_file_list
    return if file_list.blank?
    new_manifests = parse_manifests(file_list)

    return if new_manifests.blank?

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
      manifest = manifests.create(args)
      return unless m[:dependencies].present?
      dependencies = m[:dependencies].map(&:with_indifferent_access).uniq{|dep| [dep[:name].try(:strip), dep[:requirement], dep[:type]]}
      dependencies.each do |dep|
        platform = manifest.platform
        next unless dep.is_a?(Hash)
        package = nil # Package.platform(platform).find_by_name(dep[:name])

        manifest.repository_dependencies.create({
          package_id: package.try(:id),
          package_name: dep[:name].try(:strip),
          platform: platform,
          requirements: dep[:requirement],
          kind: dep[:type],
          repository_id: self.id,
          direct: manifest.kind == 'manifest'
        })
      end
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
    tree = Issue.github_client.tree(full_name, default_branch, :recursive => true).tree
    tree.select{|item| item.type == 'blob' }.map{|file| file.path }
  rescue *IGNORABLE_EXCEPTIONS
    nil
  end

  def get_file_contents(path)
    file = Issue.github_client.contents(full_name, path: path)
    {
      sha: file.sha,
      content: file.content.present? ? Base64.decode64(file.content) : file.content
    }
  rescue URI::InvalidURIError
    nil
  rescue *IGNORABLE_EXCEPTIONS
    nil
  end

  def self.find_missing_npm_packages
    joins(:manifests).where('manifests.filepath ilike ?', '%package.json').uniq.each(&:find_npm_packages)

    Package.platform('npm').each do |package|
      RepositoryDependency.platform('npm').without_package_id.where(package_name: package.name).update_all(package_id: package.id)
      Dependency.platform('npm').without_package_id.where(package_name: package.name).update_all(package_id: package.id)
      package.save
    end
  end

  def self.find_missing_cargo_packages
    joins(:manifests).where('manifests.filepath ilike ?', '%Cargo.toml').uniq.each(&:find_cargo_packages)

    Package.platform('cargo').each do |package|
      RepositoryDependency.platform('cargo').without_package_id.where(package_name: package.name).update_all(package_id: package.id)
      Dependency.platform('cargo').without_package_id.where(package_name: package.name).update_all(package_id: package.id)
      package.save
    end
  end

  def self.find_missing_go_packages
    joins(:manifests).where('manifests.filepath ilike ?', '%go.mod').uniq.each(&:find_go_packages)

    Package.platform('go').each do |package|
      RepositoryDependency.platform('go').without_package_id.where(package_name: package.name).update_all(package_id: package.id)
      Dependency.platform('go').without_package_id.where(package_name: package.name).update_all(package_id: package.id)
      package.save
    end
  end

  def find_npm_packages
    manifests.platform('npm').where('filepath ilike ?', '%package.json').each do |manifest|
      file = manifest.repository.get_file_contents(manifest.filepath)

      if file.present? && file[:content].present?
        json = JSON.parse(file[:content])
        PackageManager::Npm.update(json['name']) if json['name']
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
end
