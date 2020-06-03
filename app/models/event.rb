class Event < ApplicationRecord

  belongs_to :repository

  scope :internal, -> { where(org: Issue::INTERNAL_ORGS) }
  scope :external, -> { where.not(org: Issue::INTERNAL_ORGS) }
  scope :org, ->(org) { where(org: org) }
  scope :user, ->(user) { where(actor: user)}
  scope :repo, ->(repository_full_name) { where(repository_full_name: repository_full_name)}
  scope :event_type, ->(event_type) { where(event_type: event_type)}

  scope :humans, -> { where.not(actor: Issue::BOTS + ['ghost']) }
  scope :bots, -> { where(actor: Issue::BOTS) }
  scope :core, -> { where(actor: Issue::CORE_CONTRIBUTORS) }
  scope :not_core, -> { where.not(actor: Issue::CORE_CONTRIBUTORS + Issue::BOTS) }

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
