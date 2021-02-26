class PackagesController < ApplicationController
  def index
    @page_title = 'Internal Packages'
    @scope = Package.internal.includes(:repository)

    @scope = @scope.this_period(params[:range].to_i) if params[:range].present?

    @scope = @scope.exclude_platform(params[:exclude_platform]) if params[:exclude_platform].present?
    @scope = @scope.platform(params[:platform]) if params[:platform].present?

    @orgs_scope = @scope
    @scope = @scope.exclude_org(params[:exclude_org]) if params[:exclude_org].present?
    @scope = @scope.org(params[:org]) if params[:org].present?

    @sort = params[:sort] || 'collab_dependent_repos_count'
    @order = params[:order] || 'desc'

    respond_to do |format|
      format.html do
        @pagy, @packages = pagy(@scope.order(@sort => @order))
        @platforms = @scope.unscope(where: :platform).group(:platform).count
        @orgs = Organization.internal.pluck(:name).map{|n| [n, @scope.depends_upon_internal(Package.internal.org(n)).count.length] }
        @owners = @orgs_scope.joins(:organization).group('organizations.name').count
      end
      format.rss do
        @pagy, @packages = pagy(@scope.order(@sort => @order))
        render 'index', :layout => false
      end
      format.json do
        @pagy, @packages = pagy(@scope.order(@sort => @order))
        render json: @packages
      end
    end
  end

  def collabs
    @page_title = 'Collaborator Packages'
    @scope = Package.collabs.includes(:repository)

    @scope = @scope.this_period(params[:range].to_i) if params[:range].present?
    @scope = @scope.exclude_platform(params[:exclude_platform]) if params[:exclude_platform].present?
    @scope = @scope.platform(params[:platform]) if params[:platform].present?

    @orgs_scope = @scope
    @scope = @scope.exclude_org(params[:exclude_org]) if params[:exclude_org].present?
    @scope = @scope.org(params[:org]) if params[:org].present?

    @sort = params[:sort] || 'collab_dependent_repos_count'
    @order = params[:order] || 'desc'

    respond_to do |format|
      format.html do
        @pagy, @packages = pagy(@scope.order(@sort => @order))
        @platforms = @scope.unscope(where: :platform).group(:platform).count
        @orgs = Organization.internal.pluck(:name).map{|n| [n, @scope.depends_upon_internal(Package.internal.org(n)).count.length] }
        @owners = @orgs_scope.joins(:repository).map{|p| p.repository.org }.inject(Hash.new(0)) { |h, e| h[e] += 1 ; h }
        render 'index'
      end
      format.rss do
        @pagy, @packages = pagy(@scope.order(@sort => @order))
        render 'index', :layout => false
      end
      format.json do
        @pagy, @packages = pagy(@scope.order(@sort => @order))
        render json: @packages
      end
    end
  end

  def community
    @page_title = 'Community Packages'

    internal_package_scope = Package.internal
    internal_package_scope = internal_package_scope.org(params[:internal_org]) if params[:internal_org].present?

    @scope = Package.depends_upon_internal(internal_package_scope).community

    @scope = @scope.this_period(params[:range].to_i) if params[:range].present?
    @scope = @scope.exclude_platform(params[:exclude_platform]) if params[:exclude_platform].present?
    @scope = @scope.platform(params[:platform]) if params[:platform].present?

    @orgs_scope = @scope
    @scope = @scope.exclude_org(params[:exclude_org]) if params[:exclude_org].present?
    @scope = @scope.org(params[:org]) if params[:org].present?

    @sort = params[:sort] || 'collab_dependent_repos_count'
    @order = params[:order] || 'desc'

    respond_to do |format|
      format.html do
        @pagy, @packages = pagy(@scope.order(@sort => @order))
        @platforms = @scope.unscope(where: :platform).group_by(&:platform).map{|k,v| [k,v.length]}
        @orgs = Organization.internal.pluck(:name).map{|n| [n, @scope.depends_upon_internal(Package.internal.org(n)).count.length] }
        @owners = @orgs_scope.joins(:repository).map{|p| p.repository.org }.inject(Hash.new(0)) { |h, e| h[e] += 1 ; h }
        render 'index'
      end
      format.rss do
        @pagy, @packages = pagy(@scope.order(@sort => @order))
        render 'index', :layout => false
      end
      format.json do
        @pagy, @packages = pagy(@scope.order(@sort => @order))
        render json: @packages
      end
    end
  end

  def show
    @package = Package.find(params[:id])
    direct = params[:direct] == 'false' ? false : true

    @dependencies = Dependency.where(version_id: @package.version_ids).where(package_id: Package.internal.pluck(:id)).includes(:version, :package).group_by(&:package)
    @repository_dependencies = @package.repository_dependencies.external.where(direct: direct).active.source.includes(:repository, :manifest)

    @dependency_events_pagy, @dependency_events = pagy(@package.dependency_events.internal.order('dependency_events.committed_at DESC'), items: 50)
  end

  def search
    @scope = Package.search_by_name(params[:query]).includes(:repository)
    @pagy, @packages = pagy(@scope)
  end

  def outdated
    @packages = Package.internal.where('outdated > 0').where('collab_dependent_repos_count > 0').order('collab_dependent_repos_count DESC').includes(:repository)
  end
end
