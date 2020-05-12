class PackagesController < ApplicationController
  def index
    @scope = Package.where(repository_id: Repository.protocol.pluck(:id)).includes(:repository)
    @pagy, @packages = pagy(@scope.order('collab_dependent_repos_count DESC, dependent_repos_count DESC, created_at DESC'))
  end

  def show
    @package = Package.find(params[:id])
    @repository_dependencies = @package.repository_dependencies.active.source.includes(:repository, :manifest)
  end

  def search
    @scope = Package.search_by_name(params[:query]).includes(:repository)
    @pagy, @packages = pagy(@scope)
  end

  def outdated
    @packages = Package.platform('npm').where('collab_dependent_repos_count > 0').includes(:versions)
  end
end
