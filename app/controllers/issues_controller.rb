class IssuesController < ApplicationController
  def index
    @scope = Issue.protocol.not_employees.where("html_url <> ''")

    if params[:collab].present?
      @scope = @scope.collab(params[:collab])
    else
      @scope = @scope.all_collabs
    end

    apply_filters
    @collabs = @scope.unscope(where: :collabs).all_collabs.pluck(:collabs).flatten.inject(Hash.new(0)) { |h, e| h[e] += 1 ; h }
  end

  def collabs
    @scope = Issue.protocol.not_employees.where("html_url <> ''")
    @collabs = @scope.all_collabs.pluck(:collabs).flatten.inject(Hash.new(0)) { |h, e| h[e] += 1 ; h }.sort_by{|k,v| -v }
  end

  def all
    @scope = Issue.protocol.humans.where("html_url <> ''")

    @scope = @scope.not_employees if params[:exclude_employees]

    apply_filters
  end

  private

  def apply_filters
    @scope = @scope.where(comments_count: 0) if params[:uncommented].present?

    @scope = @scope.where('created_at > ?', 1.month.ago) if params[:recent].present?

    @scope = @scope.no_milestone if params[:no_milestone].present?

    @scope = @scope.unlabelled if params[:unlabelled].present?

    @scope = @scope.where(user: params[:user]) if params[:user].present?
    @scope = @scope.where(state: params[:state]) if params[:state].present?
    @scope = @scope.where(repo_full_name: params[:repo_full_name]) if params[:repo_full_name].present?
    @scope = @scope.org(params[:org]) if params[:org].present?

    @types = {
      'issues' => @scope.issues.count,
      'pull_requests' => @scope.pull_requests.count
    }

    @languages = Issue::LANGUAGES.to_h do |language|
      [language, @scope.language(language).count]
    end

    @scope = @scope.language(params[:language]) if params[:language].present?

    if params[:type].present?
      if params[:type] == 'issues'
        @scope = @scope.issues
      else
        @scope = @scope.pull_requests
      end
    end

    @pagy, @issues = pagy(@scope.order('issues.created_at DESC'))

    @users = @scope.unscope(where: :user).not_employees.group(:user).count

    @states = @scope.unscope(where: :state).group(:state).count
    @repos = @scope.unscope(where: :repo_full_name).group(:repo_full_name).count
    @orgs = @scope.unscope(where: :org).protocol.group(:org).count
  end
end
