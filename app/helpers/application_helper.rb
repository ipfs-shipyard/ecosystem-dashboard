module ApplicationHelper
  include Pagy::Frontend
  ALERT_TYPES = {
    success: 'alert-success',
    error: 'alert-danger',
    alert: 'alert-warning',
    notice: 'alert-info'
  }.freeze

  def bootstrap_class_for(flash_type)
    ALERT_TYPES[flash_type.to_sym] || flash_type.to_s
  end

  def collab_title
    return nil if action_name == 'all'
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

  def issues_title
    words = []

    words << 'Uncommented' if params[:uncommented].present?
    words << language_title(params[:language]) if params[:language]
    words << (params[:state].present? ? params[:state].capitalize : 'All')
    words << (params[:type].present? ? params[:type].humanize : 'Issues and PRs')
    words << "labelled \"#{Array(params[:label]).join('+')}\"" if params[:label]
    words << "in the last #{@range} days created by"

    if params[:user].present?
      words << Array(params[:user]).join('+')
    elsif params[:only_collabs].present?
      words << 'collab contributors'
    elsif params[:collab].present?
      words << "#{Array(params[:collab]).join('+')} contributors"
    else
      if params[:exclude_core].present?
        words << "non-core contributors"
      elsif params[:community].present?
        words << "community contributors"
      else
        words << "all contributors"
      end
    end

    words << "on #{Array(params[:repo_full_name]).join('+')}" if params[:repo_full_name].present?
    words << "in #{Array(params[:org]).join('+')}" if params[:org] && params[:repo_full_name].blank?

    words.compact.join(' ')
  end

  def diff_class(count)
    count > 0 ? 'text-success' : 'text-danger'
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
      'trash'
    when "IssueCommentEvent"
      'comment'
    when "PublicEvent"
      'squirrel'
    when "PushEvent"
      'repo-push'
    when "PullRequestReviewCommentEvent"
      'comment-discussion'
    when "PullRequestReviewEvent"
      'code-review'
    when "PullRequestEvent"
      'git-pull-request'
    when "ForkEvent"
      'repo-forked'
    when 'MemberEvent'
      'person'
    end
  end

  def search_result_icon(kind)
    case kind
    when 'code'
      'code-square'
    when 'repositories'
      'repo'
    when 'issues'
      'issue-opened'
    when 'commits'
      'commit'
    else
      'code-square'
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
    when "PullRequestReviewEvent"
      'Review'
    when "PullRequestEvent"
      'Pull Requests'
    when "ForkEvent"
      'Forked'
    when 'MemberEvent'
      'Member'
    when 'GollumEvent'
      'Wiki update'
    else
      "*#{event_type}*"
    end
  end

  def parse_markdown(str)
    return if str.blank?
    content_tag :div, class: 'markdown' do
      render_markdown(str)
    end
  end

  def render_markdown(str)
    return if str.blank?
    CommonMarker.render_html(str, :UNSAFE, [:tagfilter, :autolink, :table, :strikethrough]).html_safe
  end

  def page_title
    title = ""
    title += "#{@page_title} - " if @page_title.present?
    title += "#{display_name} Ecosystem Dashboard"
  end

  def brand_icon_url
    return unless default_org_name.present?
    "https://github.com/#{default_org_name}.png"
  end

  def default_org_name
    @default_org_name ||= ENV['DEFAULT_ORG'].presence || Organization.internal_org_names.first
  end

  def display_name
    ENV['DISPLAY_NAME'].presence || default_org_name
  end

  def compressed_list(array)
    return array.join(', ') if array.length < 8
    array[0..2].join(', ') + ' ... ' + array[-3..-1].join(', ')
  end

  def bool_icon(bool)
    if bool
      octicon('check-circle-fill', class: 'text-success', height: 20)
    else
      octicon('x-circle-fill', class: 'text-danger', height: 20)
    end
  end

  def existing_or_new_file(repo, method, filename)
    repo.send(method).present? ? repo.file_url(repo.send(method)) : repo.new_file_url(filename)
  end

  def bucket(user, events_scope)
    score = Pmf.score_for_user(user, events_scope)
    state = Pmf.state_for_user(user, score)
    "#{state} (#{score})"
  end
end
