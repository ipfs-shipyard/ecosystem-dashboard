class EventsController < ApplicationController
  def index
    @page_title = 'Internal Events'
    @range = (params[:range].presence || 30).to_i
    @scope = Event.includes(:repository).internal.this_period(@range).humans
    @scope = @scope.org(params[:org]) if params[:org].present?
    @scope = @scope.user(params[:user]) if params[:user].present?
    @scope = @scope.repo(params[:repo_full_name]) if params[:repo_full_name].present?
    @scope = @scope.event_type(params[:event_type]) if params[:event_type].present?

    sort = params[:sort] || 'events.created_at'
    order = params[:order] || 'desc'

    @pagy, @events = pagy(@scope.order(sort => order))

    @orgs = @scope.unscope(where: :org).internal.group(:org).count
    @repos = @scope.unscope(where: :repository_full_name).internal.group(:repository_full_name).count
    @users = @scope.unscope(where: :actor).humans.group(:actor).count
    @event_types = @scope.unscope(where: :event_type).group(:event_type).count

    respond_to do |format|
      format.html do
        @orgs = @scope.unscope(where: :org).group(:org).count
        @repos = @scope.unscope(where: :repository_full_name).group(:repository_full_name).count
        @users = @scope.unscope(where: :actor).humans.group(:actor).count
        @event_types = @scope.unscope(where: :event_type).group(:event_type).count
      end
      format.rss do
        render 'index', :layout => false
      end
      format.json do
        render json: @events
      end
    end
  end

  def collabs
    @page_title = 'Collabs Events'
    @range = (params[:range].presence || 30).to_i
    @scope = Event.includes(:repository).external.this_period(@range).humans
    @scope = @scope.search(params[:query]) if params[:query].present?
    @scope = @scope.org(params[:org]) if params[:org].present?
    @scope = @scope.user(params[:user]) if params[:user].present?
    @scope = @scope.repo(params[:repo_full_name]) if params[:repo_full_name].present?
    @scope = @scope.event_type(params[:event_type]) if params[:event_type].present?
    
    sort = params[:sort] || 'events.created_at'
    order = params[:order] || 'desc'

    @pagy, @events = pagy(@scope.order(sort => order))

    respond_to do |format|
      format.html do
        @orgs = @scope.unscope(where: :org).external.group(:org).count
        @repos = @scope.unscope(where: :repository_full_name).external.group(:repository_full_name).count
        @users = @scope.unscope(where: :actor).humans.group(:actor).count
        @event_types = @scope.unscope(where: :event_type).group(:event_type).count
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
