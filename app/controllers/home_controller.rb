class HomeController < ApplicationController
  def index

    @event_scope = Event.internal
    @issues_scope = Issue.internal
    @repos_scope = Repository.internal
    @packages_scope = Package.internal
    @search_results_scope = SearchResult.all

    if params[:org].present?
      @event_scope = @event_scope.org(params[:org])
      @issues_scope = @issues_scope.org(params[:org])
      @repos_scope = @repos_scope.org(params[:org])
      @packages_scope = @packages_scope.org(params[:org])
    end

    @period = (params[:range].presence || 7).to_i

    @new_issues = @issues_scope.this_period(@period).not_core.issues.count
    @new_issues_last_week = @issues_scope.last_period(@period).not_core.issues.count

    @new_prs = @issues_scope.this_period(@period).not_core.pull_requests.count
    @new_prs_last_week = @issues_scope.last_period(@period).not_core.pull_requests.count

    @merged_prs = @issues_scope.where('issues.merged_at > ?', @period.days.ago).not_core.pull_requests.count
    @merged_prs_last_week = @issues_scope.where('issues.merged_at > ?', (@period*2).days.ago).where('issues.merged_at < ?', @period.days.ago).not_core.pull_requests.count

    @new_collab_contribs = @issues_scope.this_period(@period).all_collabs.count
    @new_collab_contribs_last_week = @issues_scope.last_period(@period).all_collabs.count


    @releases = @event_scope.this_period(@period).event_type('ReleaseEvent').count
    @releases_last_week = @event_scope.last_period(@period).event_type('ReleaseEvent').count

    @stars = @event_scope.this_period(@period).not_core.event_type('WatchEvent').count
    @stars_last_week = @event_scope.last_period(@period).not_core.event_type('WatchEvent').count

    @forks = @event_scope.this_period(@period).not_core.event_type('ForkEvent').count
    @forks_last_week = @event_scope.not_core.last_period(@period).event_type('ForkEvent').count

    @comments = @event_scope.this_period(@period).not_core.event_type('IssueCommentEvent').count
    @comments_last_week = @event_scope.last_period(@period).not_core.event_type('IssueCommentEvent').count

    @response_time = (@issues_scope.this_period(@period).not_core.unlocked.where("html_url <> ''").not_draft.where.not(response_time: nil).average(:response_time).to_i/60.0/60.0).round(1)
    @response_time_last_week = (@issues_scope.last_period(@period).not_core.unlocked.where("html_url <> ''").not_draft.where.not(response_time: nil).average(:response_time).to_i/60.0/60.0).round(1)

    @slow_responses = @issues_scope.this_period(@period).not_core.unlocked.where("html_url <> ''").not_draft.slow_response.count
    @slow_responses_last_week = @issues_scope.last_period(@period).not_core.unlocked.where("html_url <> ''").not_draft.slow_response.count

    @contributors = @issues_scope.this_period(@period).not_core.unlocked.where("html_url <> ''").not_draft.group(:user).count.keys.length
    @contributors_last_week = @issues_scope.last_period(@period).not_core.unlocked.where("html_url <> ''").not_draft.group(:user).count.keys.length

    @first_time_contributors = (@issues_scope.this_period(@period).not_core.unlocked.where("html_url <> ''").not_draft.group(:user).count.keys - @issues_scope.where('issues.created_at < ?', @period.days.ago).not_core.unlocked.where("html_url <> ''").not_draft.group(:user).count.keys).length
    @first_time_contributors_last_week = (@issues_scope.last_period(@period).not_core.unlocked.where("html_url <> ''").not_draft.group(:user).count.keys - @issues_scope.where('issues.created_at < ?', (@period*2).days.ago).not_core.unlocked.where("html_url <> ''").not_draft.group(:user).count.keys).length

    # @active_collabs = Organization.active_collabs(@event_scope.this_period(@period)).length
    # @active_collabs_last_week = Organization.active_collabs(@event_scope.last_period(@period)).length
    #
    # repo_ids = RepositoryDependency.where(package_id: @packages_scope.pluck(:id)).group(:repository_id).count.keys
    # @community_repo_scope = Repository.community.where(id: repo_ids)
    # @new_community_repositories = @community_repo_scope.this_period(@period).count
    # @new_community_repositories_last_week = @community_repo_scope.last_period(@period).count
    #
    # @community_package_scope = Package.joins(:dependencies).where('dependencies.package_id in (?)', @packages_scope.pluck(:id)).group(:id).community
    # @new_community_packages = @community_package_scope.this_period(@period).count.keys.length
    # @new_community_packages_last_week = @community_package_scope.last_period(@period).count.keys.length
    #
    # @new_search_results = @search_results_scope.this_period(@period).count
    # @new_search_results_last_week = @search_results_scope.last_period(@period).count
  end

  def sitemap
    @routes = Rails.application.routes.routes.map do |route|
      {alias: route.name, path: route.path.spec.to_s[0..-11], controller: route.defaults[:controller], action: route.defaults[:action]}
    end 
    
    @routes.sort_by!{|r| r[:path]}

    banned_controllers = [
      "rails/info", 
      "rails/welcome",
      "admin/contributors", 
      "admin/organizations", 
      "sessions",
      "forage",
      nil
    ]
    @routes.reject! {|route| banned_controllers.include?(route[:controller])}
    @routes.reject! {|route| route[:alias].blank? }
    @routes.reject! {|route| route[:path].include?(':') || route[:path].blank? }
  
  end
end
