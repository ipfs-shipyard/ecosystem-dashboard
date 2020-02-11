class IssuesController < ApplicationController
  def index
    @scope = Issue.all.where("html_url <> ''")
    @scope = @scope.where(user: params[:user]) if params[:user].present?
    @scope = @scope.where(state: params[:state]) if params[:state].present?
    @scope = @scope.where(repo_full_name: params[:repo_full_name]) if params[:repo_full_name].present?
    @scope = @scope.where(org: params[:org]) if params[:org].present?
    @pagy, @issues = pagy(@scope.order('issues.created_at DESC'))
    @users = @scope.unscope(where: :user).group(:user).count
    @states = @scope.unscope(where: :state).group(:state).count
    @repos = @scope.unscope(where: :repo_full_name).group(:repo_full_name).count
    @orgs = @scope.unscope(where: :org).group(:org).count

  end
end
