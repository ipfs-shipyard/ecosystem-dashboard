class Contributor < ApplicationRecord
  validates :github_username, presence: true, uniqueness: true

  has_many :events, foreign_key: :actor, primary_key: :github_username
  has_many :issues, foreign_key: :user, primary_key: :github_username

  scope :core, -> { where(core: true) }
  scope :bot,  -> { where(bot: true) }
  scope :core_or_bot, -> { core.or(bot) }

  def to_s
    github_username
  end

  def self.download(github_username)
    contrib = find_or_create_by(github_username: github_username)
  end

  def self.collabs_for(username)
    Event.external.user(username).event_type('PushEvent').group(:org).count.map(&:first)
  end

  def self.suggest_orgs(github_username)
    events = AuthToken.client.user_public_events(github_username)
    pushes = events.select{|e| e[:type] == 'PushEvent'}
    orgs = pushes.map(&:org).compact.map(&:login).uniq
  end

  def self.top_external_contributors
    external_contributors = Issue.not_core.group(:user).count
    top_external_contributors = external_contributors.sort_by{|k,v| -v}.first(external_contributors.length/20).map(&:first)
  end

  def self.recent_external_contributors
    Issue.internal.this_week.not_core.group(:user).count.keys
  end

  def self.find_possible_collabs(contributors)
    possible_collabs = {}
    contributors.each do |github_username|
      begin
        orgs = suggest_orgs(github_username)
        if orgs.any?
          possible_collabs[github_username] = orgs
        end
      rescue Octokit::NotFound
        next
      end
    end
    possible_collabs.values.flatten.uniq - Organization.all.pluck(:name)
  end

  def self.filter_possible_collabs(orgs, query = ENV['DEFAULT_ORG'])
    searches = {}
    orgs.each do |org|
      sleep 5
      begin
        search = Octokit::Client.new(access_token: ENV['GITHUB_TOKEN']).search_code("org:#{org} #{query}", per_page: 1)
        searches[org] = search.total_count
      rescue Octokit::UnprocessableEntity
        searches[org] = 0
      end
    end
    searches.select{|k,v| v > 10 }
  end

  def sync
    Contributor.download(github_username)
    sync_details
    sync_events
  end

  def sync_details
    begin
      u = AuthToken.client.user(github_username)
      self.update(github_id: u.id)
      # TODO update other details here
    rescue Octokit::NotFound
      # TODO record if account has been deleted and don't sync anymore
    rescue Octokit::Error
      # handle other octokit errors
    end
  end

  def sync_events(auto_paginate = false)
    download_events(auto_paginate).each do |e|
      repo = Repository.find_by_full_name(e['repo']['name'])
      Event.record_event(repo, e)
    end
  end

  def download_events(auto_paginate = false)
    client = Octokit::Client.new(access_token: ENV['GITHUB_TOKEN'])
    begin
      if auto_paginate || etag.blank?
        events = client.user_public_events(github_username, auto_paginate: auto_paginate)
      else
        events = client.user_public_events(github_username, headers: {'If-None-Match' => etag})
      end

      update_column(:last_events_sync_at, Time.zone.now)
      return [] if events == ''
      new_etag = client.last_response.headers['etag']
      if !auto_paginate && new_etag && new_etag != etag
        update_column(:etag, new_etag)
      end
      events
    rescue *Repository::IGNORABLE_EXCEPTIONS
      []
    end
  end
end
