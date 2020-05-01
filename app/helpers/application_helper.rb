module ApplicationHelper
  include Pagy::Frontend

  def collab_title
    params[:collab].presence || 'collab'
  end

  def language_title(lang)
    case lang
    when 'py'
      'Python'
    when 'cs'
      'C#'
    else
      lang
    end
  end

  def issue_colour(issue)
    return 'merged' if issue.merged_at
    return 'draft' if issue.draft?
    issue.state == 'open' ? 'success' : 'danger'
  end

  def repo_icon(repo)
    return 'archive' if repo.archived?
    return 'repo-forked' if repo.fork?
    'repo'
  end

  def event_icon(event)
    case event.event_type
    when 'WatchEvent'
      'star'
    when "CreateEvent"
      'git-branch'
    when "CommitCommentEvent"
      'comment'
    when "ReleaseEvent"
      'tag'
    when "IssuesEvent"
      'issue-opened'
    when "DeleteEvent"
      'trashcan'
    when "IssueCommentEvent"
      'comment'
    when "PublicEvent"
      'squirrel'
    when "PushEvent"
      'repo-push'
    when "PullRequestReviewCommentEvent"
      'comment-discussion'
    when "PullRequestEvent"
      'git-pull-request'
    when "ForkEvent"
      'repo-forked'
    end
  end

  def event_title(event)
    case event.event_type
    when 'WatchEvent'
      'starred'
    when "CreateEvent"
      'created branch on'
    when "CommitCommentEvent"
      'commented on a commit on'
    when "ReleaseEvent"
      "#{event.action} a release on"
    when "IssuesEvent"
      "#{event.action} an issue on"
    when "DeleteEvent"
      "deleted a #{event.payload['ref_type']}"
    when "IssueCommentEvent"
      "#{event.action} a comment on an issue on"
    when "PublicEvent"
      'open sourced'
    when "PushEvent"
      'pushed to'
    when "PullRequestReviewCommentEvent"
      "#{event.action} a review comment on an pull request on"
    when "PullRequestEvent"
      "#{event.action} an pull request on"
    when "ForkEvent"
      'forked'
    end
  end

  def event_name(event_type)
    case event_type
    when 'WatchEvent'
      'Starred'
    when "CreateEvent"
      'Branched'
    when "CommitCommentEvent"
      'Commit Comments'
    when "ReleaseEvent"
      'Release'
    when "IssuesEvent"
      'Issues'
    when "DeleteEvent"
      'Delete Branch'
    when "IssueCommentEvent"
      'Issue Comment'
    when "PublicEvent"
      'Open Sourced'
    when "PushEvent"
      'Pushed'
    when "PullRequestReviewCommentEvent"
      'Review Comments'
    when "PullRequestEvent"
      'Pull Requests'
    when "ForkEvent"
      'Forked'
    end
  end

  def parse_markdown(str)
    return if str.blank?
    content_tag :div, class: 'markdown' do
      CommonMarker.render_html(str, :UNSAFE, [:tagfilter, :autolink, :table, :strikethrough]).html_safe
    end
  end
end
