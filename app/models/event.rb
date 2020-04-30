class Event < ApplicationRecord

  belongs_to :repository

  scope :protocol, -> { where(org: Issue::PROTOCOL_ORGS) }
  scope :org, ->(org) { where(org: org) }
  scope :user, ->(user) { where(actor: user)}
  scope :event_type, ->(event_type) { where(event_type: event_type)}

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
