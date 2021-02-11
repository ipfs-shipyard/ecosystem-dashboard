class UsersController < ApplicationController
  def show
    @username = params[:id]
    @pagy, @events = pagy(Event.user(@username))
  end
end
