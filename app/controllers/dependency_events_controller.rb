class DependencyEventsController < ApplicationController
  def index
    @page_title = 'Dependency Events'
    @scope = DependencyEvent.where('committed_at <= ?', Time.now).not_internal_repo.includes(:repository, :package)

    @scope = @scope.where(action: params[:action_name]) if params[:action_name].present?
    @scope = @scope.where(platform: params[:platform]) if params[:platform].present?
    @scope = @scope.where(package_name: params[:package_name]) if params[:package_name].present?
    @scope = @scope.where(manifest_kind: params[:manifest_kind]) if params[:manifest_kind].present?

    sort = params[:sort] || 'dependency_events.committed_at'
    order = params[:order] || 'desc'

    @pagy, @dependency_events = pagy(@scope.order(sort => order), items: 150)

    respond_to do |format|
      format.html do
        @action_names = @scope.unscope(where: :action).group(:action).count
        @platforms = @scope.unscope(where: :platform).group(:platform).count
        @package_names = @scope.unscope(where: :package_name).group(:package_name).count
        @manifest_kinds = @scope.unscope(where: :manifest_kind).group(:manifest_kind).count
      end
      format.rss do
        render 'index', :layout => false
      end
      format.json do
        render json: @dependency_events
      end
    end
  end
end
