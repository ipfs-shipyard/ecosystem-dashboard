class IssuesController < ApplicationController
  def index
    @scope = Issue.protocol.not_employees.where("html_url <> ''")

    if params[:collab].present?
      @scope = @scope.collab(params[:collab])
    else
      @scope = @scope.all_collabs
    end

    @scope = @scope.where(comments_count: 0) if params[:uncommented].present?

    @scope = @scope.where(user: params[:user]) if params[:user].present?
    @scope = @scope.where(state: params[:state]) if params[:state].present?
    @scope = @scope.where(repo_full_name: params[:repo_full_name]) if params[:repo_full_name].present?
    @scope = @scope.where(org: params[:org]) if params[:org].present?
    @pagy, @issues = pagy(@scope.order('issues.created_at DESC'))

    @users = @scope.unscope(where: :user).not_employees.group(:user).count

    @states = @scope.unscope(where: :state).group(:state).count
    @repos = @scope.unscope(where: :repo_full_name).group(:repo_full_name).count
    @orgs = @scope.unscope(where: :org).protocol.group(:org).count
    @collabs = @scope.unscope(where: :collabs).all_collabs.pluck(:collabs).flatten.inject(Hash.new(0)) { |h, e| h[e] += 1 ; h }
  end

  def collabs
    @scope = Issue.protocol.not_employees.where("html_url <> ''")
    @collabs = @scope.all_collabs.pluck(:collabs).flatten.inject(Hash.new(0)) { |h, e| h[e] += 1 ; h }.sort_by{|k,v| -v }
  end
end
