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

  scope :protocol, -> { where(org: Issue::PROTOCOL_ORGS) }
  scope :org, ->(org) { where(org: org) }
  scope :language, ->(language) { where(language: language) }
  scope :fork, ->(fork) { where(fork: fork) }
  scope :archived, ->(archived) { where(archived: archived) }

  scope :with_manifests, -> { joins(:manifests) }
  scope :without_manifests, -> { includes(:manifests).where(manifests: {repository_id: nil}) }

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
      repo.save
      repo
    rescue ArgumentError, Octokit::Error
      # derp
    end
  end

  def html_url
    "https://github.com/#{full_name}"
  end

  def download_events
    client = Octokit::Client.new(access_token: ENV['GITHUB_TOKEN'])
    events = client.repository_events(full_name, auto_paginate: false, headers: {'If-None-Match' => etag})
    return [] if events == ''
    new_etag = client.last_response.headers['etag']
    if new_etag && new_etag != etag
      update_attribute(:etag, new_etag)
    end
    events
  end

  def sync_events
    download_events.each do |e|
      Event.record_event(self, e)
    end
  end

  def self.download_protocol_repos
    Issue::PROTOCOL_ORGS.each do |org|
      download_org_repos(org)
    end
  end

  def self.download_org_events(org)
    Issue.github_client.organization_public_events(org)
  end

  def self.sync_recently_active_repos(org)
    repo_names = download_org_events(org).map(&:repo).map(&:name).uniq
    repo_names.each do |full_name|
      repo = existing_repo = Repository.find_by_full_name(full_name)
      repo = Repository.download(full_name) if existing_repo.nil?
      next unless repo
      e = repo.sync_events
      if e.any?
        Issue.download(full_name)
        Issue.where(repo_full_name: full_name).where('updated_at > ?', 1.hour.ago).each(&:update_extra_attributes)
        Repository.download(full_name) if existing_repo
      end
    end
  end

  def self.sync_recently_active_protocol_repos
    Issue::PROTOCOL_ORGS.each do |org|
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
    # sync_metadata(file_list)

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
          repository_id: self.id
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
end
