class HomeController < ApplicationController
  def index

    @new_issues = Issue.internal.this_week.not_core.issues.count
    @new_issues_last_week = Issue.internal.last_week.not_core.issues.count

    @new_prs = Issue.internal.this_week.not_core.pull_requests.count
    @new_prs_last_week = Issue.internal.last_week.not_core.pull_requests.count

    @releases = Event.internal.this_week.event_type('ReleaseEvent').count

    @stars = Event.internal.this_week.event_type('WatchEvent').count
    @stars_last_week = Event.internal.last_week.event_type('WatchEvent').count

    @forks = Event.internal.this_week.event_type('ForkEvent').count
    @forks_last_week = Event.internal.last_week.event_type('ForkEvent').count

    @comments = Event.internal.this_week.not_core.event_type('IssueCommentEvent').count
    @comments_last_week = Event.internal.last_week.not_core.event_type('IssueCommentEvent').count

    @response_time = (Issue.internal.this_week.not_core.unlocked.where("html_url <> ''").not_draft.where.not(response_time: nil).average(:response_time)/60/60).round(1)
    @response_time_last_week = (Issue.internal.last_week.not_core.unlocked.where("html_url <> ''").not_draft.where.not(response_time: nil).average(:response_time)/60/60).round(1)

    @slow_responses = Issue.internal.this_week.not_core.unlocked.where("html_url <> ''").not_draft.slow_response.count
    @slow_responses_last_week = Issue.internal.last_week.not_core.unlocked.where("html_url <> ''").not_draft.slow_response.count

    @contributors = Issue.internal.this_week.not_core.unlocked.where("html_url <> ''").not_draft.group(:user).count.keys.length
    @contributors_last_week = Issue.internal.last_week.not_core.unlocked.where("html_url <> ''").not_draft.group(:user).count.keys.length

    @first_time_contributors = (Issue.internal.this_week.not_core.unlocked.where("html_url <> ''").not_draft.group(:user).count.keys - Issue.internal.where('issues.created_at < ?', 1.week.ago).not_core.unlocked.where("html_url <> ''").not_draft.group(:user).count.keys).length
    @first_time_contributors_last_week = (Issue.internal.last_week.not_core.unlocked.where("html_url <> ''").not_draft.group(:user).count.keys - Issue.internal.where('issues.created_at < ?', 2.weeks.ago).not_core.unlocked.where("html_url <> ''").not_draft.group(:user).count.keys).length
  end
end
