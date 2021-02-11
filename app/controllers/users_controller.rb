class UsersController < ApplicationController
  def show
    @username = params[:id]
    @events_scope = Pmf.event_scope.user(@username)

    sort = params[:sort] || 'events.created_at'
    order = params[:order] || 'desc'

    @pagy, @events = pagy(@events_scope.order(sort => order))
  end

  def index
    state_name = params[:tab].presence || 'first'

    @start_date = 1.week.ago.beginning_of_week
    @end_date = Time.now.beginning_of_week
    @window = 1

    @data = Rails.cache.fetch(['state', state_name, @start_date, @end_date, @window], expires_in: 1.hours) do
      Pmf.state(state_name, @start_date, @end_date, @window)
    end

    if @data
      p @data.first[:date]
      all_users = @data.first[:states].first[1]
    else
      all_users = []
    end

    @pagy, @users = pagy_array(all_users)
  end
end
