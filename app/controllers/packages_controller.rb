class PackagesController < ApplicationController
  def index
    @scope = Package.internal.includes(:repository)

    @scope = @scope.exclude_platform(params[:exclude_platform]) if params[:exclude_platform].present?
    @scope = @scope.platform(params[:platform]) if params[:platform].present?

    @orgs_scope = @scope
    @scope = @scope.exclude_org(params[:exclude_org]) if params[:exclude_org].present?
    @scope = @scope.org(params[:org]) if params[:org].present?

    @pagy, @packages = pagy(@scope.order('collab_dependent_repos_count DESC, dependent_repos_count DESC, created_at DESC'))
    @platforms = @scope.unscope(where: :platform).group(:platform).count
    @orgs = @orgs_scope.joins(:organization).group('organizations.name').count
  end

  def show
    @package = Package.find(params[:id])
    direct = params[:direct] == 'false' ? false : true
    @repository_dependencies = @package.repository_dependencies.external.where(direct: direct).active.source.includes(:repository, :manifest)
  end

  def search
    @scope = Package.search_by_name(params[:query]).includes(:repository)
    @pagy, @packages = pagy(@scope)
  end

  def outdated
    @packages = Package.internal.where('outdated > 0').where('collab_dependent_repos_count > 0').order('collab_dependent_repos_count DESC').includes(:repository)
  end
end
