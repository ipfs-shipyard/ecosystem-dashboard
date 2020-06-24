class HomeController < ApplicationController
  def index

    period = (params[:range].presence || 7).to_i

    @new_issues = Issue.internal.this_period(period).not_core.issues.count
    @new_issues_last_week = Issue.internal.last_period(period).not_core.issues.count

    @new_prs = Issue.internal.this_period(period).not_core.pull_requests.count
    @new_prs_last_week = Issue.internal.last_period(period).not_core.pull_requests.count

    @merged_prs = Issue.internal.where('issues.merged_at > ?', period.days.ago).not_core.pull_requests.count
    @merged_prs_last_week = Issue.internal.where('issues.merged_at > ?', (period*2).days.ago).where('issues.merged_at < ?', period.days.ago).not_core.pull_requests.count

    @releases = Event.internal.this_period(period).event_type('ReleaseEvent').count

    @stars = Event.internal.this_period(period).not_core.event_type('WatchEvent').count
    @stars_last_week = Event.internal.last_period(period).not_core.event_type('WatchEvent').count

    @forks = Event.internal.this_period(period).not_core.event_type('ForkEvent').count
    @forks_last_week = Event.internal.not_core.last_period(period).event_type('ForkEvent').count

    @comments = Event.internal.this_period(period).not_core.event_type('IssueCommentEvent').count
    @comments_last_week = Event.internal.last_period(period).not_core.event_type('IssueCommentEvent').count

    @response_time = (Issue.internal.this_period(period).not_core.unlocked.where("html_url <> ''").not_draft.where.not(response_time: nil).average(:response_time).to_i/60/60).round(1)
    @response_time_last_week = (Issue.internal.last_period(period).not_core.unlocked.where("html_url <> ''").not_draft.where.not(response_time: nil).average(:response_time).to_i/60/60).round(1)

    @slow_responses = Issue.internal.this_period(period).not_core.unlocked.where("html_url <> ''").not_draft.slow_response.count
    @slow_responses_last_week = Issue.internal.last_period(period).not_core.unlocked.where("html_url <> ''").not_draft.slow_response.count

    @contributors = Issue.internal.this_period(period).not_core.unlocked.where("html_url <> ''").not_draft.group(:user).count.keys.length
    @contributors_last_week = Issue.internal.last_period(period).not_core.unlocked.where("html_url <> ''").not_draft.group(:user).count.keys.length

    @first_time_contributors = (Issue.internal.this_period(period).not_core.unlocked.where("html_url <> ''").not_draft.group(:user).count.keys - Issue.internal.where('issues.created_at < ?', period.days.ago).not_core.unlocked.where("html_url <> ''").not_draft.group(:user).count.keys).length
    @first_time_contributors_last_week = (Issue.internal.last_period(period).not_core.unlocked.where("html_url <> ''").not_draft.group(:user).count.keys - Issue.internal.where('issues.created_at < ?', (period*2).days.ago).not_core.unlocked.where("html_url <> ''").not_draft.group(:user).count.keys).length
  end
end
