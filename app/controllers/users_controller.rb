class UsersController < ApplicationController
  def show
    @username = params[:id]
    @events_scope = Event.user(@username)

    sort = params[:sort] || 'events.created_at'
    order = params[:order] || 'desc'

    @pagy, @events = pagy(@events_scope.order(sort => order))
  end

  def index
    # TODO render users
    @users = []
    @pagy, @users = pagy_array(@users)
  end

  def hackathons
    @scope = Repository.discovered_contributors.order('created_at desc')
    @pagy, @contributors = pagy(@scope, limit: 100)
  end
end
