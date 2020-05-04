class Event < ApplicationRecord

  belongs_to :repository

  scope :protocol, -> { where(org: Issue::PROTOCOL_ORGS) }
  scope :org, ->(org) { where(org: org) }
  scope :user, ->(user) { where(actor: user)}
  scope :repo, ->(repository_full_name) { where(repository_full_name: repository_full_name)}
  scope :event_type, ->(event_type) { where(event_type: event_type)}

  scope :humans, -> { where.not(actor: Issue::BOTS + ['ghost']) }
  scope :bots, -> { where(actor: Issue::BOTS) }
  scope :employees, -> { where(actor: Issue::EMPLOYEES) }
  scope :not_employees, -> { where.not(actor: Issue::EMPLOYEES + Issue::BOTS) }

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
