class IssuesController < ApplicationController
  def index
    @scope = Issue.protocol.humans.where("html_url <> ''")

    if params[:collab].present?
      @collab_users = Issue.org_contributor_names(params[:collab])
    else
      @collab_users = Issue.not_protocol.humans.not_employees.group(:user).count
    end

    @scope = @scope.where(comments_count: 0) if params[:uncommented].present?

    @scope = @scope.where(user: @collab_users.map(&:first))

    @scope = @scope.where(user: params[:user]) if params[:user].present?
    @scope = @scope.where(state: params[:state]) if params[:state].present?
    @scope = @scope.where(repo_full_name: params[:repo_full_name]) if params[:repo_full_name].present?
    @scope = @scope.where(org: params[:org]) if params[:org].present?
    @pagy, @issues = pagy(@scope.order('issues.created_at DESC'))

    @users = @scope.unscope(where: :user).humans.where(user: @collab_users.map(&:first)).group(:user).count

    @states = @scope.unscope(where: :state).group(:state).count
    @repos = @scope.unscope(where: :repo_full_name).group(:repo_full_name).count
    @orgs = @scope.unscope(where: :org).protocol.group(:org).count
    @collabs = @scope.unscope(where: :user).unscope(where: :org).humans.not_employees.not_protocol.group(:org).count
  end
end
