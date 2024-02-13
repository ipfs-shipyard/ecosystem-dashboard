class SearchController < ApplicationController
  def index
    @page_title = "Tracked Searches"
    @range = (params[:range].presence || 7).to_i
    @scope = SearchResult.this_period(@range).includes(:search_query)

    @scope = @scope.where(repository_full_name: params[:repository_full_name]) if params[:repository_full_name].present?
    @scope = @scope.where(kind: params[:kind]) if params[:kind].present?
    @scope = @scope.where(org: params[:org]) if params[:org].present?

    @scope = @scope.where.not(repository_full_name: params[:exclude_repository_full_name]) if params[:exclude_repository_full_name].present?
    @scope = @scope.where.not(kind: params[:exclude_kind]) if params[:exclude_kind].present?
    @scope = @scope.where.not(org: params[:exclude_org]) if params[:exclude_org].present?

    @pagy, @search_results = pagy(@scope.order('created_at desc'))

    respond_to do |format|
      format.html do
        @repos = @scope.unscope(where: :repository_full_name).group(:repository_full_name).count
        @kinds = @scope.unscope(where: :kind).group(:kind).count
        @orgs = @scope.unscope(where: :org).group(:org).count
      end
      format.rss do
        render 'index', :layout => false
      end
      format.json do
        render json: @search_results
      end
    end
  end

  def highlights
    @range = (params[:range].presence || 7).to_i
    @scope = SearchResult.this_period(@range).where.not(kind: 'code').includes(:search_query)

    @scope = @scope.where(kind: params[:kind]) if params[:kind].present?
    @scope = @scope.where.not(kind: params[:exclude_kind]) if params[:exclude_kind].present?

    @kinds = @scope.unscope(where: :kind).group(:kind).count
  end

  def collabs
    @page_title = "Collab Tracked Searches"
    @range = (params[:range].presence || 7).to_i
    @scope = SearchResult.this_period(@range).includes(:search_query).where(org: Organization.collaborator.pluck(:name))

    @scope = @scope.where(repository_full_name: params[:repository_full_name]) if params[:repository_full_name].present?
    @scope = @scope.where(kind: params[:kind]) if params[:kind].present?
    @scope = @scope.where(org: params[:org]) if params[:org].present?

    @scope = @scope.where.not(repository_full_name: params[:exclude_repository_full_name]) if params[:exclude_repository_full_name].present?
    @scope = @scope.where.not(kind: params[:exclude_kind]) if params[:exclude_kind].present?
    @scope = @scope.where.not(org: params[:exclude_org]) if params[:exclude_org].present?

    @pagy, @search_results = pagy(@scope.order('created_at desc'))

    respond_to do |format|
      format.html do
        @repos = @scope.unscope(where: :repository_full_name).group(:repository_full_name).count
        @kinds = @scope.unscope(where: :kind).group(:kind).count
        @orgs = @scope.unscope(where: :org).where(org: Organization.collaborator.pluck(:name)).group(:org).count
        render 'index'
      end
      format.rss do
        render 'index', :layout => false
      end
      format.json do
        render json: @search_results
      end
    end
  end
end
