class Contributor < ApplicationRecord
  validates_presence_of :github_username

  has_many :events, foreign_key: :user, primary_key: :github_username
  has_many :issues, foreign_key: :user, primary_key: :github_username

  scope :core, -> { where(core: true) }
  scope :bot,  -> { where(bot: true) }
  scope :core_or_bot, -> { core.or(bot) }

  def self.collabs_for(username)
    Event.external.user(username).event_type('PushEvent').group(:org).count.map(&:first)
  end

  def self.suggest_orgs(github_username)
    events = Issue.github_client.user_public_events(github_username)
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
end
