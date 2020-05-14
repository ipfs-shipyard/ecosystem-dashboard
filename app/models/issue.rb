class Issue < ApplicationRecord

  PROTOCOL_ORGS = ['ipfs', 'libp2p', 'ipfs-shipyard', 'multiformats', 'ipld', 'ProtoSchool', 'ipfs-inactive']
  BOTS = ['dependabot[bot]', 'dependabot-preview[bot]', 'greenkeeper[bot]',
          'greenkeeperio-bot', 'rollbar[bot]', 'guardrails[bot]',
          'waffle-iron', 'imgbot[bot]', 'codetriage-readme-bot', 'whitesource-bolt-for-github[bot]',
          'gitter-badger', 'weekly-digest[bot]', 'todo[bot]', 'auto-comment[bot]',
          'github-actions[bot]', 'codecov[bot]', 'auto-comment[bot]', 'gitcoinbot',
          'reminders[bot]', 'stale[bot]', 'sonarcloud[bot]', 'status-github-bot[bot]',
          'release-drafter[bot]', 'allcontributors[bot]', 'now[bot]', 'move[bot]',
          'welcome[bot]', 'dependency-lockfile-snitch[bot]', 'netlify[bot]', 'renovate[bot]',
          'delete-merged-branch[bot]', 'parity-cla-bot', 'snyk-bot',  'metamaskbot',
          'arabot-1', 'status-im-bot']
  EMPLOYEES = ["Stebalien", "daviddias", "whyrusleeping", "RichardLitt", "hsanjuan",
                "alanshaw", "jbenet", "lidel", "tomaka", "hacdias", "lgierth", "dignifiedquire",
                "victorb", "Kubuxu", "vmx", "achingbrain", "vasco-santos", "jacobheun",
                "raulk", "olizilla", "satazor", "magik6k", "flyingzumwalt", "kevina",
                "satazor", "vyzo", "pgte", "PedroMiguelSS", "chriscool", "hugomrdias",
                "jessicaschilling", 'aschmahmann', 'dirkmc', 'ericronne', 'andrew',
                "Mr0grog", 'rvagg', 'lanzafame', 'mikeal', 'warpfork', 'terichadbourne',
                'mburns', 'nonsense', 'twittner', 'momack2', 'creationix', 'djdv',
                'jimpick', 'meiqimichelle', 'mgoelzer', 'kishansagathiya', 'dryajov',
                'autonome', 'bigs', 'jesseclay', 'yusefnapora', 'paulobmarcos', 'ribasushi',
                'willscott', 'johnnymatthews', 'coryschwartz', 'fsdiogo', 'zebateira',
                'dominguesgm', 'catiatpereira', 'andreforsousa', 'travisperson', 'krl',
                'nicola', 'hannahhoward', 'renrutnnej', 'marten-seemann', 'cwaring',
                'AfonsoVReis', 'pkafei', 'jkosem', 'aarshkshah1992', 'thattommyhall',
                'rafaelramalho19', 'andyschwab', 'parkan', 'yiannisbot', 'Gozala', 'petar']

  LANGUAGES = ['Go', 'JS', 'Rust', 'py', 'Java', 'Ruby', 'cs', 'clj', 'Scala', 'Haskell', 'C', 'PHP']

  scope :protocol, -> { where(org: PROTOCOL_ORGS) }
  scope :not_protocol, -> { where.not(org: PROTOCOL_ORGS) }
  scope :humans, -> { where.not(user: BOTS + ['ghost']) }
  scope :bots, -> { where(user: BOTS) }
  scope :employees, -> { where(user: EMPLOYEES) }
  scope :not_employees, -> { where.not(user: EMPLOYEES + BOTS) }
  scope :all_collabs, -> { where.not("collabs = '{}'") }
  scope :collab, ->(collab) { where("collabs @> ARRAY[?]::varchar[]", collab)  }

  scope :locked, -> { where(locked: true) }
  scope :unlocked, -> { where(locked: [false, nil]) }

  scope :pull_requests, -> { where("html_url like ?", '%/pull/%') }
  scope :issues, -> { where.not("html_url like ?", '%/pull/%') }

  scope :language, ->(language) { where('repo_full_name ilike ?', "%/#{language}-%") }

  scope :no_milestone, -> { where(milestone_name: nil) }
  scope :unlabelled, -> { where("labels = '{}'") }

  scope :org, ->(org) { where(org: org) }
  scope :state, ->(state) { where(state: state) }

  scope :open_for_over_2_days, -> { where("DATE_PART('day', issues.closed_at - issues.created_at) > 2 OR issues.closed_at is NULL") }
  scope :slow_response, -> { open_for_over_2_days.where("DATE_PART('day', issues.first_response_at - issues.created_at) > 2 OR issues.first_response_at is NULL") }
  scope :no_response, -> { where(first_response_at: nil) }

  scope :draft, -> { where(draft: true) }
  scope :not_draft, -> { where('draft IS NULL or draft is false') }

  def contributed?
    !Issue::EMPLOYEES.include?(user)
  end

  def self.download(repo_full_name)
    begin
      remote_issues = github_client.issues(repo_full_name, state: 'all', since: 1.week.ago)
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
      issue.save if issue.changed?
    rescue ArgumentError, Octokit::Error
      # derp
    end
  end

  def self.github_client
    @client ||= Octokit::Client.new(access_token: ENV['GITHUB_TOKEN'], auto_paginate: true)
  end

  def self.org_repo_names(org_name)
    github_client.org_repos(org_name).map(&:full_name)
  end

  def self.download_org_repos(org_name)
    org_repo_names(org_name).each{|repo_full_name| download(repo_full_name) }
  end

  def self.active_repo_names
    Issue.protocol.unlocked.where('created_at > ?', 6.months.ago).pluck(:repo_full_name).uniq
  end

  def self.active_collab_repo_names
    Issue.not_protocol.unlocked.where('created_at > ?', 6.months.ago).pluck(:repo_full_name).uniq
  end

  def self.org_contributor_names(org_name)
    Issue.org(org_name).not_employees.group(:user).count
  end

  def self.collab_orgs
    Issue.not_protocol.group(:org).count
  end

  def self.download_new_repos
    new_repo_names.each{|repo_full_name| download(repo_full_name) }
  end

  def self.download_new_collab_repos
    new_collab_repo_names.each{|repo_full_name| download(repo_full_name) }
  end

  def self.new_repo_names
    PROTOCOL_ORGS.map do |org_name|
      org_repo_names(org_name) - active_repo_names
    end.flatten
  end

  def self.new_collab_repo_names
    collab_orgs.keys.map do |org_name|
      org_repo_names(org_name) - active_repo_names
    end.flatten
  end

  def self.download_active_repos
    active_repo_names.each{|repo_full_name| download(repo_full_name) }
  end

  def self.download_active_collab_repos
    active_collab_repo_names.each{|repo_full_name| download(repo_full_name) }
  end

  def self.update_collab_labels
    Issue.unlocked.protocol.where('created_at > ?', 1.month.ago).not_employees.group(:user).count.each do |u, count|
      collabs = Event.not_protocol.user(u).event_type('PushEvent').group(:org).count.map(&:first)
      Issue.protocol.unlocked.where(user: u).update_all(collabs: collabs)
    end
  end

  def pull_request?
    html_url && html_url.match?(/\/pull\//i)
  end

  def self.sync_pull_requests(time_range = 1.week.ago)
    protocol.pull_requests.where('created_at > ?', time_range).where(merged_at: nil).find_each(&:download_pull_request)
  end

  def download_pull_request
    return unless pull_request?
    return if merged_at.present?

    begin
      resp = Issue.github_client.pull_request(repo_full_name, number)
      update_columns(merged_at: resp.merged_at, draft: resp.draft)
    rescue Octokit::NotFound
      destroy
    end
  end

  def calculate_first_response
    return if first_response_at.present?
    begin
      events = Issue.github_client.issue_timeline(repo_full_name, number, accept: 'application/vnd.github.mockingbird-preview')
      events = events.select{|e| (e.actor && Issue::EMPLOYEES.include?(e.actor.login)) || (e.user && Issue::EMPLOYEES.include?(e.user.login)) } # filter for events by employees
      events = events.select{|e| !['subscribed', 'mentioned'].include?(e.event)  } # ignore events where actor isn't who acted

      return if events.empty? # no employee response yet

      e = events.first

      first_response_at = e.created_at || e.submitted_at

      update_columns(first_response_at: first_response_at, response_time: first_response_at - created_at)
    rescue Octokit::NotFound
      destroy
    end
  end

  def self.sync_recent
    Issue.where('created_at > ?', 9.days.ago).state('open').not_employees.unlocked.where("html_url <> ''").each(&:sync)
  end

  def sync
    begin
      remote_issue = Issue.github_client.issue(repo_full_name, number)
      Issue.update_from_github(repo_full_name, remote_issue)
      update_extra_attributes
    rescue Octokit::NotFound
      destroy
    end
  end

  def update_extra_attributes
    download_pull_request
    calculate_first_response
  end
end
