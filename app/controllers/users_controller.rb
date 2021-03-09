class UsersController < ApplicationController
  def show
    @username = params[:id]
    @events_scope = Pmf.event_scope(1).user(@username)

    sort = params[:sort] || 'events.created_at'
    order = params[:order] || 'desc'

    @pagy, @events = pagy(@events_scope.order(sort => order))
  end

  def transitions
    transition_name = params[:tab].presence || 'First Time'

    parse_pmf_params

    @data = Pmf.transitions_with_details(@start_date, @end_date, @window, @threshold, @dependency_threshold)

    if @data
      all_users = @data.first[:transitions][transition_name.to_sym]
    else
      all_users = []
    end

    respond_to do |format|
      format.html do
        @pagy, @users = pagy_array(all_users)
      end
      format.json do
        render json: @data
      end
    end
  end

  def index
    state_name = params[:tab].presence || 'first'

    parse_pmf_params

    respond_to do |format|
      format.html do
        @data = Pmf.state(state_name, @start_date, @end_date, @window, @threshold, @dependency_threshold)

        if @data
          all_users = @data.first[:states].first[1]
        else
          all_users = []
        end
        @pagy, @users = pagy_array(all_users)
      end
      format.json do
        @data = Pmf.states(@start_date, @end_date, @window, @threshold, @dependency_threshold)
        render json: @data
      end
    end
  end
end
