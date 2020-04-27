class Issue < ApplicationRecord

  PROTOCOL_ORGS = ['ipfs', 'libp2p', 'ipfs-shipyard', 'multiformats', 'ipld', 'ProtoSchool']
  BOTS = ['dependabot[bot]', 'dependabot-preview[bot]', 'greenkeeper[bot]',
          'greenkeeperio-bot', 'rollbar[bot]', 'guardrails[bot]',
          'waffle-iron', 'imgbot[bot]', 'codetriage-readme-bot', 'whitesource-bolt-for-github[bot]',
          'gitter-badger', 'weekly-digest[bot]', 'todo[bot]']
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
                'rafaelramalho19']

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

  def self.download(repo_full_name)
    remote_issues = github_client.issues(repo_full_name, state: 'all')
    remote_issues.each do |remote_issue|
      begin
        issue = Issue.find_or_create_by(repo_full_name: repo_full_name, number: remote_issue.number)
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
    nil
  end

  def self.github_client
    client = Octokit::Client.new(access_token: ENV['GITHUB_TOKEN'], auto_paginate: true)
  end

  def self.org_repo_names(org_name)
    github_client.org_repos(org_name).map(&:full_name)
  end

  def self.download_org_repos(org_name)
    org_repo_names(org_name).each{|repo_full_name| download(repo_full_name) }
  end

  def self.active_repo_names
    Issue.protocol.where('created_at > ?', 6.months.ago).pluck(:repo_full_name).uniq
  end

  def self.active_collab_repo_names
    Issue.not_protocol.where('created_at > ?', 6.months.ago).pluck(:repo_full_name).uniq
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
    Issue.not_protocol.not_employees.group(:user).count.each do |u, count|
      collabs = Issue.not_protocol.where(user: u).group(:org).count
      Issue.protocol.where(user: u).update_all(collabs: collabs.map(&:first))
    end
  end

  def pull_request?
    html_url && html_url.match?(/\/pull\//i)
  end

  def self.sync_merged_pull_requests
    protocol.pull_requests.where('closed_at > ?', 1.week.ago).state('closed').where(merged_at: nil).find_each(&:download_merged_at)
  end

  def download_merged_at
    return unless pull_request?
    return if merged_at.present?

    begin
      resp = Issue.github_client.pull_request(repo_full_name, number)
      update(merged_at: resp.merged_at) if resp.merged_at.present?
    rescue Octokit::NotFound
      destroy
    end
  end

  def self.sync_draft_pull_requests
    protocol.pull_requests.state('open').where('created_at > ?', 1.year.ago).find_each(&:download_draft)
  end

  def download_draft
    return unless pull_request?
    return if closed_at.present?
    begin
      resp = Issue.github_client.pull_request(repo_full_name, number)
      update(draft: resp.draft)
    rescue Octokit::NotFound
      destroy
    end
  end
end
