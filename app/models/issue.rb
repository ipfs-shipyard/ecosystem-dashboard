class Issue < ApplicationRecord

  PROTOCOL_ORGS = ['ipfs', 'libp2p', 'ipfs-shipyard', 'multiformats', 'ipld']
  BOTS = ['dependabot[bot]', 'dependabot-preview[bot]', 'greenkeeper[bot]',
          'greenkeeperio-bot', 'ghost', 'rollbar[bot]', 'guardrails[bot]',
          'waffle-iron', 'imgbot[bot]', 'codetriage-readme-bot', 'whitesource-bolt-for-github[bot]',
          'gitter-badger']
  EMPLOYEES = ["Stebalien", "daviddias", "whyrusleeping", "RichardLitt", "hsanjuan",
                "alanshaw", "jbenet", "lidel", "tomaka", "hacdias", "lgierth", "dignifiedquire",
                "victorb", "Kubuxu", "vmx", "achingbrain", "vasco-santos", "jacobheun",
                "raulk", "olizilla", "satazor", "magik6k", "flyingzumwalt", "kevina",
                "satazor", "vyzo", "pgte", "PedroMiguelSS", "chriscool", "hugomrdias",
                "jessicaschilling", 'aschmahmann', 'dirkmc', 'ericronne', 'andrew',
                "Mr0grog", 'rvagg', 'lanzafame', 'mikeal', 'warpfork', 'terichadbourne',
                'mburns', 'nonsense', 'twittner', 'momack2', 'creationix', 'djdv',
                'jimpick', 'meiqimichelle', 'mgoelzer', 'kishansagathiya', 'dryajov',
                'autonome', 'bigs', 'jesseclay']

  LANGUAGES = ['Go', 'JS', 'Rust', 'py', 'Java']

  scope :protocol, -> { where(org: PROTOCOL_ORGS) }
  scope :not_protocol, -> { where.not(org: PROTOCOL_ORGS) }
  scope :humans, -> { where.not(user: BOTS) }
  scope :not_employees, -> { where.not(user: EMPLOYEES + BOTS) }
  scope :all_collabs, -> { where.not("collabs = '{}'") }
  scope :collab, ->(collab) { where("collabs @> ARRAY[?]::varchar[]", collab)  }

  scope :pull_requests, -> { where("html_url like ?", '%/pull/%') }
  scope :issues, -> { where.not("html_url like ?", '%/pull/%') }

  scope :language, ->(language) { where('repo_full_name ilike ?', "%/#{language}-%") }

  def self.download(repo_full_name)
    remote_issues = github_client.issues(repo_full_name, state: 'all')
    remote_issues.each do |remote_issue|
      begin
        issue = Issue.find_or_create_by(repo_full_name: repo_full_name, number: remote_issue.number)
        issue.title = remote_issue.title.delete("\u0000")
        issue.body = remote_issue.body.try(:delete, "\u0000")
        issue.state = remote_issue.state
        issue.html_url = remote_issue.html_url
        issue.comments_count = remote_issue.comments
        issue.user = remote_issue.user.login
        issue.closed_at = remote_issue.closed_at
        issue.created_at = remote_issue.created_at
        issue.updated_at = remote_issue.updated_at
        issue.org = repo_full_name.split('/').first
        issue.save if issue.changed?
      rescue ArgumentError
        # derp
      end
    end
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

  def self.org_contributor_names(org_name)
    Issue.where(org: org_name).not_employees.group(:user).count
  end

  def self.collab_orgs
    Issue.not_protocol.group(:org).count
  end

  def self.download_active_repos
    active_repo_names.each{|repo_full_name| download(repo_full_name) }
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
end
