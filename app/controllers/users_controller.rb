class UsersController < ApplicationController
  def show
    @username = params[:id]
    @events_scope = Pmf.event_scope(@dependency_threshold).user(@username)

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

  def parse_pmf_params
    @start_date = params[:start_date].presence || 4.weeks.ago.beginning_of_week
    @threshold = params[:threshold].presence || nil
    @dependency_threshold = params[:dependency_threshold].presence || 0

    if params[:window] =~ /\A[-+]?[0-9]+\z/ # integer
      @end_date = params[:end_date].presence || Time.now.yesterday.end_of_day
      @window = params[:window].to_i.days
    else
      @end_date = params[:end_date].presence || Time.now.last_week.at_end_of_week
      if params[:window] == 'month'
        @window = 'month'
      elsif params[:window] == 'week'
        @window = 'week'
      else
        @window = 14
      end
    end
  end
end
