class Organization < ApplicationRecord
  validates_presence_of :name
  validates_uniqueness_of :name

  scope :internal, -> { where(internal: true) }
  scope :collaborator, -> { where(collaborator: true) }

  has_many :events, foreign_key: :org, primary_key: :name
  has_many :issues, foreign_key: :org, primary_key: :name
  has_many :repositories, foreign_key: :org, primary_key: :name
  has_many :repository_dependencies, through: :repositories

  def import
    Repository.import_org(name)
    first_repo_date = Repository.org(name).order('created_at ASC').first.created_at
    Repository.archived(false).org(name).each{|r| Issue.download(r.full_name, first_repo_date) }
    # TODO sync all imported issues
    Repository.archived(false).org(name).find_missing_npm_packages
    Repository.archived(false).org(name).find_missing_cargo_packages
    Repository.archived(false).org(name).find_missing_go_packages
    # TODO Repository.archived(false).org(name).find_each(&:download_tags)
    guess_core_contributors
    guess_bots
    # TODO find and import collabs
  end

  def guess_core_contributors
    core = pushing_contributor_names.select{|n| Event.internal.where(event_type: 'PushEvent').user(n).group(:repository_full_name).count.length > 1 }

    core.each do |name|
      Contributor.find_or_create_by(github_username: name, core: true)
    end
  end

  def guess_bots
    names = (Event.internal.group(:actor).count.keys + Issue.internal.group(:user).count.keys).uniq
    bot_names = names.select{|n| n.match(/-bot$/i) || n.match(/\[bot\]$/i) }
    bot_names.each do |name|
      Contributor.find_or_create_by(github_username: name, bot: true)
    end
  end

  def sync_docker_packages
    docker_image_names.each{|name| PackageManager::Docker.update(name) }
  end

  def docker_image_names
    return [] unless docker_hub_org.present?
    PackageManager::Docker.org_package_names(docker_hub_org)
  end

  def pushing_contributor_names
    events.where(event_type: 'PushEvent').group(:actor).count.reject{|n| n.match(/-bot$/i) || n.match(/\[bot\]$/i) }.keys
  end

  def update_counts
    self.events_count = Event.internal.user(pushing_contributor_names).not_core.this_period(30).count
    self.search_results_count = SearchResult.where(org: name).this_period(30).count
    save
  end

  def self.active_collabs(event_scope)
    external_users = event_scope.not_core.pluck(:actor).uniq
    active_collab_names = Event.external.user(external_users).event_type('PushEvent').group(:org).count.map(&:first)
  end
end
