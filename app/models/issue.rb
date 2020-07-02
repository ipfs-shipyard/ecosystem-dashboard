class Issue < ApplicationRecord

  LANGUAGES = ['Go', 'JS', 'Rust', 'py', 'Java', 'Ruby', 'cs', 'clj', 'Scala', 'Haskell', 'C', 'PHP']

  scope :internal, -> { includes(:organization).where(organizations: {internal: true}) }
  scope :external, -> { includes(:organization).where(organizations: {internal: false}) }
  scope :humans, -> { core.or(not_core) }
  scope :bots, -> { includes(:contributor).where(contributors: {bot: true}) }
  scope :core, -> { includes(:contributor).where(contributors: {core: true}) }
  scope :not_core, -> { includes(:contributor).where(contributors: {id: nil}) }
  scope :all_collabs, -> { where.not("collabs = '{}'") }
  scope :collab, ->(collab) { where("collabs @> ARRAY[?]::varchar[]", collab)  }

  scope :locked, -> { where(locked: true) }
  scope :unlocked, -> { where(locked: [false, nil]) }

  scope :pull_requests, -> { where("html_url like ?", '%/pull/%') }
  scope :issues, -> { where.not("html_url like ?", '%/pull/%') }

  scope :language, ->(language) { where('repo_full_name ilike ?', "%/#{language}-%") }

  scope :no_milestone, -> { where(milestone_name: nil) }
  scope :unlabelled, -> { where("labels = '{}'") }
  scope :label, ->(label) { where("labels @> ARRAY[?]::varchar[]", label) }

  scope :org, ->(org) { where(org: org) }
  scope :state, ->(state) { where(state: state) }
  scope :user, ->(user) { where(user: user) }

  scope :open_for_over_2_days, -> { where("DATE_PART('day', issues.closed_at - issues.created_at) > 2 OR issues.closed_at is NULL") }
  scope :slow_response, -> { open_for_over_2_days.where("DATE_PART('day', issues.first_response_at - issues.created_at) > 2 OR issues.first_response_at is NULL") }
  scope :no_response, -> { where(first_response_at: nil) }

  scope :draft, -> { where(draft: true) }
  scope :not_draft, -> { where('draft IS NULL or draft is false') }

  scope :exclude_user, ->(user) { where.not(user: user) }
  scope :exclude_repo, ->(repo_full_name) { where.not(repo_full_name: repo_full_name) }
  scope :exclude_org, ->(org) { where.not(org: org) }
  scope :exclude_language, ->(languages) { where('repo_full_name NOT ilike ALL(ARRAY[?])', Array(languages).map{|l| "%/#{l}-%" }) }
  scope :exclude_collab, ->(collab) { where.not("collabs && ARRAY[?]::varchar[]", collab)  }
  scope :exclude_label, ->(label) { where.not("labels && ARRAY[?]::varchar[]", label)  }

  scope :this_period, ->(period) { where('issues.created_at > ?', period.days.ago) }
  scope :last_period, ->(period) { where('issues.created_at > ?', (period*2).days.ago).where('issues.created_at < ?', period.days.ago) }
  scope :this_week, -> { where('issues.created_at > ?', 1.week.ago) }
  scope :last_week, -> { where('issues.created_at > ?', 2.week.ago).where('issues.created_at < ?', 1.week.ago) }

  belongs_to :repository, foreign_key: :repo_full_name, primary_key: :full_name, optional: true
  belongs_to :contributor, foreign_key: :user, primary_key: :github_username, optional: true
  belongs_to :organization, foreign_key: :org, primary_key: :name, optional: true

  def self.median_slow_response_rate
    arr = all.group_by{|i| i.created_at.to_date }.map{|date, issues| [date, issues.select(&:slow_response?).length]}
    sorted = arr.map(&:second).sort
    len = sorted.length
    (sorted[(len - 1) / 2] + sorted[len / 2]) / 2.0
  end

  def slow_response?
    return false if draft?
    return false if created_at > 2.days.ago
    first_response_at.nil? || (first_response_at - created_at) > 2.days
  end

  def contributed?
    return true unless contributor.present?
    !contributor.core?
  end

  def self.download(repo_full_name, since = 1.week.ago)
    begin
      remote_issues = github_client.issues(repo_full_name, state: 'all', since: since)
      remote_issues.each do |remote_issue|
        update_from_github(repo_full_name, remote_issue)
      end
    rescue Octokit::NotFound
      # its gone
    end
    nil
  end

  def self.update_from_github(repo_full_name, remote_issue)
    begin
      issue = Issue.find_or_create_by(repo_full_name: repo_full_name, number: remote_issue.number)
      repo_full_name = remote_issue.repository_url.gsub('https://api.github.com/repos/', '')
      issue.github_id = remote_issue.id
      issue.repo_full_name = repo_full_name
      issue.title = remote_issue.title.delete("\u0000")
      issue.body = remote_issue.body.try(:delete, "\u0000")
      issue.state = remote_issue.state
      issue.html_url = remote_issue.html_url
      issue.locked = remote_issue.locked
      issue.comments_count = remote_issue.comments
      issue.user = remote_issue.user.login
      issue.closed_at = remote_issue.closed_at
      issue.created_at = remote_issue.created_at
      issue.updated_at = remote_issue.updated_at
      issue.org = repo_full_name.split('/').first
      issue.milestone_name = remote_issue.milestone.try(:title)
      issue.milestone_id = remote_issue.milestone.try(:number)
      issue.labels = remote_issue.labels.map(&:name)
      issue.last_synced_at = Time.zone.now
      issue.save
    rescue ArgumentError, Octokit::Error
      # derp
    end
  end

  def self.github_client
    @client ||= Octokit::Client.new(access_token: ENV['GITHUB_TOKEN'], auto_paginate: true)
  end

  def self.active_repo_names
    Issue.internal.unlocked.where('issues.created_at > ?', 6.months.ago).pluck(:repo_full_name).uniq
  end

  def self.download_active_repos
    active_repo_names.each{|repo_full_name| download(repo_full_name) }
  end

  def self.update_collab_labels
    Issue.unlocked.internal.where('issues.created_at > ?', 1.month.ago).not_core.group(:user).count.each do |u, count|
      Issue.internal.unlocked.where(user: u).update_all(collabs: Contributor.collabs_for(u))
    end
  end

  def pull_request?
    html_url && html_url.match?(/\/pull\//i)
  end

  def download_pull_request
    return unless pull_request?
    return if merged_at.present?

    begin
      resp = Issue.github_client.pull_request(repo_full_name, number)
      updates = {}
      updates[:merged_at] = resp.merged_at if resp.merged_at != merged_at
      updates[:draft] = resp.draft if resp.draft != draft
      update_columns(updates) if updates.any?
    rescue Octokit::NotFound
      destroy
    end
  end

  def calculate_first_response
    return if first_response_at.present?
    begin
      events = Issue.github_client.issue_timeline(repo_full_name, number, accept: 'application/vnd.github.mockingbird-preview')
      # filter for events by core contributors
      core_contributor_usernames = Contributor.core.pluck(:github_username)
      events = events.select{|e| (e.actor && core_contributor_usernames.include?(e.actor.login)) || (e.user && core_contributor_usernames.include?(e.user.login)) }
      # ignore events where actor isn't who acted
      events = events.select{|e| !['subscribed', 'mentioned'].include?(e.event)  }
      # bail if no core contributor response yet
      return if events.empty?

      e = events.first

      first_response_at = e.created_at || e.submitted_at
      response_time = first_response_at - created_at

      update_columns(first_response_at: first_response_at, response_time: response_time) if response_time > 0
    rescue Octokit::NotFound
      destroy
    end
  end

  def self.sync_recent
    Issue.where('issues.created_at > ?', 9.days.ago).state('open').not_core.unlocked.where("html_url <> ''").each(&:sync)
  end

  def sync
    begin
      remote_issue = Issue.github_client.issue(repo_full_name, number)
      Issue.update_from_github(repo_full_name, remote_issue)
      update_extra_attributes
      update_column(:last_synced_at, Time.zone.now)
    rescue Octokit::NotFound
      destroy
    end
  end

  def update_extra_attributes
    download_pull_request
    calculate_first_response
  end
end
