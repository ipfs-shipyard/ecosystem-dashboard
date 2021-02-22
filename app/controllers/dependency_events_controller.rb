class DependencyEventsController < ApplicationController
  def index
    @page_title = 'Dependency Events'
    @range = (params[:range].presence || 30).to_i
    @scope = DependencyEvent.internal.this_period(@range)

    sort = params[:sort] || 'dependency_events.committed_at'
    order = params[:order] || 'desc'

    @pagy, @dependency_events = pagy(@scope.order(sort => order))

    respond_to do |format|
      format.html do

      end
      format.rss do
        render 'index', :layout => false
      end
      format.json do
        render json: @events
      end
    end
  end
end
