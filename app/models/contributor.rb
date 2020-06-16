class Contributor < ApplicationRecord
  validates_presence_of :github_username

  has_many :events, foreign_key: :user, primary_key: :github_username
  has_many :issues, foreign_key: :user, primary_key: :github_username

  scope :core, -> { where(core: true) }
  scope :bot,  -> { where(bot: true) }
  scope :core_or_bot, -> { core.or(bot) }

  def self.suggest_orgs(github_username)
    events = Issue.github_client.user_public_events(github_username)
    pushes = events.select{|e| e[:type] == 'PushEvent'}
    orgs = pushes.map(&:org).compact.map(&:login).uniq
  end

  def self.find_top_external_contributors
    external_contributors = Issue.not_core.group(:user).count
    top_external_contributors = external_contributors.sort_by{|k,v| -v}.first(external_contributors.length/20).map(&:first)
  end

  def self.find_possible_collabs
    possible_collabs = {}
    find_top_external_contributors.each do |github_username|
      begin
        orgs = suggest_orgs(github_username)
        orgs = pushes.map(&:org).compact.map(&:login).uniq
        if orgs.any?
          possible_collabs[github_username] = orgs
        end
      rescue Octokit::NotFound
        next
      end
    end
    possible_collabs.values.flatten.uniq - Organization.all.pluck(:name)
  end
end
