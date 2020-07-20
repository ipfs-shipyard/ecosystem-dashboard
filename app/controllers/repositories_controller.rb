class RepositoriesController < ApplicationController
  def index
    @page_title = 'Internal Repositories'
    @scope = Repository.internal
    @scope = @scope.org(params[:org]) if params[:org].present?
    @scope = @scope.language(params[:language]) if params[:language].present?
    @scope = @scope.fork(params[:fork]) if params[:fork].present?
    @scope = @scope.archived(params[:archived]) if params[:archived].present?

    @sort = params[:sort] || 'pushed_at'
    @order = params[:order] || 'desc'

    respond_to do |format|
      format.html do
        @pagy, @repositories = pagy(@scope.order(@sort => @order))

        @orgs = @scope.unscope(where: :org).internal.group(:org).count
        @languages = @scope.unscope(where: :language).group(:language).count
      end
      format.rss do
        @pagy, @repositories = pagy(@scope.order(@sort => @order))
        render 'index', :layout => false
      end
      format.json do
        @pagy, @repositories = pagy(@scope.order(@sort => @order))
        render json: @repositories
      end
    end
  end

  def show
    @repository = Repository.find(params[:id])
    @manifests = @repository.manifests.includes(repository_dependencies: {package: :versions}).order('kind DESC')
  end

  def collab_repositories
    @page_title = 'Collaborator Repositories'
    @scope = Repository.external
    @scope = @scope.org(params[:org]) if params[:org].present?
    @scope = @scope.language(params[:language]) if params[:language].present?
    @scope = @scope.fork(params[:fork]) if params[:fork].present?
    @scope = @scope.archived(params[:archived]) if params[:archived].present?

    @sort = params[:sort] || 'pushed_at'
    @order = params[:order] || 'desc'

    respond_to do |format|
      format.html do
        @pagy, @repositories = pagy(@scope.order(@sort => @order))

        @orgs = @scope.unscope(where: :org).group(:org).count
        @languages = @scope.unscope(where: :language).group(:language).count
      end
      format.rss do
        @pagy, @repositories = pagy(@scope.order(@sort => @order))
        render 'index', :layout => false
      end
      format.json do
        @pagy, @repositories = pagy(@scope.order(@sort => @order))
        render json: @repositories
      end
    end
  end
end
