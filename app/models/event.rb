class Event < ApplicationRecord

  belongs_to :repository
  belongs_to :contributor, foreign_key: :actor, primary_key: :github_username, optional: true
  belongs_to :organization, foreign_key: :org, primary_key: :name, optional: true

  scope :internal, -> { includes(:organization).where(organizations: {internal: true}) }
  scope :external, -> { includes(:organization).where(organizations: {internal: false}) }
  scope :org, ->(org) { where(org: org) }
  scope :user, ->(user) { where(actor: user)}
  scope :repo, ->(repository_full_name) { where(repository_full_name: repository_full_name)}
  scope :event_type, ->(event_type) { where(event_type: event_type)}

  scope :humans, -> { core.or(not_core) }
  scope :bots, -> { includes(:contributor).where(contributors: {bot: true}) }
  scope :core, -> { includes(:contributor).where(contributors: {core: true}) }
  scope :not_core, -> { includes(:contributor).where(contributors: {id: nil}) }

  scope :this_week, -> { where('events.created_at > ?', 1.week.ago) }
  scope :last_week, -> { where('events.created_at > ?', 2.week.ago).where('events.created_at < ?', 1.week.ago) }

  def self.record_event(repository, event_json)
    e = Event.find_or_initialize_by(github_id: event_json.id)

    e.actor = event_json.actor.login
    e.event_type = event_json.type
    e.action = event_json.payload.action
    e.repository_id = repository.id
    e.repository_full_name = repository.full_name
    e.org = repository.org
    e.payload = event_json.payload.to_h
    e.created_at = event_json.created_at
    e.save if e.changed?
  end
end
