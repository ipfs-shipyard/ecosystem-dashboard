class RepositoriesController < ApplicationController
  def index
    @scope = Repository.internal
    @scope = @scope.org(params[:org]) if params[:org].present?
    @scope = @scope.language(params[:language]) if params[:language].present?
    @scope = @scope.fork(params[:fork]) if params[:fork].present?
    @scope = @scope.archived(params[:archived]) if params[:archived].present?
    @pagy, @repositories = pagy(@scope.order('repositories.pushed_at DESC'))

    @orgs = @scope.unscope(where: :org).internal.group(:org).count
    @languages = @scope.unscope(where: :language).group(:language).count
  end

  def show
    @repository = Repository.find(params[:id])
    @manifests = @repository.manifests.includes(repository_dependencies: {package: :versions}).order('kind DESC')
  end

  def collab_repositories
    @scope = Repository.external
    @scope = @scope.org(params[:org]) if params[:org].present?
    @scope = @scope.language(params[:language]) if params[:language].present?
    @scope = @scope.fork(params[:fork]) if params[:fork].present?
    @scope = @scope.archived(params[:archived]) if params[:archived].present?
    @pagy, @repositories = pagy(@scope.order('repositories.pushed_at DESC'))

    @orgs = @scope.unscope(where: :org).external.group(:org).count
    @languages = @scope.unscope(where: :language).group(:language).count
  end
end
