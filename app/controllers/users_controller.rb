class UsersController < ApplicationController
  def show
    @username = params[:id]
    @events_scope = Pmf.event_scope.user(@username)

    sort = params[:sort] || 'events.created_at'
    order = params[:order] || 'desc'

    @pagy, @events = pagy(@events_scope.order(sort => order))
  end
end
