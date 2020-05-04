class OrgsController < ApplicationController
  def protocol
    scope = Issue.all

    if params[:range].present?
      scope = scope.where('created_at > ?', params[:range].to_i.days.ago)
    end

    @orgs =Issue::PROTOCOL_ORGS.map do |org|
      load_org_data(scope, org)
    end
  end

  def show
    scope = Issue.all

    if params[:range].present?
      scope = scope.where('created_at > ?', params[:range].to_i.days.ago)
    end

    @orgs = [load_org_data(scope, params[:id])]
  end

  def events
    @scope = Event.org(params[:id]).includes(:repository).where('created_at > ?', 1.month.ago).humans
    @scope = @scope.user(params[:user]) if params[:user].present?
    @scope = @scope.repo(params[:repo_full_name]) if params[:repo_full_name].present?
    @scope = @scope.event_type(params[:event_type]) if params[:event_type].present?
    @pagy, @events = pagy(@scope.order('created_at DESC'))

    @repos = @scope.unscope(where: :repository_full_name).protocol.group(:repository_full_name).count
    @users = @scope.unscope(where: :actor).humans.group(:actor).count
    @event_types = @scope.unscope(where: :event_type).group(:event_type).count
  end

  private

  def load_org_data(scope, org)
    {
      name: org,
      issues_count: scope.issues.org(org).count,
      open_issues_count: scope.issues.org(org).state('open').count,
      closed_issues_count: scope.issues.org(org).state('closed').count,
      pull_requests_count: scope.pull_requests.org(org).count,
      open_pull_requests_count: scope.pull_requests.org(org).state('open').count,
      closed_pull_requests_count: scope.pull_requests.org(org).state('closed').count,
      comments: scope.org(org).sum(:comments_count),
      contributors: scope.org(org).humans.employees.group(:user).count.sort_by(&:last).reverse,
      community_contributors: scope.org(org).not_employees.group(:user).count.sort_by(&:last).reverse,
      bots: scope.org(org).bots.group(:user).count.sort_by(&:last).reverse,
      repos: scope.org(org).group(:repo_full_name).count.sort_by(&:last).reverse
    }
  end
end
