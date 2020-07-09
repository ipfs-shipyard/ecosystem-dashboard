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

  scope :this_period, ->(period) { where('events.created_at > ?', period.days.ago) }
  scope :last_period, ->(period) { where('events.created_at > ?', (period*2).days.ago).where('events.created_at < ?', period.days.ago) }
  scope :this_week, -> { where('events.created_at > ?', 1.week.ago) }
  scope :last_week, -> { where('events.created_at > ?', 2.week.ago).where('events.created_at < ?', 1.week.ago) }

  scope :search, ->(query) { where('payload::text ilike ?', "%#{query}%") }

  def contributed?
    return true unless contributor.present?
    !contributor.core?
  end

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

  def title
    "#{actor} #{action_text} #{repository.full_name}"
  end

  def html_url
    case event_type
    when 'WatchEvent'
      "https://github.com/#{repository.full_name}/stargazers"
    when "CreateEvent"
      "https://github.com/#{repository.full_name}/tree/#{payload['ref']}"
    when "CommitCommentEvent"
      payload['comment']['html_url']
    when "ReleaseEvent"
      payload['release']['html_url']
    when "IssuesEvent"
      payload['issue']['html_url']
    when "DeleteEvent"
      "https://github.com/#{repository.full_name}"
    when "IssueCommentEvent"
      payload['comment']['html_url']
    when "PublicEvent"
      "https://github.com/#{repository.full_name}"
    when "PushEvent"
      "https://github.com/#{repository.full_name}/commits/#{payload['ref'].gsub("refs/heads/", '')}"
    when "PullRequestReviewCommentEvent"
      payload['comment']['html_url']
    when "PullRequestEvent"
      payload['pull_request']['html_url']
    when "ForkEvent"
      payload['forkee']['html_url']
    when 'MemberEvent'
      "https://github.com/#{payload['member']['login']}"
    when 'GollumEvent'
      payload['pages'].first['html_url']
    end
  end

  def action_text
    case event_type
    when 'WatchEvent'
      'starred'
    when "CreateEvent"
      "created a #{payload['ref_type']} on"
    when "CommitCommentEvent"
      'commented on a commit on'
    when "ReleaseEvent"
      "#{action} a release on"
    when "IssuesEvent"
      "#{action} an issue on"
    when "DeleteEvent"
      "deleted a #{payload['ref_type']}"
    when "IssueCommentEvent"
      if payload['issue']['pull_request'].present?
        "#{action} a comment on a pull request on"
      else
        "#{action} a comment on an issue on"
      end
    when "PublicEvent"
      'open sourced'
    when "PushEvent"
      "pushed #{ActionController::Base.helpers.pluralize(payload['size'], 'commit')} to #{payload['ref'].gsub("refs/heads/", '')}"
    when "PullRequestReviewCommentEvent"
      "#{action} a review comment on an pull request on"
    when "PullRequestEvent"
      "#{action} an pull request on"
    when "ForkEvent"
      'forked'
    when 'MemberEvent'
      "#{action} #{payload['member']['login']} to"
    when 'GollumEvent'
      "#{payload['pages'].first['action']} a wiki page on"
    end
  end
end
