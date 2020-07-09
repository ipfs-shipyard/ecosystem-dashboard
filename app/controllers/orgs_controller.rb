class OrgsController < ApplicationController
  def internal
    scope = Issue.all

    if params[:range].present?
      scope = scope.where('issues.created_at > ?', params[:range].to_i.days.ago)
    end

    @orgs = Organization.internal.pluck(:name).map do |org|
      load_org_data(scope, org)
    end
  end

  def collabs
    @scope = Issue.internal.not_core.unlocked.includes(:contributor).where("html_url <> ''")
    @collabs = Repository.external.pluck(:org).flatten.inject(Hash.new(0)) { |h, e| h[e] += 1 ; h }.sort_by{|k,v| -v }
  end

  def show
    scope = Issue.all

    if params[:range].present?
      scope = scope.where('issues.created_at > ?', params[:range].to_i.days.ago)
    end

    @orgs = [load_org_data(scope, params[:id])]
  end

  def dependencies
    @repositories = Repository.archived(false).fork(false).where('pushed_at > ?', 1.year.ago).org(params[:id])
    @dependencies = RepositoryDependency.internal.where(repository_id: @repositories.pluck(:id)).includes({package: :versions}, :repository, :manifest)
    @internal_packages = @dependencies.group_by(&:package).sort_by{|p,rd| [-rd.length, p.name] }
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
      contributors: scope.org(org).humans.core.group(:user).count.sort_by(&:last).reverse,
      community_contributors: scope.org(org).not_core.group(:user).count.sort_by(&:last).reverse,
      bots: scope.org(org).bots.group(:user).count.sort_by(&:last).reverse,
      repos: scope.org(org).group(:repo_full_name).count.sort_by(&:last).reverse
    }
  end
end
