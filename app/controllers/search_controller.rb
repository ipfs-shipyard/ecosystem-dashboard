class SearchController < ApplicationController
  def index
    @range = (params[:range].presence || 7).to_i
    @scope = SearchResult.this_period(@range).includes(:search_query)

    @scope = @scope.where(repository_full_name: params[:repository_full_name]) if params[:repository_full_name].present?
    @scope = @scope.where(kind: params[:kind]) if params[:kind].present?
    @scope = @scope.where(org: params[:org]) if params[:org].present?

    @pagy, @search_results = pagy(@scope.order('created_at desc'))

    @repos = @scope.unscope(where: :repository_full_name).group(:repository_full_name).count
    @kinds = @scope.unscope(where: :kind).group(:kind).count
    @orgs = @scope.unscope(where: :org).group(:org).count
  end
end
