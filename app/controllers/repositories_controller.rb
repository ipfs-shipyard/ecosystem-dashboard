class RepositoriesController < ApplicationController
  def index
    @page_title = 'Internal Repositories'
    @scope = Repository.internal

    @scope = @scope.this_period(params[:range].to_i) if params[:range].present?

    @scope = @scope.org(params[:org]) if params[:org].present?
    @scope = @scope.language(params[:language]) if params[:language].present?
    @scope = @scope.fork(params[:fork]) if params[:fork].present?
    @scope = @scope.archived(params[:archived]) if params[:archived].present?

    @sort = params[:sort] || 'score'
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
    @results = @repository.search_results.limit(10).order('created_at DESC')
  end

  def collab_repositories
    @page_title = 'Collaborator Repositories'
    @scope = Repository.collaborator.where('score >= 0')
    @scope = @scope.this_period(params[:range].to_i) if params[:range].present?
    @scope = @scope.org(params[:org]) if params[:org].present?
    @scope = @scope.language(params[:language]) if params[:language].present?
    @scope = @scope.fork(params[:fork]) if params[:fork].present?
    @scope = @scope.archived(params[:archived]) if params[:archived].present?

    @sort = params[:sort] || 'score'
    @order = params[:order] || 'desc'

    respond_to do |format|
      format.html do
        @pagy, @repositories = pagy(@scope.order(@sort => @order))

        @orgs = @scope.unscope(where: :org).collaborator.group(:org).count
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

  def community
    @page_title = 'Community Repositories'

    repo_ids = RepositoryDependency.where(package_id: Package.internal.pluck(:id)).group(:repository_id).count.keys

    @scope = Repository.community.where(id: repo_ids)
    @scope = @scope.this_period(params[:range].to_i) if params[:range].present?
    @scope = @scope.org(params[:org]) if params[:org].present?
    @scope = @scope.language(params[:language]) if params[:language].present?
    @scope = @scope.fork(params[:fork]) if params[:fork].present?
    @scope = @scope.archived(params[:archived]) if params[:archived].present?

    @sort = params[:sort] || 'score'
    @order = params[:order] || 'desc'

    respond_to do |format|
      format.html do
        @pagy, @repositories = pagy(@scope.order(@sort => @order))

        @orgs = @scope.unscope(where: :org).community.group(:org).count
        @languages = @scope.unscope(where: :language).group(:language).count
        render :collab_repositories
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

  def map
    if params[:organization].present?
      @organization = Organization.find_by_name(params[:organization])
      @scope = @organization.repositories
    else
      @scope = Repository.internal
    end

    @go = @scope.active.fork(false).where(language: 'Go').order('dependent_repos_count desc, stargazers_count desc, pushed_at asc')
    @go_deps = RepositoryDependency.direct.where(package_id: Package.internal.platform('Go').pluck(:id)).includes(package: :repository)
    @go_deps_repos = @go_deps.map{|d| d.package.repository }.uniq
    @go_libs = @go.where(id: @go_deps_repos.pluck(:id)).includes(:packages)
    @user_go_libs = @go_libs.select{|r| r.packages.sum(&:dependent_repos_count) > 0 }
    @internal_go_libs = @go_libs.select{|r| r.packages.sum(&:dependent_repos_count).zero? }
    @go_tools = @go.where.not(id: @go_deps_repos.pluck(:id)).includes(:packages)

    @javascript = @scope.active.fork(false).where(language: ['JavaScript', 'TypeScript', 'CoffeeScript']).order('dependent_repos_count desc, stargazers_count desc, pushed_at asc')
    @javascript_deps = RepositoryDependency.direct.where(package_id: Package.internal.platform('Npm').pluck(:id)).includes(package: :repository)
    @javascript_deps_repos = @javascript_deps.map{|d| d.package.repository }.uniq
    @javascript_libs = @javascript.where(id: @javascript_deps_repos.pluck(:id)).includes(:packages)
    @user_javascript_libs = @javascript_libs.select{|r| r.packages.sum(&:dependent_repos_count) > 0 }
    @internal_javascript_libs = @javascript_libs.select{|r| r.packages.sum(&:dependent_repos_count).zero? }
    @javascript_tools = @javascript.where.not(id: @javascript_deps_repos.pluck(:id)).includes(:packages)

    @documentation = @scope.active.fork(false).where(language: [nil, 'TeX']).order('stargazers_count desc, pushed_at asc')
    @websites = @scope.active.fork(false).where(language: ['HTML', 'CSS']).order('stargazers_count desc, pushed_at asc')
    @infratructure = @scope.active.fork(false).where(language: ['Shell', 'Makefile', 'Dockerfile', 'HCL']).order('stargazers_count desc, pushed_at asc')
    @others = @scope.active.fork(false).where.not(language: ['Go', 'JavaScript', 'TypeScript', 'HTML', 'CSS', 'Shell', 'Makefile', 'Dockerfile', 'CoffeeScript', 'HCL', 'TeX']).order('stargazers_count desc, pushed_at asc')
    @forks = @scope.active.fork(true).order('stargazers_count desc, pushed_at asc')
    @archived = @scope.archived(true).order('stargazers_count desc, pushed_at asc')
  end
end
