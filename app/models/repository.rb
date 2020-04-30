class Repository < ApplicationRecord

  scope :protocol, -> { where(org: Issue::PROTOCOL_ORGS) }

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
      e = repo.download_events
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
end
