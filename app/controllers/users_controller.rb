class UsersController < ApplicationController
  def show
    @username = params[:id]
    @events_scope = Event.user(@username)

    @pagy, @events = pagy(@events_scope)
  end
end
